defmodule ExAliyunOss.Client.Object do
  alias ExAliyunOss.{HttpMethod, Request}
  require HttpMethod
  require Logger

  def request_to_put_object(var) do
    verified_object_name = verify_object_name(var.object_name)

    verified_object_name =
      if var.naming_with_hash do
        naming_with_hash(verified_object_name, var.file_binary)
      else
        verified_object_name
      end

    content_type = MIME.from_path(verified_object_name)

    headers = %{
      "content-length" => byte_size(var.file_binary),
      "content-type" => content_type
    }

    %Request{
      method: HttpMethod.put(),
      resource: "/#{var.bucket_name}#{verified_object_name}",
      body: var.file_binary,
      headers: headers,
      region: var.region,
      bucket_name: var.bucket_name,
      supplement: %{object_name: verified_object_name, content_type: content_type}
    }
  end

  def request_to_get_object(var) do
    verified_object_name = verify_object_name(var.object_name)

    %Request{
      method: HttpMethod.get(),
      resource: "/#{var.bucket_name}#{verified_object_name}",
      body: "",
      region: var.region,
      bucket_name: var.bucket_name,
      supplement: %{object_name: verified_object_name}
    }
  end

  def request_to_get_object_meta(var) do
    verified_object_name = verify_object_name(var.object_name)

    %Request{
      method: HttpMethod.head(),
      resource: "/#{var.bucket_name}#{verified_object_name}",
      body: "",
      region: var.region,
      bucket_name: var.bucket_name,
      supplement: %{object_name: verified_object_name}
    }
  end

  def request_to_copy_object(var) do
    # since may copy from an object name with an encoded name (e.g contain Chinese character),
    # so try to decode in the first to avoid double encode uri with the encoded uri when send the final request.
    verified_copy_to_object_name = verify_object_name(var.copy_to_object) |> URI.decode()
    verified_copy_from_object_name = verify_object_name(var.copy_from_object)
    supplement_headers = var.headers

    headers =
      if not is_map(supplement_headers) do
        raise ExAliyunOss.Error,
              "Invalid supplement headers when copy object: #{inspect(supplement_headers)}"
      else
        copy_source = "/#{var.bucket_name}#{verified_copy_from_object_name}"
        Map.merge(supplement_headers, %{"x-oss-copy-source" => copy_source})
      end

    content_type = MIME.from_path(verified_copy_to_object_name)

    %Request{
      method: HttpMethod.put(),
      resource: "/#{var.bucket_name}#{verified_copy_to_object_name}",
      headers: headers,
      region: var.region,
      bucket_name: var.bucket_name,
      supplement: %{object_name: verified_copy_to_object_name, content_type: content_type}
    }
  end

  def request_to_delete_object(var) do
    verified_object_name = verify_object_name(var.object_name)

    %Request{
      method: HttpMethod.delete(),
      resource: "/#{var.bucket_name}#{verified_object_name}",
      body: "",
      region: var.region,
      bucket_name: var.bucket_name,
      supplement: %{object_name: verified_object_name}
    }
  end

  defp verify_object_name(object_name) do
    # verify and ensure the verified `object_name` starts with "/"
    splited = String.trim(object_name) |> String.split("/")

    if Enum.slice(splited, 1..-1) |> Enum.any?(fn item -> item == "" end) do
      raise ExAliyunOss.Error, "Invalid object_name: #{inspect(object_name)}"
    else
      if Enum.at(splited, 0) != "" do
        "/" <> object_name
      else
        object_name
      end
    end
  end

  defp naming_with_hash(object_name, file_binary) do
    hash = :crypto.hash(:md5, file_binary) |> Base.encode16(case: :lower)
    splited = String.split(object_name, ".")

    case Enum.slice(splited, 0..-2) do
      [] ->
        "#{object_name}-#{hash}"

      _ ->
        {forepart_items, [file_extension]} = Enum.split(splited, length(splited) - 1)
        forepart = Enum.join(forepart_items, ".")
        "#{forepart}-#{hash}.#{file_extension}"
    end
  end
end
