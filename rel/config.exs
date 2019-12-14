# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
~w(rel plugins *.exs)
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Distillery.Releases.Config,
    # This sets the default release built by `mix distillery.release`
    default_release: :default,
    # This sets the default environment used by `mix distillery.release`
    default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/config/distillery.html


# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  # If you are running Phoenix, you should make sure that
  # server: true is set and the code reloader is disabled,
  # even in dev mode.
  # It is recommended that you build with MIX_ENV=prod and pass
  # the --env flag to Distillery explicitly if you want to use
  # dev mode.
  set dev_mode: true
  set include_erts: false
  set cookie: :"Z)(SD?uO<^!K.q!Ci7}7a]4$p?^y:x^%K}wu&cg%)WPhoBS{KHTWtM56.L;7H}/b"
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"pRlPiv!OOD6@zc(%Du^>T19IH]2NQA0}$f9q10E<>UZ`K!dk.G6/4HV]!>3mRi.k"
  set vm_args: "rel/vm.args"

  set config_providers: [
    {Mix.Releases.Config.Providers.Elixir, ["${CONFIGURATION_DIR}/config.exs"]}
    # {Toml.Provider, [path: "${CONFIGURATION_DIR}/config.toml"]},
  ]

  set commands: [
    migrate: "rel/commands/migrate.sh"
  ]

  set overlays: [
    {:mkdir, "etc"},
    {:copy, "rel/etc/environment", "etc/environment"},
    # {:template, "rel/etc/environment", "etc/environment"}
  ]
end

environment :prodaws do
  set include_erts: true
  set include_src: false
  set cookie: :"pRlPiv!OOD6@zc(%Du^>T19IH]2NQA0}$f9q10E<>UZ`K!dk.G6/4HV]!>3mRi.k"
  set vm_args: "rel/vm.args"

  set config_providers: [
    # {Mix.Releases.Config.Providers.Elixir, ["${CONFIGURATION_DIR}/config.exs"]}
    {Toml.Provider, [path: "${CONFIGURATION_DIR}/config.toml"]},
  ]

  set commands: [
    migrate: "rel/commands/migrate.sh"
  ]

  set overlays: [
    {:mkdir, "etc"},
    {:copy, "rel/etc/environment", "etc/environment"},
    # {:template, "rel/etc/environment", "etc/environment"}
  ]
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix distillery.release`, the first release in the file
# will be used by default

release :mix_deploy_example do
  set version: current_version(:mix_deploy_example)
  set applications: [
    :runtime_tools
  ]
end
