# quartus
> These images are part of the dockerized tools meant to be used with image [`dev-base`](../dev-base/README.md) in GitHub Codespace or VsCode devcontainer environments.
> For answers to general why? and how? consult the [README of dev-base](../dev-base/README.md).

These images contain a continerized version of `Quartus Prime <Version> Lite Edition` in various versions and supported devices.

Quartus is a part of [Intel Quartus Prime Lite](https://www.intel.de/content/www/de/de/products/details/fpga/development-tools/quartus-prime/resource.html). To reduce the size of the images the tools of Quartus have been split up into two image groups:
 - `quartus`, tools to synthesize HDL for Intel/Altera FPGAs (these one here)
 - [`questasim`](../questasim/README.md), tools to simulate HDL

## Tags
| Tag | Quartus Version | Device Support | Note |
|---|---|---|---|
| `18.1-cycloneiv` | 18.1.0 | Cyclone IV | Quartus GUI non functional with WSLg (only window borders), use [`VcXsrv`](https://github.com/marchaesen/vcxsrv). |
| `22.1-cycloneiv` | 22.1.2 | Cyclone IV | - |
| `23.1-cycloneiv` | 23.1.1 | Cyclone IV | - |
| `24.1-cycloneiv` | 24.1.0 | Cyclone IV | Very slow. ~2x slowdown compared to older versions. Regardless if GUI or scripts are used. |

Feel free to open an issue to request other versions or additional device support.

## Usage
> Please note that using Quartus implies acceptance of [Intel/Altera FPGA's EULA](http://fpgasoftware.intel.com/eula/) for the appropriate version(s) you use.

The image has `quartus_sh` set as `ENTRYPOINT`. Simply running a container without arguments will invoke `quartus_sh` with the default `CMD` argument `-version` and print the Quartus version:
```
$ docker run ghcr.io/nikleberg/quartus:24.1-cycloneiv
> Quartus Prime Shell
  Version 24.1std.0 Build 1077 03/04/2025 SC Lite Edition
  Copyright (C) 2025  Altera Corporation. All rights reserved.
```

For an actual usage you want to override the `CMD` by giving additional arguments to the `docker run` command. For example to run a tcl script you could run:
```
$ docker run ghcr.io/nikleberg/quartus:24.1-cycloneiv -t <script>.tcl
> Info: *******************************************************************
  Info: Running Quartus Prime Shell
      Info: Version 24.1std.0 Build 1077 03/04/2025 SC Lite Edition
      Info: Copyright (C) 2025  Altera Corporation. All rights reserved.
      Info: Your use of Altera Corporation's design tools, logic functions
      Info: and other software and tools, and any partner logic
  ...
```

Quartus knows many CLI programs, `quartus_sh` is just the common entrypoint to run tcl scripts with (and which I use the most). An incomplete selection of additional CLIs:
 - `quartus_asm` - Assembler
 - `quartus_fit` - Fitter
 - `quartus_map` - Analysis & Synthesis
 - `quartus_pgm` - Programmer
 - `quartus_sta` - Timing Analyzer
 - and many more...

To use them you can simply set `--entrypoint quartus_<xxx>` to the desired program when starting the container with `docker run`.

### Additional `docker run` Arguments
For improved functionality and ease-of-use you may want to add some of these arguments to the `docker run` command stated above:
 - `--hostname quartus`: Make the shells in the container display a human readable machine name.
 - `--interactive --tty`: This makes the started container interactive and not run in the background.
 - `--rm`: Removes the container after the command is finished, your disk will thank you.
 - `--workdir $(pwd)`: Sets the working directory inside the container to the current shell path.
 - `--volumes-from $(cat /proc/self/cgroup | head -n 1 | cut -d '/' -f3)`: If the container is started in the DooD environment provided by [`dev-base`](../dev-base/README.md) in Devcontainers, then this forwards the required volumes from the base container to the _quartus_ tool container. This is required to access any path in `/workspaces`. 
 - `--volume=/dev:/dev --privileged`: Allows USB/JTAG access to FPGAs for programming.
 - `--env=DISPLAY=:0 --volume=/tmp/.X11-unix/:/tmp/.X11-unix/`: Forwards your X11 configuration (this works in WSLg!). With this, starting the GUI with the command `quartus` opens the GUI on your docker host.

### Alias
To release your fingers from the pain of entering these commands and arguments all the time, use an alias function.

Put the below functions in a script and `source <script>` it in whatever shell you need the `quartus_*` commands. After this, having Quartus installed locally is almost identical as having it isolated in this self-contained docker image.

```bash
function get_common_args () {
    common_vols="--volumes-from $(cat /proc/self/cgroup | head -n 1 | cut -d '/' -f3)"
    common_disp="--env=DISPLAY=:0 --volume=/tmp/.X11-unix/:/tmp/.X11-unix/"
    common_misc="--workdir $(pwd) --interactive --tty --rm"
    common_args="$common_vols $common_disp $common_misc"
    echo $common_args
}
export -f get_common_args

function command_not_found_handle () {
    if [[ $1 =~ ^quartus.*$ ]]; then
        quartus_args="--hostname quartus --entrypoint $1 $(get_common_args)"
        shift
        docker run $quartus_args ghcr.io/nikleberg/quartus:24.1-cycloneiv $*
        return
    fi
    return 127 # not a quartus command
}
export -f command_not_found_handle
function quartus_bash () {
    quartus_args="--hostname quartus --entrypoint bash $(get_common_args)"
    docker run $quartus_args ghcr.io/nikleberg/quartus:24.1-cycloneiv $*
}
export -f quartus_bash
```

Note:
 - The `command_not_found_handle` is not a classical function-like alias but a general handler that gets called by BASH (versions >= 4) to look for unknown commands. With a regex compare we test if the unknown commands starts with `quartus` and will redirect all such commands to a freshly started docker container.
 - The additional `quartus_bash` alias is for debugging. It overwrites the entrypoint in the image and lets you more easily debug problems by dropping you into a bash shell inside the container.

## License
[MIT](../LICENSE) © [NikLeberg](https://github.com/NikLeberg).
