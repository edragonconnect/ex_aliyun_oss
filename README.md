# ExAliyunOss

**Aliyun OSS SDK for Elixir**

## Implemented API

* put_bucket
* put_bucket_lifecycle
* delete_bucket
* put_object
* copy_object
* delete_object

Add Configuration in `config.exs`:

```elixir
config :ex_aliyun_oss,
  accounts: %{
    "READABLE_OSS_ACCOUNT_NAME" => %{
      access_key_id: "your_access_key_id",
      access_key_secret: "your_access_key_secret"
    },
    ...more...
  },
  clients_pool: [size: 100, max_overflow: 20]
```


