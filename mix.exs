defmodule MixDeployExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :mix_deploy_example,
      version: "0.1.0",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      default_release: :mix_deploy_example,
      releases: releases()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {MixDeployExample.Application, []},
      extra_applications: [:logger, :runtime_tools, :ssl]
    ]
  end

  # Paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp releases do
    [
      prod: [
        include_executables_for: [:unix],
        steps: [:assemble, :tar]
      ],
      aws: [
        include_executables_for: [:unix],
        steps: [:assemble, :tar],
        config_providers: [
          {TomlConfigProvider, path: "/etc/mix-deploy-example/config.toml"}
        ]
      ]
    ]
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:distillery, "~> 2.1"},
      {:ecto_sql, "~> 3.0"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      # {:mix_deploy, "~> 0.7"},
      {:mix_deploy, github: "cogini/mix_deploy", branch: "master"},
      {:mix_systemd, github: "cogini/mix_systemd", override: true},
      {:phoenix, "~> 1.4.6"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_pubsub, "~> 1.1"},
      {:plug_cowboy, "~> 2.0"},
      {:postgrex, ">= 0.0.0"},
      # Mix releases
      {:toml_config, "~> 0.1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
