defmodule MixDeployExample.Release do
  @moduledoc """
  Run release commands.

  See [Ecto migrations and custom commands](https://hexdocs.pm/phoenix/releases.html#ecto-migrations-and-custom-commands).
  """

  @app :mix_deploy_example

  def migrate do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    for app <- [:crypto, :ssl, :postgrex, :ecto, :ecto_sql] do
      {:ok, res} = Application.ensure_all_started(app)
      IO.puts("==> Started #{app}: #{inspect(res)}")
    end

    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
