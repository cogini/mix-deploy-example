import Config

# Runtime configuration

config :mix_deploy_example, MixDeployExampleWeb.Endpoint,
  http: [:inet6, port: System.get_env("PORT") || 4000],
  secret_key_base: System.get_env("SECRET_KEY_BASE")

config :mix_deploy_example, MixDeployExample.Repo, url: System.get_env("DATABASE_URL")
