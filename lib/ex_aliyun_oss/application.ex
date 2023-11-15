defmodule ExAliyunOss.Application do
  @moduledoc false
  use Application
  alias ExAliyunOss.{Account, Client}

  @clients_pool Application.compile_env(:ex_aliyun_oss, :clients_pool,
                  size: 100,
                  max_overflow: 100
                )

  def start(_type, _args) do
    children = load_oss_clients()
    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end

  defp load_oss_clients() do
    case Application.fetch_env(:ex_aliyun_oss, :accounts) do
      {:ok, accounts} ->
        Enum.map(Map.keys(accounts), fn account_name ->
          account_conf = Map.get(accounts, account_name)

          account = %Account{
            access_key_id: account_conf.access_key_id,
            access_key_secret: account_conf.access_key_secret
          }

          :poolboy.child_spec(
            Client.pool_name(account_name),
            pool_config_to_client(account_name),
            [account]
          )
        end)

      _ ->
        []
    end
  end

  defp pool_config_to_client(account_name) do
    [
      {:name, {:local, ExAliyunOss.Client.pool_name(account_name)}},
      {:worker_module, ExAliyunOss.Client},
      {:size, Keyword.get(@clients_pool, :size)},
      {:max_overflow, Keyword.get(@clients_pool, :max_overflow)},
      {:strategy, :fifo}
    ]
  end
end
