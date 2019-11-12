import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mix_deploy_example, MixDeployExampleWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :mix_deploy_example, MixDeployExample.Repo,
  username: "postgres",
  password: "postgres",
  database: "mix_deploy_example_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
