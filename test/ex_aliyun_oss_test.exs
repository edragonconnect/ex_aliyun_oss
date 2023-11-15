defmodule ExAliyunOssTest do
  use ExUnit.Case
  require Logger

  alias ExAliyunOss.{Region, ACL, Client, LifecycleStatus}

  alias ExAliyunOss.Var.{
    PutBucket,
    PutBucketLifecycle,
    PutBucketLifecycle.Expiration,
    PutObject,
    CopyObject,
    DeleteObject
  }

  require Region
  require ACL
  require LifecycleStatus

  @account "test"
  @bucket_name "elixir-created2"

  test "create bucket" do
    put_bucket_vars = %PutBucket{
      acl: ACL.public_read(),
      bucket_name: @bucket_name,
      region: Region.cn_hangzhou()
    }

    result = Client.put_bucket(@account, put_bucket_vars)
    Logger.info("#{inspect(result, pretty: true)}")
    {:ok, response} = result
    assert response.status_code == 200
  end

  test "set bucket lifecycle with expiration 1 day for `tmp/` folder" do
    expiration = %Expiration{days: 1}

    put_bucket_lifecycle_vars = %PutBucketLifecycle{
      prefix: "tmp/",
      status: LifecycleStatus.enabled(),
      expiration: expiration,
      bucket_name: @bucket_name,
      region: Region.cn_hangzhou()
    }

    result = Client.put_bucket_lifecycle(@account, put_bucket_lifecycle_vars)
    Logger.info("#{inspect(result, pretty: true)}")
    {:ok, response} = result
    assert response.status_code == 200
  end

  test "put object" do
    # put object normally
    files_to_upload = %{
      "#{File.cwd!()}/test/data/upload_text.txt" => "/201711/1/1.txt",
      "#{File.cwd!()}/test/data/upload_img.png" => "/201711/1/2.png",
      "#{File.cwd!()}/test/data/upload_测试.txt" => "/201711/1/测试.txt",
      "#{File.cwd!()}/test/data/upload  _  中文 _img.png" => "/201711/1/upload_ 中文_img.png",
      "#{File.cwd!()}/test/data/upload_ABCD+HIE1~@.txt" => "/201711/1/upload_ABCD+HIE1~@.txt",
      # "#{File.cwd!}/test/data/upload_AB&*!(#)C)(&*^%$#!D+HIE1~@测试.txt" => "/201711/1/upload_AB&*!(#)C)(&*^%$#!D+HIE1~@测试.txt", # this naming will occur a malformed URI, Get 400 Bad request from server
      "#{File.cwd!()}/test/data/upload_AB&*!(#)C)(&*^$#!D+HIE1~@测试.txt" =>
        "/201711/1/upload_AB&*!(#)C)(&*^$#!D+HIE1~@测试.txt"
    }

    for {path_to_local_file, object_name} <- files_to_upload do
      file_binary = File.read!(path_to_local_file)

      put_object_vars = %PutObject{
        object_name: object_name,
        file_binary: file_binary,
        bucket_name: @bucket_name,
        region: Region.cn_hangzhou()
      }

      result = Client.put_object(@account, put_object_vars)
      Logger.info("result: #{inspect(result, pretty: true)}")
      {:ok, response} = result

      assert response.request_url ==
               "https://#{@bucket_name}.oss-cn-hangzhou.aliyuncs.com#{Client.encode_resource(object_name)}"

      assert response.status_code == 200
    end

    # put object and append a md5 hash value(base on the content of the uploading file) to name the uploaded object.
    # the initial character of `object_name` does not require with `/`, we will automatically amend it with `/` if needed.
    path_to_local_file = "#{File.cwd!()}/test/data/upload_text.txt"
    file_binary = File.read!(path_to_local_file)

    put_object_vars = %PutObject{
      object_name: "201711/1/2.txt",
      file_binary: file_binary,
      bucket_name: @bucket_name,
      region: Region.cn_hangzhou(),
      naming_with_hash: true
    }

    result = Client.put_object(@account, put_object_vars)
    Logger.info("put_object result: #{inspect(result, pretty: true)}")
    {:ok, response} = result

    assert response.request_url ==
             "https://#{@bucket_name}.oss-cn-hangzhou.aliyuncs.com/201711/1/2-a833b9ee4bf75bf13f934913bddc4774.txt"

    assert response.status_code == 200
  end

  test "get object" do
    object_name = "/201711/1/1.txt"

    oss_get_object = %GetObject{
      object_name: object_name,
      bucket_name: @bucket_name,
      region: Region.cn_hangzhou()
    }

    result = Client.get_object(@oss_account, oss_get_object, with_external_endpoint)

    {:ok, response} = result
    assert response.status_code == 200

    assert response.request_url ==
             "https://#{@bucket_name}.oss-cn-hangzhou.aliyuncs.com/201711/1/1.txt"

    assert is_binary(response.body) == true
  end

  test "copy object" do
    path_to_local_file = "#{File.cwd!()}/test/data/upload_text.txt"
    file_binary = File.read!(path_to_local_file)

    put_object_vars = %PutObject{
      object_name: "/copytest/old/1.txt",
      file_binary: file_binary,
      bucket_name: @bucket_name,
      region: Region.cn_hangzhou(),
      naming_with_hash: true
    }

    result = Client.put_object(@account, put_object_vars)
    Logger.info("test copy, put_object result: #{inspect(result, pretty: true)}")
    {:ok, response} = result

    assert response.request_url ==
             "https://#{@bucket_name}.oss-cn-hangzhou.aliyuncs.com/copytest/old/1-a833b9ee4bf75bf13f934913bddc4774.txt"

    assert response.status_code == 200

    copy_from_object = List.last(String.split(response.request_url, ".com"))
    copy_to_object = "/copytest/new/1-a833b9ee4bf75bf13f934913bddc4774.txt"

    copy_object_vars = %CopyObject{
      copy_from_object: copy_from_object,
      copy_to_object: copy_to_object,
      bucket_name: @bucket_name,
      region: Region.cn_hangzhou()
    }

    copy_result = Client.copy_object(@account, copy_object_vars)
    Logger.info("test copy, copy_object result: #{inspect(copy_result, pretty: true)}")
    {:ok, response} = copy_result

    assert response.request_url ==
             "https://#{@bucket_name}.oss-cn-hangzhou.aliyuncs.com/copytest/new/1-a833b9ee4bf75bf13f934913bddc4774.txt"

    assert response.status_code == 200

    # with Chinese characters
    path_to_local_file = "#{File.cwd!()}/test/data/upload_测试.txt"
    file_binary = File.read!(path_to_local_file)

    put_object_vars = %PutObject{
      object_name: "/copytest/old/测试.txt",
      file_binary: file_binary,
      bucket_name: @bucket_name,
      region: Region.cn_hangzhou(),
      naming_with_hash: true
    }

    result = Client.put_object(@account, put_object_vars)
    Logger.info("test copy, put_object result: #{inspect(result, pretty: true)}")
    {:ok, response} = result

    assert response.request_url ==
             "https://#{@bucket_name}.oss-cn-hangzhou.aliyuncs.com/copytest/old/%E6%B5%8B%E8%AF%95-a833b9ee4bf75bf13f934913bddc4774.txt"

    assert response.status_code == 200

    copy_from_object = List.last(String.split(response.request_url, ".com"))

    copy_to_object = String.replace(copy_from_object, "old", "new")

    copy_object_vars = %CopyObject{
      copy_from_object: copy_from_object,
      copy_to_object: copy_to_object,
      bucket_name: @bucket_name,
      region: Region.cn_hangzhou()
    }

    copy_result = Client.copy_object(@account, copy_object_vars)
    Logger.info("test copy, copy_object result: #{inspect(copy_result, pretty: true)}")
    {:ok, response} = copy_result

    assert response.request_url ==
             "https://#{@bucket_name}.oss-cn-hangzhou.aliyuncs.com/copytest/new/%E6%B5%8B%E8%AF%95-a833b9ee4bf75bf13f934913bddc4774.txt"

    assert response.status_code == 200

    # with special characters
    path_to_local_file = "#{File.cwd!()}/test/data/upload_AB&*!(#)C)(&*^$#!D+HIE1~@测试.txt"
    file_binary = File.read!(path_to_local_file)

    put_object_vars = %PutObject{
      object_name: "/copytest/old/upload_AB&*!(#)C)(&*^$#!D+HIE1~@测试.txt",
      file_binary: file_binary,
      bucket_name: @bucket_name,
      region: Region.cn_hangzhou(),
      naming_with_hash: true
    }

    result = Client.put_object(@account, put_object_vars)
    Logger.info("test copy, put_object result: #{inspect(result, pretty: true)}")
    {:ok, response} = result

    assert response.request_url ==
             "https://#{@bucket_name}.oss-cn-hangzhou.aliyuncs.com/copytest/old/upload_AB%26%2A%21%28%23%29C%29%28%26%2A%5E%24%23%21D%2BHIE1~%40%E6%B5%8B%E8%AF%95-a833b9ee4bf75bf13f934913bddc4774.txt"

    assert response.status_code == 200

    copy_from_object = List.last(String.split(response.request_url, ".com"))

    copy_to_object = String.replace(copy_from_object, "old", "new")

    copy_object_vars = %CopyObject{
      copy_from_object: copy_from_object,
      copy_to_object: copy_to_object,
      bucket_name: @bucket_name,
      region: Region.cn_hangzhou()
    }

    copy_result = Client.copy_object(@account, copy_object_vars)
    Logger.info("test copy, copy_object result: #{inspect(copy_result, pretty: true)}")
    {:ok, response} = copy_result

    assert response.request_url ==
             "https://#{@bucket_name}.oss-cn-hangzhou.aliyuncs.com/copytest/new/upload_AB%26%2A%21%28%23%29C%29%28%26%2A%5E%24%23%21D%2BHIE1~%40%E6%B5%8B%E8%AF%95-a833b9ee4bf75bf13f934913bddc4774.txt"

    assert response.status_code == 200
  end

  test "copy object with encode" do
    path_to_local_file = "#{File.cwd!()}/test/data/O0Owc-Moutai Three Chinese Zodiacs - 53%.png"
    file_binary = File.read!(path_to_local_file)

    put_object_vars = %PutObject{
      object_name: "/tmp/O0Owc-Moutai Three Chinese Zodiacs - 53%.png",
      file_binary: file_binary,
      bucket_name: @bucket_name,
      region: Region.cn_hangzhou()
    }

    result = Client.put_object(@account, put_object_vars)
    Logger.info("test copy, put_object result: #{inspect(result, pretty: true)}")
    {:ok, response} = result

    assert response.request_url ==
             "https://#{@bucket_name}.oss-cn-hangzhou.aliyuncs.com/tmp/O0Owc-Moutai+Three+Chinese+Zodiacs+-+53%25.png"

    assert response.status_code == 200

    copy_from_object = List.last(String.split(response.request_url, ".com"))
    copy_to_object = String.replace(copy_from_object, "tmp", "dev")

    copy_object_vars = %CopyObject{
      copy_from_object: copy_from_object,
      copy_to_object: copy_to_object,
      bucket_name: @bucket_name,
      region: Region.cn_hangzhou()
    }

    copy_result = Client.copy_object(@account, copy_object_vars)
    Logger.info("test copy, copy_object result: #{inspect(copy_result, pretty: true)}")
    {:ok, response} = copy_result

    assert response.request_url ==
             "https://#{@bucket_name}.oss-cn-hangzhou.aliyuncs.com/dev/O0Owc-Moutai%2BThree%2BChinese%2BZodiacs%2B-%2B53%25.png"

    assert response.status_code == 200
  end

  test "delete object" do
    path_to_local_file = "#{File.cwd!()}/test/data/upload_text.txt"
    file_binary = File.read!(path_to_local_file)

    put_object_vars = %PutObject{
      object_name: "/deletetest/test.txt",
      file_binary: file_binary,
      bucket_name: @bucket_name,
      region: Region.cn_hangzhou(),
      naming_with_hash: true
    }

    result = Client.put_object(@account, put_object_vars)
    Logger.info("test delete object, put_object result: #{inspect(result, pretty: true)}")
    {:ok, response} = result

    assert response.request_url ==
             "https://#{@bucket_name}.oss-cn-hangzhou.aliyuncs.com/deletetest/test-a833b9ee4bf75bf13f934913bddc4774.txt"

    assert response.status_code == 200

    del_object_vars = %DeleteObject{
      object_name: "/deletetest/test-a833b9ee4bf75bf13f934913bddc4774.txt",
      bucket_name: @bucket_name,
      region: Region.cn_hangzhou()
    }

    del_result = Client.delete_object(@account, del_object_vars)
    Logger.info("test delete object, delete_object result: #{inspect(del_result)}")
  end

  test "delete bucket" do
    delete_result = Client.delete_bucket(@account, @bucket_name, Region.cn_hangzhou())
    Logger.info("delete_bucket result: #{inspect(delete_result, pretty: true)}")
    {:ok, response} = delete_result
    assert String.contains?(response.body, "The bucket you tried to delete is not empty") == true
    assert response.status_code != 200
  end
end
