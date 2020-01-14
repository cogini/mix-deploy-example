# mix_deploy_example

This is a working example Elixir app which shows how to deploy using
[mix_deploy](https://github.com/cogini/mix_deploy) to a local system and via
[AWS CodeDeploy](https://aws.amazon.com/codedeploy/).

`mix_deploy` generates scripts which are used to deploy your app using systemd
on a server. It includes scripts to set up the initial system, deploy
code and handle configuration during startup. It uses
[mix_systemd](https://github.com/cogini/mix_systemd) to generate systemd unit
files.

# Deploying locally

These instructions show how to deploy an app to the same server you are building
on. That can be a $5/month [Digital Ocean](https://m.do.co/c/150575a88316) server.

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

We normally use ASDF, but compiling from source on a small server takes a while.

## Configure

Set up your production db password and `secret_key_base`, used by Phoenix to protect
session cookies.

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

Initialize the libraries, copying templates from `mix_systemd` and `mix_deploy` package dirs to `rel/templates`,
then generate files based on the config in `config/prod.exs`:

```shell
MIX_ENV=prod bin/build
```

That does the following:

```
mix systemd.init
MIX_ENV=prod mix systemd.generate

mix deploy.init
MIX_ENV=prod mix deploy.generate
chmod +x bin/*
```

This example loads environment vars from `/etc/mix-deploy-example/environment`:

```elixir
config :mix_systemd,
  dirs: [
    # Create /etc/mix-deploy-example dir
    :configuration,
  ],
  env_files: [
    # Load environment vars from /etc/mix-deploy-example/environment
    ["-", :configuration_dir, "/environment"],
  ]

config :mix_deploy,
  # List of scripts to generate
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

    # Release commands
    "set-env",
    "remote-console",
    "migrate",
  ],
  # This should match mix_systemd
  env_files: [
    ["-", :configuration_dir, "/environment"],
  ],
  # Have deploy-copy-files copy config/environment to /etc/mix-deploy-example
  copy_files: [
    %{
      src: "config/environment",
      dst: :configuration_dir,
      user: "$DEPLOY_USER",
      group: "$APP_GROUP",
      mode: "640"
    },
  ]
```

## Initialize the local system

Set up the local system for the app, creating users, directories, etc:

```shell
bin/deploy-create-users
bin/deploy-create-dirs

sudo mkdir -p /etc/mix-deploy-example
sudo chmod 750 /etc/mix-deploy-example
sudo chown deploy:app /etc/mix-deploy-example

cp bin/* /srv/mix-deploy-example/bin

bin/deploy-copy-files
bin/deploy-enable
```

`bin/deploy-copy-files` copies `config/environment` to `/etc/mix-deploy-example/environment`.
`systemd` then loads it on startup, setting OS environment vars.

Configure `config/releases.exs` to use `System.get_env/2` to read config from
the environment vars:

```elixir
config :mix_deploy_example, MixDeployExampleWeb.Endpoint,
  http: [:inet6, port: System.get_env("PORT") || 4000],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  cache_static_manifest: "priv/static/cache_manifest.json"

config :mix_deploy_example, MixDeployExample.Repo,
  url: System.get_env("DATABASE_URL")
```

# Log out and log in again

## Build

Build the app and make a release:

```shell
MIX_ENV=prod bin/build
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

## Test

Test it by making a request to the server:

```shell
curl -v http://localhost:4000/
```

If things aren't working right, you can roll back to the previous release:

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
    prod: [
      include_executables_for: [:unix],
      steps: [:assemble, :tar]
    ],
  ]
end
```

Configure `rel/env.sh.eex` and `rel/vm.args.eex` if necessary, e.g.
to [increase network ports](https://www.cogini.com/blog/tuning-tcp-ports-for-your-phoenix-app/).

See [the docs](https://hexdocs.pm/mix/Mix.Tasks.Release.html) for more details.

## Install mix_deploy and mix_systemd

Add libraries to deps from Hex:

```elixir
{:mix_deploy, "~> 0.7"}
```

Add `rel/templates` and `bin/deploy-*` to `.gitignore`.

## Copy build and utility scripts

Copy scripts from the `bin/` directory to the `bin/` directory of your project.

These scripts install the required dependencies:

- `build-install-asdf`
- `build-install-asdf-deps-centos`
- `build-install-asdf-deps-ubuntu`
- `build-install-asdf-init`
- `build-install-asdf-macos`
- `build-install-deps-centos`
- `build-install-deps-ubuntu`

This script builds the app:

- `build`

This script verifies that the app is running correctly:

- `bin/validate-service`

## Configure Phoenix for OTP releases

Update `config/prod.exs` to run from release:

- Start Phoenix endpoints automatically

```elixir
config :phoenix, :serve_endpoints, true
```

- Don't import `prod.secret.exs`

```elixir
`# import_config "prod.secret.exs"`
```

## Configure mix_deploy and mix_systemd

Configure `mix_deploy` and `mix_systemd` in `config/prod.exs`.

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

- Add `lib/mix_deploy_example/release.ex` as described in
  [Ecto migrations and custom commands](https://hexdocs.pm/phoenix/releases.html#ecto-migrations-and-custom-commands)

## Add TOML config provider

- Add to `mix.exs`

```elixir
defp deps do
  [
    {:toml_config, "~> 0.1.0"}, # Mix releases
  ]
end
```

```
defp releases do
  [
    aws: [
      include_executables_for: [:unix],
      config_providers: [
        {TomlConfigProvider, path: "/etc/mix-deploy-example/config.toml"}
      ],
      steps: [:assemble, :tar]
    ],
  ]
end
```

## Add Ansible scripts

See `ansible` dir.

## Add Docker file

```shell
build -f build/docker/Dockerfile .
```
