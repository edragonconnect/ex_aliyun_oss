defmodule ExAliyunOss.Client do
  use GenServer
  alias ExAliyunOss.Var.PutBucket
  alias ExAliyunOss.Client.{Bucket, Object}
  alias ExAliyunOss.Http

  @request_timeout 30_000
  @pool_name_prefix :ex_aliyun_oss_client
  @oss_domain "aliyuncs.com"

  defstruct account: nil

  def oss_domain, do: @oss_domain
  def pool_name(account_name), do: splice_pool_name(account_name)

  def start_link([account]) do
    GenServer.start_link(__MODULE__, account)
  end

  @spec put_bucket(String.t(), %PutBucket{}, boolean) :: tuple
  def put_bucket(account_name, var, with_external_endpoint \\ true) do
    request = Bucket.request_to_put_bucket(var)
    call_transaction(account_name, {:exec, "/", request, with_external_endpoint})
  end

  @spec put_bucket_lifecycle(String.t(), %ExAliyunOss.Var.PutBucketLifecycle{}, boolean) :: tuple
  def put_bucket_lifecycle(account_name, var, with_external_endpoint \\ true) do
    request = Bucket.request_to_put_bucket_lifecycle(var)
    call_transaction(account_name, {:exec, "/?lifecycle", request, with_external_endpoint})
  end

  @spec delete_bucket(String.t(), String.t(), String.t(), boolean) :: tuple
  def delete_bucket(account_name, bucket_name, region, with_external_endpoint \\ true) do
    request = Bucket.request_to_delete_bucket(bucket_name, region)
    call_transaction(account_name, {:exec, "/", request, with_external_endpoint})
  end

  @spec put_object(String.t(), %ExAliyunOss.Var.PutObject{}, boolean) :: tuple
  def put_object(account_name, var, with_external_endpoint \\ true) do
    request = Object.request_to_put_object(var)
    uri = request.supplement.object_name
    call_transaction(account_name, {:exec, uri, request, with_external_endpoint})
  end

  @spec get_object(String.t(), %ExAliyunOss.Var.GetObject{}, boolean) :: tuple
  def get_object(account_name, var, with_external_endpoint \\ true) do
    request = Object.request_to_get_object(var)
    uri = request.supplement.object_name
    call_transaction(account_name, {:exec, uri, request, with_external_endpoint})
  end

  @spec get_object_meta(String.t(), %ExAliyunOss.Var.GetObject{}, boolean) :: tuple
  def get_object_meta(account_name, var, with_external_endpoint \\ true) do
    request = Object.request_to_get_object_meta(var)
    uri = request.supplement.object_name
    call_transaction(account_name, {:exec, uri, request, with_external_endpoint})
  end

  @spec copy_object(String.t(), %ExAliyunOss.Var.CopyObject{}, boolean) :: tuple
  def copy_object(account_name, var, with_external_endpoint \\ true) do
    request = Object.request_to_copy_object(var)
    uri = request.supplement.object_name
    call_transaction(account_name, {:exec, uri, request, with_external_endpoint})
  end

  @spec delete_object(String.t(), %ExAliyunOss.Var.DeleteObject{}, boolean) :: tuple
  def delete_object(account_name, var, with_external_endpoint \\ true) do
    request = Object.request_to_delete_object(var)
    uri = request.supplement.object_name
    call_transaction(account_name, {:exec, uri, request, with_external_endpoint})
  end

  @impl true
  def init(account) do
    {:ok, %__MODULE__{account: account}}
  end

  @impl true
  def handle_call({:exec, uri, request, with_external_endpoint}, _from, state) do
    result =
      uri
      |> Http.client(state.account, request, with_external_endpoint)
      |> Http.send(request.method)

    {:reply, result, state}
  end

  defp call_transaction(account_name, request, request_timeout \\ @request_timeout) do
    :poolboy.transaction(
      splice_pool_name(account_name),
      fn worker ->
        GenServer.call(worker, request, request_timeout)
      end,
      :infinity
    )
  end

  defp splice_pool_name(account_name) when is_bitstring(account_name) do
    String.to_atom("#{@pool_name_prefix}_#{account_name}")
  end

  @spec external_endpoint(%ExAliyunOss.Request{}) :: String.t()
  def external_endpoint(request) do
    validate_basic_required(request)
    "https://#{request.bucket_name}.oss-#{request.region}.#{@oss_domain}"
  end

  @spec internal_endpoint(%ExAliyunOss.Request{}) :: String.t()
  def internal_endpoint(request) do
    validate_basic_required(request)
    "http://#{request.bucket_name}.oss-#{request.region}-internal.#{@oss_domain}"
  end

  def encode_resource(resource) do
    # since uploading object name may contain non-ascii characters, we need to encode it
    [filename | rest] = String.split(resource, "/") |> Enum.reverse()

    [URI.encode_www_form(filename) | rest]
    |> Enum.reverse()
    |> Enum.join("/")
  end

  defp validate_basic_required(var) do
    if var.bucket_name == nil or var.region == nil do
      raise ExAliyunOss.Error, "BucketName and Region are required."
    end
  end
end
