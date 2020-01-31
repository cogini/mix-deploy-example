defmodule MixDeployExample.ReleaseTasks.Migrate do
  @moduledoc "Mix task to run Ecto database migrations"

  # CHANGEME: Name of app as used by Application.get_env
  @app :mix_deploy_example
  # CHANGEME: Name of app repo module
  @repo_module MixDeployExample.Repo

  def run(args \\ [])

  def run(_args) do
    ext_name = @app |> to_string |> String.replace("_", "-")
    config_dir = Path.join("/etc", ext_name)

    app_env = [{@app, Application.get_all_env(@app)}]

    config_exs = Path.join(config_dir, "config.exs")

    app_env =
      if File.exists?(config_exs) do
        IO.puts("==> Loading config file #{config_exs}")
        Config.Reader.merge(app_env, Config.Reader.read!(config_exs))
      else
        app_env
      end

    config_toml = Path.join(config_dir, "config.toml")

    app_env =
      if File.exists?(config_toml) do
        IO.puts("==> Loading config file #{config_toml}")
        TomlConfigProvider.load(app_env, config_toml)
      else
        app_env
      end

    repo_config = app_env[@app][@repo_module]
    repo_config = Keyword.put(repo_config, :adapter, Ecto.Adapters.Postgres)
    Application.put_env(@app, @repo_module, repo_config)

    # Start requisite apps
    IO.puts("==> Starting applications..")

    for app <- [:crypto, :ssl, :postgrex, :ecto, :ecto_sql] do
      {:ok, res} = Application.ensure_all_started(app)
      IO.puts("==> Started #{app}: #{inspect(res)}")
    end

    # Start repo
    IO.puts("==> Starting repo")
    {:ok, _pid} = apply(@repo_module, :start_link, [[pool_size: 2, log: :info, log_sql: true]])

    # Run migrations for the repo
    IO.puts("==> Running migrations")
    priv_dir = Application.app_dir(@app, "priv")
    migrations_dir = Path.join([priv_dir, "repo", "migrations"])

    opts = [all: true]
    config = apply(@repo_module, :config, [])
    pool = config[:pool]

    if function_exported?(pool, :unboxed_run, 2) do
      pool.unboxed_run(@repo_module, fn ->
        Ecto.Migrator.run(@repo_module, migrations_dir, :up, opts)
      end)
    else
      Ecto.Migrator.run(@repo_module, migrations_dir, :up, opts)
    end

    # Shut down
    :init.stop()
  end
end
