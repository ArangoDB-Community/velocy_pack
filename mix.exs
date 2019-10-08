defmodule VelocyPack.MixProject do
  use Mix.Project

  @version "0.1.4"
  @description """
  An Elixir parser and generator for VelocyPack v1.
  """
  @source_url "https://github.com/ArangoDB-Community/velocy_pack"
  @homepage_url "https://github.com/arangodb/velocypack/blob/master/VelocyPack.md"

  def project do
    [
      app: :velocy,
      version: @version,
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      name: "VelocyPack",
      description: @description,
      source_url: @source_url,
      homepage_url: @homepage_url,
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: ["README.md"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:ex_doc, "> 0.0.0", only: :dev, runtime: false}
    ]
  end
end
