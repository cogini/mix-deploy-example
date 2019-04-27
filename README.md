# mix_deploy_example

This is a working example Elixir app which shows how to deploy using
[mix_deploy](https://github.com/cogini/mix_deploy).

`mix_deploy` generates scripts which are used to deploy your app using systemd
on a server. It includes scripts to set up the initial system, deploy
code and handle configuration during startup.

It supports deployment to a local system and via [AWS CodeDeploy](https://aws.amazon.com/codedeploy/).

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

Run this once to set up the system, creating users, directories, etc:

```shell
sudo bin/deploy-init-local
```

## Configure

Copy the sample production config:

```shell
cp config/prod.secret.exs.sample config/prod.secret.exs
```

The `secret_key_base` value protects Phoenix sessions. Generate your own value with:

```shell
mix phx.gen.secret 64
```

Configure production database settings and `secret_key_base` in `config/prod.secret.exs`.

Copy the runtime config to `/etc`.

```shell
cp config/prod.secret.exs /etc/mix-deploy-example/config.exs
chown deploy:app /etc/mix-deploy-example/config.exs
chmod 644 /etc/mix-deploy-example/config.exs
```end

## Deploy

Deploy the release to the local machine:

```shell
# Extract release to target directory, creating current symlink
bin/deploy-release

# Restart the systemd unit
sudo bin/deploy-restart
```

Connect to your server:

```shell
curl -http://localhost:4000/
```

You can roll back the release with the following:

```shell
bin/deploy-rollback
sudo bin/deploy-restart
```

# Changes

Following are the steps used to set up this repo. You can do the same to add
it to your own project. This repo is built as a series of git commits, so you
can see how it works step by step.

## Generate Phoenix project

```shell
mix phx.new mix_deploy_example
mix deps.get
cd assets && npm install && node node_modules/webpack/bin/webpack.js --mode development
```

* Add `mix.lock` to git
* Add `package-lock.json` to git

## Set up distillery

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

Increase network ports in `rel/vm.args`

Add runtime config provider to `rel/config.exs`:

```elixir
environment :prod do
  set config_providers: [
    {Mix.Releases.Config.Providers.Elixir, ["/etc/mix-deploy-example/config.exs"]}
  ]
end
```

Add `config/prod.secret.exs.sample` file.

## Add mix_deploy and mix_systemd

Add libraries to deps:

```elixir
{:mix_systemd, github: "cogini/mix_systemd", override: true},
{:mix_deploy, github: "cogini/mix_deploy"},
end
```
TODO: should use hex versions

Add `rel/templates` and `bin/deploy-*` to `.gitignore`.

## Add build scripts

* `build`
* `build-install-asdf`
* `build-install-asdf-deps-centos`
* `build-install-asdf-deps-ubuntu`
* `build-install-asdf-init`
* `build-install-asdf-macos`
* `build-install-deps-centos`
* `build-install-deps-ubuntu`

## Add script to validate service is working

`bin/validate-service`

## Configure system

Update `config/prod.exs` to run from release:

* Start Phoenix endpoints
* Don't use use prod.secret.exs

## Configure mix_deploy and mix_systemd

Configure `mix_deploy` and `mix_systemd`. If you are deploying on the
local system, then it will work without any configuration.

By default, it runs the app under an OS user matching the application,
e.g. `mix-deploy-example`, which is a bit long, so
change `config/prod.exs` to use `app` for the OS user:

```elixir
config :mix_deploy,
  app_user: "app",
  app_group: "app"

config :mix_systemd,
  app_user: "app",
  app_group: "app"
```

## Configure ASDF

* Add `.tool-versions`

## Configure for CodeDeploy

* Add `appspec.yml`

## Configure for CodeBuild

* Add `buildspec.yml`
