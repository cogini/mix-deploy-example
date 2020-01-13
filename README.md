# mix_deploy_example

This is a working example Elixir app which shows how to deploy using
[mix_deploy](https://github.com/cogini/mix_deploy) to a local system and via
[AWS CodeDeploy](https://aws.amazon.com/codedeploy/).

`mix_deploy` generates scripts which are used to deploy your app using systemd
on a server. It includes scripts to set up the initial system, deploy
code and handle configuration during startup.

It uses [mix_systemd](https://github.com/cogini/mix_systemd) to generate a corresponding
systemd unit file.

# Deploying locally

These instructions show how to deploy an app to the build server.

## Install build dependencies

Install Erlang, Elixir and Node.js from OS packages:

```shell
# Ubuntu
LANG=en_US.UTF-8 sudo bin/build-install-deps-ubuntu

# CentOS
LANG=en_US.UTF-8 sudo bin/build-install-deps-centos
```

or install using [ASDF](https://www.cogini.com/blog/using-asdf-with-elixir-and-phoenix/):

```shell
# Ubuntu
LANG=en_US.UTF-8 sudo bin/build-install-asdf-deps-ubuntu && bin/build-install-asdf-init

# CentOS
LANG=en_US.UTF-8 sudo bin/build-install-asdf-deps-centos && bin/build-install-asdf-init
```

## Configure

Generate `secret_key_base`:

```shell
mix phx.gen.secret 64
```

Create a database using
[Digital Ocean's Managed Databases Service](https://www.cogini.com/blog/multiple-databases-with-digital-ocean-managed-databases-service/).

Create the file `config/environment` with app secrets:

```shell
SECRET_KEY_BASE="EOdJB1T39E5Cdeebyc8naNrOO4HBoyfdzkDy2I8Cxiq4mLvIQ/0tK12AK1ahrV4y"
DATABASE_URL="ecto://doadmin:SECRET@db-postgresql-sfo2-xxxxx-do-user-yyyyyy-0.db.ondigitalocean.com:25060/defaultdb?ssl=true"
```

## Initialize `mix_systemd` and `mix_deploy`

```shell
mix systemd.init
mix systemd.generate

mix deploy.init
mix deploy.generate
chmod +x bin/*
```

## Initialize the local system

Run this once to set up the system for the app, creating users, directories, etc:

```shell
sudo bin/deploy-init-local
```

This runs:

```shell
bin/deploy-create-users
bin/deploy-create-dirs

cp bin/* /srv/mix-deploy-example/bin

bin/deploy-copy-files
bin/deploy-enable
```

`bin/deploy-copy-files` copies `bin/environment` to
`/etc/mix-deploy-example/environment`.
`systemd` loads it on startup, setting OS environment vars.

Configure `config/prod.exs` to use `System.get_env/1` to read config
from the environment:

```elixir
config :mix_deploy_example, MixDeployExampleWeb.Endpoint,
  http: [:inet6, port: System.get_env("PORT") || 4000],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  cache_static_manifest: "priv/static/cache_manifest.json"

config :mix_deploy_example, MixDeployExample.Repo,
  url: System.get_env("DATABASE_URL")
```

## Build

Build the app and make a release:

```shell
bin/build
```

## Deploy

Deploy the release to the local machine:

```shell
# Extract release to target directory, creating current symlink
bin/deploy-release

# Run database migrations
bin/deploy-migrate

# Restart the systemd unit
sudo bin/deploy-restart
```

Make a request to the server:

```shell
curl -v http://localhost:4000/
```

To open a console on the running release:

```shell
sudo -i -u app /srv/mix-deploy-example/bin/deploy-remote-console
```

TODO: update for mix

If things aren't working right with the release, roll back to the previous
release:

```shell
bin/deploy-rollback
sudo bin/deploy-restart
```

# Preparing an existing project for deployment

Following are the steps used to set up this repo. You can do the same to add
it to your own project.

## Generate Phoenix project

```shell
mix phx.new mix_deploy_example
mix deps.get
cd assets && npm install && node node_modules/webpack/bin/webpack.js --mode development
```

- Add `mix.lock` to git
- Add `package-lock.json` to git

## Configure Elixir 1.9+ mix releases

Configure releases in `mix.exs`:

```elixir
defp releases do
  [
    mix_deploy_example: [
      include_executables_for: [:unix],
      # config_providers: [
      #   {TomlConfigProvider, path: "/etc/mix-deploy-example/config.toml"}
      # ],
      steps: [:assemble, :tar]
    ],
  ]
end
```

Configure `rel/env.sh.eex` and `rel/vm.args.eex` if necessary, e.g.
[increasing network ports](https://www.cogini.com/blog/tuning-tcp-ports-for-your-phoenix-app/).

See [the docs](https://hexdocs.pm/mix/Mix.Tasks.Release.html) for more details.

## Install mix_deploy and mix_systemd

Add libraries to deps from Hex:

```elixir
{:mix_deploy, "~> 0.7.0"}
```

Add `rel/templates` and `bin/deploy-*` to `.gitignore`.

## Copy build and utility scripts

Copy these scripts from the `bin/` directory to the `bin/` directory of your project.

These scripts install the required dependencies:

- `build-install-asdf`
- `build-install-asdf-deps-centos`
- `build-install-asdf-deps-ubuntu`
- `build-install-asdf-init`
- `build-install-asdf-macos`
- `build-install-deps-centos`
- `build-install-deps-ubuntu`

This script builds your application:

- `build`

This script verifies that your application is running correctly:

- `bin/validate-service`

## Configure Phoenix for OTP releases

Update `config/prod.exs` to run from release:

- Start Phoenix endpoints

```elixir
config :phoenix, :serve_endpoints, true
```

- Don't import `prod.secret.exs`

```elixir
`# import_config "prod.secret.exs"`
```

## Configure mix_deploy and mix_systemd

Configure `mix_deploy` and `mix_systemd` in `config/prod.exs`:

```elixir
config :mix_systemd,
  # release_system: :distillery,
  dirs: [
    # Create /etc/mix-deploy-example
    :configuration,
    # Create /run/mix-deploy-example
    # :runtime,
  ],
  # Don't clear runtime dir between restarts, useful for debugging
  # runtime_directory_preserve: "yes",
  env_files: [
    # Load environment vars from /srv/mix-deploy-example/etc/environment
    ["-", :deploy_dir, "/etc/environment"],
    # Load environment vars from /etc/mix-deploy-example/environment
    ["-", :configuration_dir, "/environment"],
  ],
  # env_vars: [
  #   # Tell release scripts to use runtime directory for temp files
  #   # Mix
  #   ["RELEASE_TMP=", :runtime_dir],
  #   # Distillery
  #   # ["RELEASE_MUTABLE_DIR=", :runtime_dir],
  #   # "REPLACE_OS_VARS=true",
  # ],
  app_user: "app",
  app_group: "app"

config :mix_deploy,
  # release_system: :distillery,
  # release_name: Mix.env(),
  templates: [
    # Systemd wrappers
    "start",
    "stop",
    "restart",
    "enable",

    # System setup
    "create-users",
    "create-dirs",

    # Local deploy
    "init-local",
    "copy-files",
    "release",
    "rollback",

    # CodeDeploy
    # "clean-target",
    # "extract-release",
    # "set-perms",

    # CodeBuild
    # "stage-files",
    # "sync-assets-s3",

    # Release commands
    "set-env",
    "remote-console",
    "migrate",

    # Runtime environment
    # "sync-config-s3",
    # "runtime-environment-file",
    # "runtime-environment-wrap",
    # "set-cookie-ssm",
  ],
  # This should match mix_systemd
  env_files: [
    ["-", :deploy_dir, "/etc/environment"],
    ["-", :configuration_dir, "/environment"],
  ],
  # This should match mix_systemd
  # env_vars: [
  #   # Tell release scripts to use runtime directory for temp files
  #   # Mix
  #   ["RELEASE_TMP=", :runtime_dir],
  #   # Distillery
  #   # ["RELEASE_MUTABLE_DIR=", :runtime_dir],
  #   # "REPLACE_OS_VARS=true",
  # ],
  # Have deploy-copy-files copy config/environment to /etc/mix-deploy-example
  copy_files: [
    %{
      src: "config/environment",
      dst: :configuration_dir,
      user: "$DEPLOY_USER",
      group: "$APP_GROUP",
      mode: "640"
    },
  ],
  app_user: "app",
  app_group: "app"
```

## Configure ASDF

Create a `.tool-versions` file in the root of your project, describing the versions
of OTP, Elixir, and Node that you will be building with:

```
erlang 22.2
elixir 1.9.4
nodejs 10.15.3
```

## Configure for CodeDeploy

- Add `appspec.yml`

## Configure for CodeBuild

- Add `buildspec.yml`

## Add database migrations

Add a [Distillery custom command to run database migrations](https://www.cogini.com/blog/running-ecto-migrations-in-production-releases-with-distillery-custom-commands/)

- Add `lib/mix_deploy_example/tasks/migrate.ex`

- Add TOML lib to `mix.exs`

## Add Ansible scripts

## Add Docker file

```shell
build -f build/docker/Dockerfile .
```
