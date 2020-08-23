defmodule ConfigPin.MixProject do
  use Mix.Project

  @description "A BeagleBone config-pin wrapper for use in Elixir Nerves projects."

  def project do
    [
      app: :nerves_config_pin,
      description: @description,
      version: "0.1.0",
      elixir: "~> 1.10",
      package: package(),
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      test_coverage: [tool: ExCoveralls, test_task: "espec"],
      dialyzer: [
        ignore_warnings: "dialyzer.ignore.exs",
        list_unused_filters: true,
        plt_add_apps: [:mix],
        plt_file: {:no_warn, plt_file_path()}
      ],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coverage.show": :test,
        espec: :test,
      ],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      "coverage.show": "do coveralls.html, cmd xdg-open cover/excoveralls.html",
      "docs.show": "do docs, cmd xdg-open doc/index.html",
      test: "espec --cover",
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:excoveralls, "~> 0.13", only: :test},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:espec, "~> 1.8", only: :test},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
    ]
  end

  defp docs do
    [
      main:   "ConfigPin",
      extras: ["README.md"]
    ]
  end

  defp package do
    [
      name: "nerves_config_pin",
      maintainers: ["Alex McLain"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/amclain/nerves_config_pin"}
    ]
  end

  # Path to the dialyzer .plt file.
  defp plt_file_path do
    [Mix.Project.build_path(), "plt", "dialyxir.plt"]
    |> Path.join()
    |> Path.expand()
  end
end
