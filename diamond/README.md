# diamond
> This image is part of the dockerized tools meant to be used with image [`dev-base`](../dev-base/README.md) in GitHub Codespace or VSCode devcontainer environments.
> For answers to general why? and how? consult the [README of dev-base](../dev-base/README.md).

This image ships a containerized version of `Lattice Diamond` in various versions and supported devices.

By only keeping some device support files and removing several of the below listed tools or components from the default install, the image size has been reduced to a somewhat comfortable 3.5 GB. Removed where:
 - example designs
 - IBIS models
 - QuestaSim (use the sister image [`questasim`](../questasim/README.md))
 - LatticeMico System Development Tools

## Tags
| Tag | Diamond Version | Device Support | Note |
|---|---|---|---|
| `3.14-ecp5` | 3.14.0.75.2 | ECP5 | - |

Feel free to open an issue to request other versions or additional device support.

## Usage
> Please note that using Diamond implies acceptance of Lattice's EULA for the appropriate version(s) you use.

The image has `diamondc` set as `ENTRYPOINT`. Simply running a container without arguments will invoke `diamondc` without any arguments and will drop you into an interactive Tcl shell:
```
$ docker run ghcr.io/nikleberg/diamond:3.14-ecp5
> --- Lattice Diamond  Version 3.14.0.75.2
  --- Copyright (C) 1992-2024 Lattice Semiconductor Corporation.
  --- All Rights Reserved.
  --- Lattice Diamond install path: /opt/diamond
  --- Start Time: Tue Oct 27 21:47:18 2026
  %
```

For an actual usage you want to supply additional arguments to the `docker run` command. For example to run a tcl script you could run:
```
$ docker run ghcr.io/nikleberg/diamond:3.14-ecp5 <script>.tcl
```

Diamond knows many CLI programs, `diamondc` is just the common entrypoint to run tcl scripts with (and which I use the most). You can simply set `--entrypoint <xxx>` to the desired program when starting the container with `docker run`. For example you could drop yourself into `bash` and explore the image or, after some tinkering with [x11 forwarding](../dev-base/README.md#bonus-gui), launch `diamond` as a GUI application.

### License File
Lattice Diamond requires a valid license that can be obtained from [Lattice Licensing Portal](https://latticesemi.com/license). At least in the rare case when that website actually works. For ease of use a valid license is already included. But it is bound to a specific NIC id i.e. MAC address `00:ab:ab:ab:ab:ab`. Using this bundled license implies acceptance of Lattice's EULA for the appropriate version(s) you use and agreement to Lattice's [Legal Notice](https://www.latticesemi.com/en/About/LegalNotices).

Alternatively you may [aquire your own license file for `Diamond-Base-NL`](https://latticesemi.com/license). To use it you have to extend the `docker run` arguments:
 - mount the license file into the container with `--volume /path/on/host/license:/path/on/container/license`
 - set the environment variable `LM_LICENSE_FILE` such that e.g. `diamondc` finds it with: `--env=LM_LICENSE_FILE=/path/on/container/license`

If you want to use the included license you have to set the MAC address for the docker container differently depending on where you use it:

#### Local
To use the container locally just add the `mac-address` option to the docker run command:
```shell
docker run --mac-address=00:ab:ab:ab:ab:ab ghcr.io/nikleberg/diamond:3.14-ecp5
```

#### Devcontainer
For a devcontainer used with e.g. VSCode add the following config to `devcontainer.json`:
```json
{
  "image": "ghcr.io/nikleberg/diamond:3.14-ecp5",
  "runArgs": [
    "--mac-address=00:ab:ab:ab:ab:ab"
  ]
}
```

#### GitHub Action
For using this container as image in the CI environment of GitHub Actions add the `mac-address` option to `jobs.<job_id>.container.options` in the yaml:
```yaml
jobs:
  example:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/nikleberg/diamond:3.14-ecp5
      options: --mac-address=00:ab:ab:ab:ab:ab
    steps:
    - ...
```

#### GitLab CI
The GitLab CI yaml syntax i.e. its docker runner has [currently](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2344) no capability to set additional docker run options. But if the runner has the `CAP_NET` capability then one can change the MAC address within the container itself. For example with `ifconfig`:
```yaml
example:
  image: ghcr.io/nikleberg/diamond:3.14-ecp5
  before_script: |
    apt-get -q -y update && apt-get -q -y install net-tools
    ifconfig eth0 down
    ifconfig eth0 hw ether "00:ab:ab:ab:ab:ab"
    ifconfig eth0 up
  script: ...
```

## License
[MIT](../LICENSE) © [NikLeberg](https://github.com/NikLeberg).
