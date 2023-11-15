defmodule ExAliyunOss.Constants do
  defmacro const(name, value) do
    quote do
      defmacro unquote(name)(), do: unquote(value)
    end
  end
end

defmodule ExAliyunOss.Region do
  import ExAliyunOss.Constants

  const(:cn_qingdao, "cn-qingdao")
  const(:cn_beijing, "cn-beijing")
  const(:cn_zhangjiakou, "cn-zhangjiakou")
  const(:cn_hangzhou, "cn-hangzhou")
  const(:cn_shanghai, "cn-shanghai")
  const(:cn_shenzhen, "cn-shenzhen")
  const(:cn_hongkong, "cn-hongkong")

  # Asia Pacific Southeast - Singapore
  const(:ap_southeast_1, "ap-southeast-1")
  # Asia Pacific Southeast - Sydney 
  const(:ap_southeast_2, "ap-southeast-2")
  # Asia Pacific Southeast - Kuala Lumpur
  const(:ap_southeast_3, "ap-southeast-3")
  # Japan - Tokyo
  const(:ap_northeast_1, "ap-northeast-1")
  # US - silicon valley
  const(:us_west_1, "us-west-1")
  # US - Virginia
  const(:us_east_1, "us-east-1")
  # Europe - Frankfurt
  const(:eu_central_1, "eu-central-1")
  # Middle East - Dubai
  const(:me_east_1, "me-east-1")
end

defmodule ExAliyunOss.ACL do
  import ExAliyunOss.Constants

  const(:public_read_write, "public-read-write")
  const(:public_read, "public-read")
  const(:private, "private")
end

defmodule ExAliyunOss.BucketType do
  import ExAliyunOss.Constants

  const(:standard, "Standard")
  const(:ia, "IA")
  const(:archive, "Archive")
end

defmodule ExAliyunOss.HttpMethod do
  import ExAliyunOss.Constants

  const(:put, "PUT")
  const(:post, "POST")
  const(:get, "GET")
  const(:head, "HEAD")
  const(:delete, "DELETE")
end

defmodule ExAliyunOss.LifecycleStatus do
  import ExAliyunOss.Constants

  const(:enabled, "Enabled")
  const(:disabled, "Disabled")
end
