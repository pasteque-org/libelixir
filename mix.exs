defmodule ArchethicClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :archethic_client,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      consolidate_protocols: Mix.env() == :prod,
      source_url: "https://github.com/pasteque-org/libelixir",
      docs: [
        main: "ArchethicClient"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ArchethicClient.Application, []}
    ]
  end

  # Specify dialyzer path
  defp dialyzer do
    [
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Web
      {:req, "~> 0.5"},
      # Currently using fork waiting for issue: https://github.com/CargoSense/absinthe_client/issues/19
      {:absinthe_client, git: "https://github.com/Neylix/absinthe_client.git"},

      # Utils
      {:decimal, "~> 2.0"},

      # Dev
      {:plug, "~> 1.0", only: [:dev, :test]},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:styler, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.37", only: :dev, runtime: false}
    ]
  end
end
