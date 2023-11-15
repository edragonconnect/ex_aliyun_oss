defmodule ExAliyunOss.Client.Bucket do
  alias ExAliyunOss.{BucketToXML, HttpMethod, Request}

  require HttpMethod

  def request_to_put_bucket(var) do
    xml = BucketToXML.put_bucket(var)

    %Request{
      method: HttpMethod.put(),
      resource: "/#{var.bucket_name}/",
      body: xml,
      headers: %{"x-oss-acl" => var.acl},
      region: var.region,
      bucket_name: var.bucket_name
    }
  end

  def request_to_put_bucket_lifecycle(var) do
    xml = BucketToXML.put_bucket_lifecycle(var)

    %Request{
      method: HttpMethod.put(),
      resource: "/#{var.bucket_name}/?lifecycle",
      body: xml,
      region: var.region,
      bucket_name: var.bucket_name
    }
  end

  def request_to_delete_bucket(bucket_name, region) do
    %Request{
      method: HttpMethod.delete(),
      resource: "/#{bucket_name}/",
      region: region,
      bucket_name: bucket_name
    }
  end
end
