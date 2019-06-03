# mix_deploy_example

This is a working example Elixir app which shows how to deploy using
[mix_deploy](https://github.com/cogini/mix_deploy) to a local system and via
[AWS CodeDeploy](https://aws.amazon.com/codedeploy/).

`mix_deploy` generates scripts which are used to deploy your app using systemd
on a server. It includes scripts to set up the initial system, deploy
code and handle configuration during startup.

It uses [mix_systemd](https://github.com/cogini/mix_systemd) to generate a corresponding
systemd unit file.

# Running

## Install build dependencies

Install Erlang, Elixir and Node.js from OS packages or use
[ASDF](https://www.cogini.com/blog/using-asdf-with-elixir-and-phoenix/).

```shell
LANG=en_US.UTF-8 sudo bin/build-install-deps-ubuntu
```

## Build

Build the app and make a release:

```shell
bin/build
```

## Initialize local system

Run this once to set up the system for the app, creating users, directories,
etc:

```shell
sudo bin/deploy-init-local
```

## Configure

We keep secrets like database passwords and environment-specific configuration
like database host separate from the release, stored in a file in the OS
standard config directory for apps, under `/etc`.

Copy the sample production config:

```shell
cp config/prod.secret.exs.sample config/prod.secret.exs
```

Edit `config/prod.secret.exs`, configuring production database settings and `secret_key_base`.

Generate `secret_key_base` like this:

```shell
mix phx.gen.secret 64
```

Copy the runtime config to `/etc`.

```shell
cp config/prod.secret.exs /etc/mix-deploy-example/config.exs
chown deploy:app /etc/mix-deploy-example/config.exs
chmod 644 /etc/mix-deploy-example/config.exs
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

If things aren't working right with the release, roll back to the previous
release with the following:

```shell
bin/deploy-rollback
sudo bin/deploy-restart
```

# Preparing an existing project for deployment

Following are the steps used to set up this repo. You can do the same to add
it to your own project. This repo is built as a series of git commits, so you
can see how it works step by step.

## Generate Phoenix project

```shell
mix phx.new mix_deploy_example
mix deps.get
cd assets && npm install && node node_modules/webpack/bin/webpack.js --mode development
```

- Add `mix.lock` to git
- Add `package-lock.json` to git

## Install and configure Distillery

Add library to deps:

```elixir
{:distillery, "~> 2.0"}
```

Generate initial distillery config files in the `rel` dir:

```shell
mix release.init
```

Add `rel` dir to git.

## Configure release

[Increase network ports](https://www.cogini.com/blog/tuning-tcp-ports-for-your-phoenix-app/) in `rel/vm.args`.

Add runtime config provider to `rel/config.exs`:

```elixir
environment :prod do
  set config_providers: [
    {Mix.Releases.Config.Providers.Elixir, ["/etc/mix-deploy-example/config.exs"]}
  ]
end
```

Add `config/prod.secret.exs.sample` file.

## Install mix_deploy and mix_systemd

Add libraries to deps from Hex:

```elixir
{:mix_systemd, "~> 0.1.0"},
{:mix_deploy, "~> 0.1.0"}
```

Or from GitHub:

```elixir
{:mix_systemd, github: "cogini/mix_systemd", override: true},
{:mix_deploy, github: "cogini/mix_deploy"},
end
```

Add `rel/templates` and `bin/deploy-*` to `.gitignore`.

## Copy build and utility scripts

Copy these scripts from the `bin/` directory to the `bin/` directory of your project.

These scripts build your release or install the required dependencies:

- `build`
- `build-install-asdf`
- `build-install-asdf-deps-centos`
- `build-install-asdf-deps-ubuntu`
- `build-install-asdf-init`
- `build-install-asdf-macos`
- `build-install-deps-centos`
- `build-install-deps-ubuntu`

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

Configure `mix_deploy` and `mix_systemd`. If you are deploying on the local
system, then it will work without any configuration.

By default, it runs the app under an OS user matching the application, e.g.
`mix-deploy-example`, which is a bit long, so change `config/prod.exs` to use
`app` as the name of the OS user:

```elixir
config :mix_deploy,
  app_user: "app",
  app_group: "app"

config :mix_systemd,
  app_user: "app",
  app_group: "app"
```

## Configure ASDF

Create a `.tool-versions` file in the root of your project, describing the versions
of OTP, Elixir, and Node that you will be building with:

```
erlang 21.3
elixir 1.8.2
nodejs 10.16.0
```

## Configure for CodeDeploy

- Add `appspec.yml`

## Configure for CodeBuild

- Add `buildspec.yml`

## Add database migrations

Add a [Distillery custom command to run database migrations](https://www.cogini.com/blog/running-ecto-migrations-in-production-releases-with-distillery-custom-commands/)

- Add `lib/mix_deploy_example/tasks/migrate.ex`
- Add `rel/commands/migrate.sh`.

In `rel/config.exs`:

```elixir
environment :prod do
  set commands: [
    migrate: "rel/commands/migrate.sh"
  ]
end
```

## Add Ansible scripts

## Add Docker file

```shell
build -f docker/Dockerfile.build .
```
