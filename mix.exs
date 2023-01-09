defmodule TallariumCredo.Mixfile do
  use Mix.Project

  def project do
    [
      app: :tallarium_credo,
      version: "0.0.5",
      elixir: ">= 1.10.1",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  defp aliases do
    [
      ci: [
        "format --check-formatted",
        "credo --strict",
        "compile --warnings-as-errors"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:credo, ">= 1.5.1", only: [:dev, :test]},
      {:destructure, "~> 0.2"}
    ]
  end
end
