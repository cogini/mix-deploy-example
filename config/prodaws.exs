use Mix.Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :mix_deploy_example, MixDeployExampleWeb.Endpoint,
  http: [:inet6, port: System.get_env("PORT") || 4000],
  # http: [:inet6, port: {:system, "PORT"}],
  https: [
    port: System.get_env("HTTPS_PORT") || 4001,
    cipher_suite: :strong,
    keyfile: "/etc/mix-deploy-example/ssl/app-https.key",
    certfile: "/etc/mix-deploy-example/ssl/app-https.cert.pem",
    # cacertfile: "/etc/mix-deploy-example/ssl/app-https.cacert.pem",
    # dhfile: "/etc/mix-deploy-example/ssl/app-https.dh.pem",
  ],
  # force_ssl: [rewrite_on: [:x_forwarded_proto]],
  # force_ssl: [hsts: true],
  # url: [host: {:system, "HOST"}, port: 443],
  # static_url: [host: {:system, "ASSETS_HOST"}, port: 443],
  url: [host: System.get_env("HOST"), port: 443],
  static_url: [host: System.get_env("ASSETS_HOST"), port: 443],
  cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger, level: :info

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :mix_deploy_example, MixDeployExampleWeb.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [
#         :inet6,
#         port: 443,
#         cipher_suite: :strong,
#         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
#       ]
#
# The `cipher_suite` is set to `:strong` to support only the
# latest and more secure SSL ciphers. This means old browsers
# and clients may not be supported. You can set it to
# `:compatible` for wider support.
#
# `:keyfile` and `:certfile` expect an absolute path to the key
# and cert in disk or a relative path inside priv, for example
# "priv/ssl/server.key". For all supported SSL configuration
# options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
#
# We also recommend setting `force_ssl` in your endpoint, ensuring
# no data is ever sent via http, always redirecting to https:
#
#     config :mix_deploy_example, MixDeployExampleWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases (distillery)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:

config :phoenix, :serve_endpoints, true

# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :mix_deploy_example, MixDeployExampleWeb.Endpoint, server: true
#
# Note you can't rely on `System.get_env/1` when using releases.
# See the releases documentation accordingly.

config :mix_systemd,
  app_user: "app",
  app_group: "app",
  service_type: :exec,
  env_vars: [
    "REPLACE_OS_VARS=true",
    "HOME=/home/app"
  ],
  exec_start_pre: [
    "!/srv/mix-deploy-example/bin/deploy-sync-config-s3"
  ]

config :mix_deploy,
  app_user: "app",
  app_group: "app",
  restart_method: :systemctl,
  service_type: :exec


# Finally import the config/prod.secret.exs which should be versioned
# separately.
# import_config "prod.secret.exs"
