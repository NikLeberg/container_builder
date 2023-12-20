# questasim
> This image is part of the dockerized tools meant to be used with image [`dev-base`](../dev-base/README.md) in GitHub Codespace or VsCode devcontainer environments.
> For answers to general why? and how? consult the [README of dev-base](../dev-base/README.md).

This container contains a continerized version of `Questa  Intel Starter FPGA Edition-64 vsim 2021.2 Simulator 2021.04 Apr 14 2021`.

Questa is a part of [Intel Quartus Prime Lite](https://www.intel.de/content/www/de/de/products/details/fpga/development-tools/quartus-prime/resource.html). To reduce the size of the image the tools of Quartus have been split up into two images:
 - [`quartus`](../quartus/README.md), tools to synthesize HDL for Intel FPGAs
 - `questasim`, tools to simulate HDL (this one here)

But even with this split, the image is still very big (~4.6 GB). The large _installation step_ image layer is split up into multiple smaller layers to help speed up image pull / download and make it more robust.

## Usage
The image has `vsim` set as `ENTRYPOINT`. Simply running a container without arguments will invoke `vsim` with the default `CMD` argument `-version` and print the Questa version:
```shell
$ docker run ghcr.io/nikleberg/questasim
> Questa  Intel Starter FPGA Edition-64 vsim 2021.2 Simulator 2021.04 Apr 14 2021
```

For an actual usage you want to override the `CMD` by giving additional arguments to the `docker run` command. For example to run a simulation tcl script you could run:
```bash
$ docker run ghcr.io/nikleberg/questasim -c -do <script>.tcl
> # Questa Intel Starter FPGA Edition-64 vcom 2021.2 Compiler 2021.04 Apr 14 2021
  # Start time: 22:15:25 on Oct 12,2023
  # vcom top.vhdl 
  # -- Loading package STANDARD
  # -- Loading package TEXTIO
  # -- Loading package std_logic_1164
  ...
```

### Additional `docker run` Arguments
For improved functionality and ease-of-use you may want to add some of these arguments to the `docker run` command stated above:
 - `--hostname vsim`: Make the shells in the container display a human readable machine name.
 - `--interactive --tty`: This makes the started container interactive and not run in the background.
 - `--rm`: Removes the container after the command is finished, your disk will thank you.
 - `--workdir $(pwd)`: Sets the working directory inside the container to the current shell path.
 - `--volumes-from $(cat /proc/self/cgroup | head -n 1 | cut -d '/' -f3)`: If the container is started in the DooD environment provided by [`dev-base`](../dev-base/README.md) in Devcontainers, then this forwards the required volumes from the base container to the _questasim_ tool container. This is required to access any path in `/workspaces`. 
 - `--env=DISPLAY=:0 --volume=/tmp/.X11-unix/:/tmp/.X11-unix/`: Forwards your X11 configuration (this works in WSLg!). With this, starting `vsim` without the `-c` flag (CLI mode) starts the GUI of `vsim` (or actually _QuestaSim_) on your docker host.
 - `--mac-address=00:ab:ab:ab:ab:ab`: Sets a specific MAC address for the docker NIC. This is for licencing purposes, please read below [_License File_](#license-file).

### Alias
To release your fingers from the pain of entering these commands and arguments all the time, use an alias function.

Put the below functions in a script and `source <script>` it in whatever shell you need the `vsim` command. After this, having `vsim` installed locally is almost identical as having it isolated in this self-contained docker image.

```bash
function get_common_args () {
    common_vols="--volumes-from $(cat /proc/self/cgroup | head -n 1 | cut -d '/' -f3)"
    common_disp="--env=DISPLAY=:0 --volume=/tmp/.X11-unix/:/tmp/.X11-unix/"
    common_misc="--workdir $(pwd) --interactive --tty --rm"
    common_args="$common_vols $common_disp $common_misc"
    echo $common_args
}
export -f get_common_args

function vsim () {
    vsim_args="--hostname vsim --mac-address=00:ab:ab:ab:ab:ab $(get_common_args)"
    docker run $vsim_args ghcr.io/nikleberg/questasim $*
}
export -f vsim
function vsim_bash () {
    vsim_args="--hostname vsim --mac-address=00:ab:ab:ab:ab:ab --entrypoint bash $(get_common_args)"
    docker run $vsim_args ghcr.io/nikleberg/questasim $*
}
export -f vsim_bash
```

Note the additional `vsim_bash` alias. It overwrites the entrypoint in the image and lets you more easily debug problems by dropping you into a bash shell inside the container.

### License File
Since v21.1 of Quartus, ModelSim was replaced by QuestaSim. It requires a valid license that can be obtained from [intel](https://licensing.intel.com/). For ease of use a valid license is already included. But it is bound to a specific NIC id i.e. MAC address `00:ab:ab:ab:ab:ab`.

If you want to use this license you have to set the MAC address for the docker contrainer with the `--mac-address=00:ab:ab:ab:ab:ab` argument when starting the container with `docker run`.

Alternatively you may [aquire your own license file](https://licensing.intel.com/). To use it you have to:
 - mount the license file into the container with `--volume /path/on/host/license:/path/on/container/license`
 - set the environment variable `LM_LICENSE_FILE` such that `vsim` finds it with: `--env=LM_LICENSE_FILE=/path/on/container/license`

## License
[MIT](../LICENSE) © [NikLeberg](https://github.com/NikLeberg).
