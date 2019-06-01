# Setting up servers using Ansible

This document tells how to set up a server to run a Phoenix app using
[Ansible](https://www.ansible.com/).

# Install Ansible

On your local dev machine, install Ansible:

```shell
pip install ansible
```

# Configure SSH

Ansible uses ssh to talk to the server. On your local dev machine, add an ssh
host alias in the `~/.ssh/config` file so you can reference the server using
its name.

    Host web-server
        HostName 123.45.67.89

You can use any name you like, but it needs to match `ansible/inventory/hosts`.

## Configure settings for the app

For security, we use separate accounts to deploy the app and to run it.

The deploy account owns the code and config files, and has rights
to restart the app. We normally use a separate account called `deploy`.

The app runs under a separate account with the minimum permissions it needs.
We normally create a name matching the app, e.g. `foo` or use a generic name
like `app`.

Under the `ansible` dir, edit `inventory/group_vars/all/elixir-release.yml` to
set Ansible variables to match the Elixir app you are deploying.

```yaml
# External name of the app, used to name directories and the systemd unit
elixir_release_name: mix-deploy-example

# Internal Erlang name of the app, used by Distillery to name directories
elixir_release_name_code: mix_deploy_example

# Internal Elixir name of the app
elixir_release_name_module: MixDeployExample

# Location to deploy to
elixir_release_deploy_dir: "/srv/{{ elixir_release_name }}"

# OS user for deploy
elixir_release_deploy_user: deploy
elixir_release_deploy_group: "{{ elixir_release_deploy_user }}"

# OS user the app runs under
elixir_release_app_user: app
elixir_release_app_group: "{{ elixir_release_app_user }}"

# Port that Phoenix listens on
elixir_release_http_listen_port: 4000

# Configure firewall to open the port
iptables_http_app_port: "{{ elixir_release_http_listen_port }}"

# Config dir under base (combined systemd)
elixir_release_conf_dir: "/etc/{{ elixir_release_name }}"

# Directory for runtime scripts
elixir_release_scripts_dir: "{{ elixir_release_deploy_dir }}/bin"
```

## Configure OS accounts

Define users and associated ssh keys in `inventory/group_vars/all/users.yml`.

This defines a user `jake`, getting the ssh keys from their GitHub profile.

```yaml
users_users:
  - user: jake
    name: "Jake Morrison"
    github: reachfh
```

Add the key for the `jake` user to the deploy account, allowing it to log in
via ssh:

```yaml
users_deploy_users:
 - jake
```

If you want to create a separate account on the server for the user, add
them to the `users_global_admin_users` array:

```yaml
users_global_admin_users:
 - jake
```

# Set up web server

Run Ansible to do the initial setup on the server, including creating
users and setting up iptables firewall.

The `-u` flag specifies the user for the initial setup. For a dedicated server,
that might be root. In a cloud environment, it might be a default user like
`centos` or `ubuntu` with your keypair installed. The user needs to be root or
a user with sudo permissions. See `playbooks/manage-users.yml` for other connection
options, e.g. specifying a password manually.

```shell
ansible-playbook -u root -v -l web-servers playbooks/setup-web.yml -D
```

At this point, you can log in with the user you specified (e.g. `jake`) and
complete setup using the `mix_deploy` scripts.

Alternatively, you can set up the app directories using Ansible:

```shell
ansible-playbook -u $USER -v -l web-servers playbooks/deploy-app.yml --skip-tags deploy -D
```

# Deploy config to web server

Instead of baking secrets like db passwords into the release file, we create a
config file and copy it to the app config dir under `/etc/`.

For dedicated servers, we use Ansible to generate a TOML-format config file from
a template and push it to the web server.

This is most useful for fleets of dediated servers.

```
ansible-playbook -u $USER -v -l web-servers playbooks/config-web.yml -D
```

See `templates/app.config.toml.j2`.

# Deploy app to web server

Build the release on a build server, then push it to prod servers and restart.
This is most useful for fleets of dediated servers.

```shell
ansible-playbook -u deploy -v -l web-servers playbooks/deploy-app.yml --tags deploy --extra-vars ansible_become=false -D
```

You can install Ansible on the build machine with:

```shell
ansible-playbook -u $USER -v -l web-servers playbooks/setup-ansible.yml -D
```

# Set up local database

The following playbook sets up a Postgres database:

```shell
ansible-playbook -u $USER -v -l db-servers playbooks/setup-db.yml -D
```

Configuration is in `inventory/group_vars/db-servers/postgresql.yml`.

## Set up build server

This playbook sets up the build server, installing ASDF:

```
ansible-playbook -u root -v -l build-servers playbooks/setup-build.yml -D
```

See `inventory/group_vars/build-servers/vars.yml`, particularly `app_repo` for
the URL of the git repo.
