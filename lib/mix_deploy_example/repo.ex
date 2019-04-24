defmodule MixDeployExample.Repo do
  use Ecto.Repo,
    otp_app: :mix_deploy_example,
    adapter: Ecto.Adapters.Postgres
end
