defmodule TeslaMetadataLogger.MixProject do
  use Mix.Project

  def project do
    [
      app: :tesla_metadata_logger,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:tesla, "~> 1.0"}
    ]
  end
end
