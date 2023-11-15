defmodule ExAliyunOss.BucketToXML do
  require EEx

  EEx.function_from_file(:def, :put_bucket, "lib/ex_aliyun_oss/xml/put_bucket.eex", [
    :var_put_bucket
  ])

  EEx.function_from_file(
    :def,
    :put_bucket_lifecycle,
    "lib/ex_aliyun_oss/xml/put_bucket_lifecycle.eex",
    [:var_put_bucket_lifecycle]
  )
end
