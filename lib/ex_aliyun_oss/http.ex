defmodule ExAliyunOss.Http.Middleware do
  @behaviour Tesla.Middleware

  alias ExAliyunOss.{Client, Response}
  require Logger

  def call(env, next, options) do
    account = Keyword.get(options, :account)
    request = Keyword.get(options, :request)
    use_external_endpoint = Keyword.get(options, :use_ext_endpoint, true)
    uri = Keyword.get(options, :uri)

    env
    |> signature(account, request)
    |> config_endpoint(request, uri, use_external_endpoint)
    |> Tesla.put_body(request.body)
    |> Tesla.run(next)
    |> prepare_response()
  end

  defp signature(env, account, request) do
    date = Timex.format!(Timex.now(), "%a, %d %b %Y %H:%M:%S GMT", :strftime)

    headers = request.headers
    content_type = Map.get(headers, "content-type", "")

    oss_headers_str = oss_headers_to_str(request.headers)

    str_to_sign =
      "#{request.method}\n\n#{content_type}\n#{date}\n#{oss_headers_str}#{request.resource}"

    signature =
      ExAliyunOss.Utils.crypto_hmac(:sha, account.access_key_secret, str_to_sign)
      |> Base.encode64()

    authorization = "OSS #{account.access_key_id}:#{signature}"

    updated_headers =
      Map.merge(request.headers, %{
        "Authorization" => authorization,
        "Date" => date,
        "content-type" => content_type
      })

    Tesla.put_headers(env, Enum.into(updated_headers, []))
  end

  defp config_endpoint(env, request, uri, external?) do
    url =
      if external? do
        "#{Client.external_endpoint(request)}#{Client.encode_resource(uri)}"
      else
        "#{Client.internal_endpoint(request)}#{Client.encode_resource(uri)}"
      end

    Map.put(env, :url, url)
  end

  defp oss_headers_to_str([]), do: ""

  defp oss_headers_to_str(headers) do
    headers
    |> Enum.filter(fn {header_key, _header_value} ->
      String.downcase(header_key) |> String.starts_with?("x-oss-")
    end)
    |> Enum.sort(fn {k1, _v1}, {k2, _v2} -> k1 <= k2 end)
    |> Enum.map(fn {header_key, header_value} ->
      "#{String.trim(String.downcase(header_key))}:#{String.trim(header_value)}\n"
    end)
    |> Enum.join("")
  end

  defp prepare_response({:error, reason}) do
    Logger.error("error response: #{inspect(reason)}")
    {:error, reason}
  end

  defp prepare_response({:ok, env}) do
    response = %Response{
      request_url: env.url,
      status_code: env.status,
      headers: env.headers,
      body: env.body
    }

    updated_response =
      Enum.reduce(env.headers, response, fn item, acc ->
        case item do
          {"date", date} -> Map.put(acc, :date, date)
          {"x-oss-request-id", request_id} -> Map.put(acc, :request_id, request_id)
          {"x-oss-server-time", server_time} -> Map.put(acc, :server_time, server_time)
          _ -> acc
        end
      end)

    {:ok, updated_response}
  end
end

defmodule ExAliyunOss.Http do
  use Tesla

  adapter(Tesla.Adapter.Hackney)

  plug(Tesla.Middleware.Retry, max_retries: 5)
  plug(Tesla.Middleware.Timeout, timeout: 15_000)

  def client(uri, account, request, use_external_endpoint \\ true) do
    Tesla.client([
      {ExAliyunOss.Http.Middleware,
       account: account, request: request, use_ext_endpoint: use_external_endpoint, uri: uri}
    ])
  end

  def send(http_client, "PUT"), do: request(http_client, method: :put)
  def send(http_client, "POST"), do: request(http_client, method: :post)
  def send(http_client, "GET"), do: request(http_client, method: :get)
  def send(http_client, "HEAD"), do: request(http_client, method: :head)
  def send(http_client, "DELETE"), do: request(http_client, method: :delete)

  def send(_http_client, unknown_method) do
    raise ExAliyunOss.Error, "Invalid http method: #{inspect(unknown_method)}"
  end
end
