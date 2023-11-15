defmodule ExAliyunOss.Client do
  use GenServer

  @request_timeout 30_000
  @pool_name_prefix :ex_aliyun_oss_client
  @oss_domain "aliyuncs.com"

  alias ExAliyunOss.Var.PutBucket
  alias ExAliyunOss.Client.{Bucket, Object}
  alias ExAliyunOss.Http

  defstruct account: nil

  def pool_name(account_name), do: splice_pool_name(account_name)

  def start_link([account]), do: GenServer.start_link(__MODULE__, account)

  def oss_domain, do: @oss_domain

  def init(account) do
    {:ok, %__MODULE__{account: account}}
  end

  @spec put_bucket(String.t(), %PutBucket{}, boolean) :: tuple
  def put_bucket(account_name, var, with_external_endpoint \\ true) do
    call_transaction(account_name, {:put_bucket, var, with_external_endpoint})
  end

  @spec put_bucket_lifecycle(String.t(), %ExAliyunOss.Var.PutBucketLifecycle{}, boolean) :: tuple
  def put_bucket_lifecycle(account_name, var, with_external_endpoint \\ true) do
    call_transaction(account_name, {:put_bucket_lifecycle, var, with_external_endpoint})
  end

  @spec delete_bucket(String.t(), String.t(), String.t(), boolean) :: tuple
  def delete_bucket(account_name, bucket_name, region, with_external_endpoint \\ true) do
    call_transaction(account_name, {:delete_bucket, bucket_name, region, with_external_endpoint})
  end

  @spec put_object(String.t(), %ExAliyunOss.Var.PutObject{}, boolean) :: tuple
  def put_object(account_name, var, with_external_endpoint \\ true) do
    call_transaction(account_name, {:put_object, var, with_external_endpoint})
  end

  @spec get_object(String.t(), %ExAliyunOss.Var.GetObject{}, boolean) :: tuple
  def get_object(account_name, var, with_external_endpoint \\ true) do
    call_transaction(account_name, {:get_object, var, with_external_endpoint})
  end

  @spec copy_object(String.t(), %ExAliyunOss.Var.CopyObject{}, boolean) :: tuple
  def copy_object(account_name, var, with_external_endpoint \\ true) do
    call_transaction(account_name, {:copy_object, var, with_external_endpoint})
  end

  @spec delete_object(String.t(), %ExAliyunOss.Var.DeleteObject{}, boolean) :: tuple
  def delete_object(account_name, var, with_external_endpoint \\ true) do
    call_transaction(account_name, {:delete_object, var, with_external_endpoint})
  end

  def handle_call({:put_bucket, var, with_external_endpoint}, _from, state) do
    request = Bucket.request_to_put_bucket(var)
    uri = "/"

    result =
      uri
      |> Http.client(state.account, request, with_external_endpoint)
      |> Http.send(request.method)

    {:reply, result, state}
  end

  def handle_call({:put_bucket_lifecycle, var, with_external_endpoint}, _from, state) do
    request = Bucket.request_to_put_bucket_lifecycle(var)
    uri = "/?lifecycle"

    result =
      uri
      |> Http.client(state.account, request, with_external_endpoint)
      |> Http.send(request.method)

    {:reply, result, state}
  end

  def handle_call({:delete_bucket, bucket_name, region, with_external_endpoint}, _from, state) do
    request = Bucket.request_to_delete_bucket(bucket_name, region)
    uri = "/"

    result =
      uri
      |> Http.client(state.account, request, with_external_endpoint)
      |> Http.send(request.method)

    {:reply, result, state}
  end

  def handle_call({:put_object, var, with_external_endpoint}, _from, state) do
    account = state.account
    request = Object.request_to_put_object(var)
    uri = "#{request.supplement.object_name}"

    result =
      uri
      |> Http.client(account, request, with_external_endpoint)
      |> Http.send(request.method)

    {:reply, result, state}
  end

  def handle_call({:get_object, var, with_external_endpoint}, _from, state) do
    account = state.account
    request = Object.request_to_get_object(var)
    uri = "#{request.supplement.object_name}"

    result =
      uri
      |> Http.client(account, request, with_external_endpoint)
      |> Http.send(request.method)

    {:reply, result, state}
  end

  def handle_call({:copy_object, var, with_external_endpoint}, _from, state) do
    account = state.account
    request = Object.request_to_copy_object(var)
    uri = "#{request.supplement.object_name}"

    result =
      uri
      |> Http.client(account, request, with_external_endpoint)
      |> Http.send(request.method)

    {:reply, result, state}
  end

  def handle_call({:delete_object, var, with_external_endpoint}, _from, state) do
    account = state.account
    request = Object.request_to_delete_object(var)
    uri = "#{request.supplement.object_name}"

    result =
      uri
      |> Http.client(account, request, with_external_endpoint)
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
    splited = String.split(resource, "/")
    [filename | rest] = Enum.reverse(splited)

    rest
    |> Enum.reverse()
    |> Enum.concat([URI.encode_www_form(filename)])
    |> Enum.join("/")
  end

  defp validate_basic_required(var) do
    if var.bucket_name == nil or var.region == nil do
      raise ExAliyunOss.Error, "BucketName and Region are required."
    end
  end
end
