defmodule ExAliyunOss.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_aliyun_oss,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex],
      mod: {ExAliyunOss.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.2"},
      {:hackney, "~> 1.17"},
      {:timex, "~> 3.4"},
      {:poolboy, "~> 1.5.1"},
      {:mime, "~> 1.3"},
    ]
  end
end
