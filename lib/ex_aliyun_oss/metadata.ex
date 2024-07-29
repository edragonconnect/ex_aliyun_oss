defmodule ExAliyunOss.Error do
  defexception [:message, :error_code]

  def exception(value) do
    msg = "Error: #{inspect(value)}"
    %ExAliyunOss.Error{message: msg}
  end
end

defmodule ExAliyunOss.Account do
  defstruct [:access_key_id, :access_key_secret]
end

defmodule ExAliyunOss.Request do
  defstruct method: nil,
            endpoint: nil,
            resource: nil,
            body: "",
            headers: %{},
            options: [],
            bucket_name: nil,
            region: nil,
            supplement: nil
end

defmodule ExAliyunOss.Response do
  defstruct request_url: nil,
            request_id: nil,
            server_time: nil,
            status_code: nil,
            headers: nil,
            body: "",
            date: nil
end

defmodule ExAliyunOss.Var.PutBucket do
  alias ExAliyunOss.{BucketType, ACL}
  require BucketType
  require ACL
  defstruct type: BucketType.standard(), acl: ACL.private(), bucket_name: nil, region: nil
end

defmodule ExAliyunOss.Var.PutBucketLifecycle.Transition do
  defstruct days: nil, created_before_date: nil, storage_class: nil
end

defmodule ExAliyunOss.Var.PutBucketLifecycle.AbortMultipartUpload do
  defstruct days: nil, created_before_date: nil
end

defmodule ExAliyunOss.Var.PutBucketLifecycle.Expiration do
  defstruct days: nil, created_before_date: nil
end

defmodule ExAliyunOss.Var.PutBucketLifecycle do
  alias ExAliyunOss.{BucketType, LifecycleStatus}
  require BucketType
  require LifecycleStatus

  defstruct prefix: nil,
            status: LifecycleStatus.enabled(),
            transition: nil,
            abort_multipart_upload: nil,
            expiration: nil,
            bucket_name: nil,
            region: nil,
            rule_id: ""
end

defmodule ExAliyunOss.Var.PutObject do
  defstruct bucket_name: nil,
            region: nil,
            object_name: nil,
            file_binary: nil,
            naming_with_hash: false
end

defmodule ExAliyunOss.Var.GetObject do
  defstruct bucket_name: nil, region: nil, object_name: nil
end

defmodule ExAliyunOss.Var.CopyObject do
  defstruct bucket_name: nil,
            region: nil,
            copy_from_object: nil,
            copy_to_object: nil,
            headers: %{}
end

defmodule ExAliyunOss.Var.DeleteObject do
  defstruct bucket_name: nil, region: nil, object_name: nil
end
