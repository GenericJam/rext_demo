defmodule RectDemo.MixProject do
  use Mix.Project

  def project do
    [
      app: :rect_demo,
      version: "0.1.0",
      elixir: "~> 1.20",
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [extra_applications: [:logger], mod: {RectDemo.Application, []}]
  end

  defp deps do
    [
      {:rect, path: "../rect"},
      {:rect_dev, path: "../rect_dev", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:jump_credo_checks, "~> 0.4", only: [:dev, :test], runtime: false},
      {:ex_slop, "~> 0.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [setup: ["deps.get", "cmd git config core.hooksPath .githooks"]]
  end
end
