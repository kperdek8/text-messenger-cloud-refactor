defmodule AwsMockup.MixProject do
  use Mix.Project

  def project do
    [
      app: :aws_mockup,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AwsMockup.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:plug_cowboy, "~> 2.6"},
      {:jose, "~> 1.11"},
      {:jason, "~> 1.4"},
      { :uuid, "~> 1.1" }
    ]
  end

  defp aliases do
    []
  end
end
