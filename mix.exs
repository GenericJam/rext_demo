defmodule RextDemo.MixProject do
  use Mix.Project

  def project do
    [app: :rext_demo, version: "0.1.0", elixir: "~> 1.19", deps: deps()]
  end

  def application do
    [extra_applications: [:logger], mod: {RextDemo.Application, []}]
  end

  defp deps do
    [
      {:rext, path: "../rext"},
      {:rext_dev, path: "../rext_dev", only: :dev, runtime: false}
    ]
  end
end
