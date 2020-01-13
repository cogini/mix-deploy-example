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

Install Erlang, Elixir and Node.js from OS packages or use
[ASDF](https://www.cogini.com/blog/using-asdf-with-elixir-and-phoenix/).

Install using OS packages:

```shell
# Ubuntu
LANG=en_US.UTF-8 sudo bin/build-install-deps-ubuntu

# CentOS
LANG=en_US.UTF-8 sudo bin/build-install-deps-centos
```

or

Install using ASDF:

```shell
# Ubuntu
LANG=en_US.UTF-8 sudo bin/build-install-asdf-deps-ubuntu && bin/build-install-asdf-init

# CentOS
LANG=en_US.UTF-8 sudo bin/build-install-asdf-deps-centos && bin/build-install-asdf-init
```

## Build

Build the app and make a release:

```shell
bin/build
```

## Configure

Create a file `config/environment` with contents like:

```shell
DATABASE_URL="ecto://foo_prod:Sekrit!@db.foo.local/foo_prod"
SECRET_KEY_BASE="EOdJB1T39E5Cdeebyc8naNrOO4HBoyfdzkDy2I8Cxiq4mLvIQ/0tK12AK1ahrV4y"
HOST="www.example.com"
ASSETS_HOST="assets.example.com"
```


Generate `secret_key_base` like this:

```shell
mix phx.gen.secret 64
```

The `bin/deploy-copy-files` script will copy it to `/etc/mix-deploy-example/environment`,
and `systemd` will load it on startup and set OS environment vars for the app.

## Initialize local system

Run this once to set up the system for the app, creating users, directories,
etc:

```shell
sudo bin/deploy-init-local
```

It runs `bin/deploy-copy-files`. If you change the `config/environment` file, run
it again.

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

If things aren't working right with the release, roll back to the previous
release with the following:

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

## Configure release

Add runtime config provider to `rel/config.exs`:

```elixir
environment :prod do
  set config_providers: [
    {Mix.Releases.Config.Providers.Elixir, ["/etc/mix-deploy-example/config.exs"]}
  ]
end
```

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
build -f docker/Dockerfile.build .
```
