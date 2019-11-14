defmodule MetadataLogger.Tesla.MixProject do
  use Mix.Project

  @version "0.1.1-dev"

  def project do
    [
      app: :metadata_logger_tesla,
      version: @version,
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # hex
      description: "Tesla Middleware to log request and response into in metadata",
      package: package(),

      # ex_doc
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:tesla, "~> 1.0"},
      {:bypass, "~> 1.0", only: :test},
      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/elixir-metadata-logger/metadata_logger_tesla",
        "Changelog" =>
          "https://github.com/elixir-metadata-logger/metadata_logger_tesla/blob/master/CHANGELOG.md"
      },
      maintainers: ["Chulki Lee"]
    ]
  end

  defp docs do
    [
      name: "MetadataLogger.Tesla",
      source_ref: "v#{@version}",
      canonical: "https://hexdocs.pm/metadata_logger_tesla",
      source_url: "https://github.com/elixir-metadata-logger/metadata_logger_tesla"
    ]
  end
end
