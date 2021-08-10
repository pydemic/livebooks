defmodule Phi do
  use Mix.Project

  def project do
    [
      app: :phi,
      version: "0.0.1",
      elixir: "~> 1.12",
      elixirc_paths: ["lib"],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Phi.Application, []},
      extra_applications: [:logger, :runtime_tools, :inets, :ssl]
    ]
  end

  defp aliases do
    []
  end

  defp deps do
    [
      {:flow, "~> 1.1.0"},
      {:nimble_csv, "~> 1.1.0"}
    ]
  end
end
