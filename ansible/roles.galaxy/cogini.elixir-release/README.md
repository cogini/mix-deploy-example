# elixir-release

This Ansible role deploys Elixir/Phoenix releases.

It uses Erlang "releases" with systemd for process supervision, as described in
"[Deploying Elixir apps with Ansible](https://www.cogini.com/blog/deploying-elixir-apps-with-ansible/)" and.
"[Best practices for deploying Elixir apps](https://www.cogini.com/blog/best-practices-for-deploying-elixir-apps/)".

## Directory structure

It uses a structure like Capistrano to manage the release files. The base
directory is named for the app, e.g. `/srv/foo`, with a `releases` directory
under it.  When the role deploys a release, it creates a directory named by a
timestamp, e.g. `/srv/foo/releases/20190603T072116`.  It unpacks the files
under it, makes a symlink from `/srv/foo/current` to the new directory.

## Restarting

After deploying the release, it restarts the app to make it live.

By default, when `elixir_release_restart_method: systemctl`, it does this by running:

```shell
sudo /bin/systemctl restart foo
```

The deploy user account needs sufficient permissions to restart the app.
Instead of giving the deploy account full sudo permissions, a user-specific
sudo config file specifies what commands it can run, e.g. `/etc/sudoers.d/deploy-foo`:

    deploy ALL=(ALL) NOPASSWD: /bin/systemctl start foo, /bin/systemctl stop foo, /bin/systemctl restart foo

Better is if we didn't require sudo permissions at all. One option is to take
advantage of systemd to restart the app.

Set `elixir_release_restart_method: systemd_flag`, the deploy process touches a
`/srv/foo/flags/restart.flag` file on the disk after deploying the code.
Systemd notices and restarts it with the new code.

See [mix-deploy-example](https://github.com/cogini/mix-deploy-example) for a full example.

# Example Playbook

A minimal playbook, for an app called `foo`:

    - hosts: '*'
      become: true
      vars:
        elixir_release_app_name: foo
      roles:
        - cogini.elixir-release

Put this in `ansible/playbooks/deploy-app.yml`.

First, set up the target machine, e.g. installing packages and creating directories.
Run this from your dev machine, specifying a user with sudo permissions:

    ansible-playbook -u $USER -v -l web-servers playbooks/deploy-app.yml --skip-tags deploy -D

Next, deploy the code. Run this from the build server, from a user account with
ssh access to the deploy account on the target machine:

    ansible-playbook -u deploy -v -l web-servers playbooks/deploy-app.yml --tags deploy --extra-vars ansible_become=false -D

A more heaviliy customized playbook:

    - hosts: '*'
      become: true
      vars:
        elixir_release_app_name: foo
        elixir_release_app_user: bar
        elixir_release_deploy_user: deploy
        elixir_release_mix_env: public
        elixir_release_base_dir: /opt/bar
        elixir_release_app_dirs:
          - configuration
          - runtime
          - logs
          - tmp
          - state
          - cache
        elixir_release_tmp_directory_base: /var/tmp/bar
        elixir_release_state_directory_base: /var/bar
        elixir_release_http_listen_port: 8080
        elixir_release_cache_directory_mode: 0700
        elixir_release_configuration_directory_mode: 0755
        elixir_release_logs_directory_mode: 0755
        elixir_release_state_directory_mode: 0755
        elixir_release_tmp_directory_mode: 0755
        elixir_release_sudoers_file: "{{ elixir_release_app_user }}-{{ elixir_release_service_name }}"
        # Location of source app, assuming that the deploy scripts are in a separate repo in a parallel dir
        elixir_release_src_dir: "{{ playbook_dir }}/../../../foo"
      roles:
        - cogini.elixir-release

# Role Variables

Location of app to get release files. By default, it assumes that you have an `ansible` directory
in your app source

    elixir_release_app_dir: "{{ role_path }}/../../.."

Erlang name of the application, used to by Distillery to name directories
and scripts.

    elixir_release_app_name: my_app

External name of the app, used to name the systemd service and directories.
By default, it converts underscores to dashes:

    elixir_release_service_name: "{{ elixir_release_app_name | replace('_', '-') }}"

Elixir application name. By default, it is the CamelCase version of the app name:

    elixir_release_app_module: "{{ elixir_release_service_name.title().replace('_', '') }}"

Version of the app to release. If not specified, will read it from the `start_erl.data`
file in the release directory.

    elixir_release_version: "0.1.0"

For security, we use separate accounts to deploy the app and to run it.  The
deploy account owns the code and config files, and has rights to restart the
app. We normally use a separate account called `deploy`.  The app runs under a
separate account with the minimum permissions it needs.  We normally create a
name matching the app, e.g. `foo` or use a generic name like `app`.

The release files are owned by `deploy:app` with mode 0644 so that the app can read them.

OS account that deploys and owns the release files:

    elixir_release_deploy_user: deploy

OS group that deploys and owns the release files:

    elixir_release_deploy_group: "{{ elixir_release_deploy_user }}"

OS account that the app runs under:

    elixir_release_app_user: "{{ elixir_release_service_name }}"

OS group that the app runs under:

    elixir_release_app_group: "{{ elixir_release_app_user }}"

App release environment, i.e. the setting of `MIX_ENV`, used to find the release file under the `_build` dir:

    elixir_release_mix_env: prod

Directory prefix for release files:

    elixir_release_base_dir: /srv

Base directory for deploy files:

    elixir_release_deploy_dir: "{{ elixir_release_base_dir }}/{{ elixir_release_service_name }}"

Directories under deploy dir.

Where release tarballs are unpacked:

    elixir_release_releases_dir: "{{ elixir_release_deploy_dir }}/releases"

Currently running release (symlink):

    elixir_release_current_dir: "{{ elixir_release_deploy_dir }}/current"

Location of deploy scripts:

    elixir_release_scripts_dir: "{{ elixir_release_deploy_dir }}/bin"

Flag file dir, used to signal restart:

    elixir_release_flags_dir: "{{ elixir_release_deploy_dir }}/flags"

Directories where the app keeps its files, following [systemd](https://www.freedesktop.org/software/systemd/man/systemd.exec.html).

    elixir_release_app_dirs:
      - configuration
      - runtime
      # - logs
      # - tmp
      # - state
      # - cache

Whether to use [conform](https://github.com/bitwalker/conform):

    elixir_release_conform: false
    elixir_release_conform_conf_path: "{{ elixir_release_configuration_dir }}/config.conform"

How we should restart the app:

    elixir_release_restart_method: systemctl
    # elixir_release_restart_method: systemd_flag
    # elixir_release_restart_method: touch

Options are:

* `systemctl`, which runs `systemctl restart foo`
* `systemd_flag`, which touches the file `{{ elixir_release_shutdown_flags_dir }}/restart.flag`
* `touch`, which touches the file `{{ elixir_release_shutdown_flags_dir }}/restart.flag`.
  Directory permissions are 0770, allowing the managed process to restart itself.

Which users are allowed to restart the app using `sudo /bin/systemctl restart` when method == `systemctl`.

  elixir_release_restart_users:
   - "{{ elixir_release_deploy_user }}"

Set to `[]` and nobody can restart, or add additional names, e.g. `- "{{ elixir_release_app_user }}"`.

## systemd and scripts

By default this role assumes that you are using
[mix_systemd](https://hex.pm/packages/mix_systemd) to generate the systemd unit
file and [mix_deploy](https://hex.pm/packages/mix_deploy) to generate lifecycle
scripts.

`elixir_release_systemd_source` controls the source of the systemd unit file.

    elixir_release_systemd_source: mix_systemd

With the default value of `mix_systemd`, the role copies the systemd unit files from the
`_build/{{ elixir_release_mix_env }}/systemd` directory. Set it to `self`, nd
this role will generate a systemd unit file from a template.

`elixir_release_scripts_source` controls the source of the scripts.

    elixir_release_scripts_source: bin

With the default value of `bin`, the role copies scripts from the project's `bin` directory
to `/srv/foo/bin` on the target system. Set it to `mix_deploy` if you have set
`output_dir_per_env: true` in the `mix_deploy` config, storing the generated scripts under `_build`.

The following variables are used when generating the systemd unit file:

Port that the app listens for HTTP connections on:

    elixir_release_http_listen_port: 4000

Port that the app listens for HTTPS connections on:

    elixir_release_https_listen_port: 4001

Open file limit:

    elixir_release_limit_nofile: 65536

Seconds to wait between restarts:

    elixir_release_systemd_restart_sec: 5

`LANG` environment var:

    elixir_release_lang: "en_US.UTF-8"

umask:

    elixir_release_umask: "0027"

Target systemd version, used to enable more advanced features:

    elixir_release_systemd_version: 219

Systemd service type:

    elixir_release_service_type: simple

Start command:

    elixir_release_start_command: foreground

PID file when using forking service type:

    elixir_release_pid_file: "{{ elixir_release_runtime_dir }}/{{ elixir_release_app_name}}.pid"

List of ExecStartPre scripts in systemd unit file:

    elixir_release_exec_start_pre: []

List of environment vars to set in systemd unit file:

    elixir_release_env_vars: []

# Dependencies

None

# Requirements

None

# License

MIT

# Author Information

Jake Morrison <jake@cogini.com>
