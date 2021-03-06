defmodule SmartRentEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :smart_rent_ex,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:typed_struct, "~> 0.2.1"},
      {:phoenix_client, "~> 0.3"},
      {:retry, "~> 0.14"},
      {:tesla, "~> 1.4"},
      {:jason, "~> 1.0"}
    ]
  end
end
