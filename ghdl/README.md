# ghdl
> This image is part of the dockerized tools meant to be used with image [`dev-base`](../dev-base/README.md) in GitHub Codespace or VsCode devcontainer environments.
> For answers to general why? and how? consult the [README of dev-base](../dev-base/README.md).

This container contains a continerized version of [`ghdl`](https://github.com/ghdl/ghdl) as standalone executable.
Additionally `make` for tool automation is installed as well.

## Usage
The image has `ghdl` set as `ENTRYPOINT`. Simply running a container without arguments will invoke `ghdl` with the default `CMD` argument `--version` and print the ghdl version:
```
$ docker run ghcr.io/nikleberg/ghdl
> GHDL 4.0.0-dev (3.0.0.r760.gaf5371ab5) [Dunoon edition]
   Compiled with GNAT Version: 10.5.0
   static elaboration, mcode code generator
  Written by Tristan Gingold.

  Copyright (C) 2003 - 2023 Tristan Gingold.
  GHDL is free software, covered by the GNU General Public License.  There is NO
  warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

For an actual usage you want to override the `CMD` by giving additional arguments to the `docker run` command. For example to actually analize a VHDL source file you could run:
```
$ docker run ghcr.io/nikleberg/ghdl -a top.vhdl
> ...
```

To use `make` you may use the `--entrypoint <binary>` argument when starting the container with `docker run`.

### Additional `docker run` Arguments
For improved functionality and ease-of-use you may want to add some of these arguments to the `docker run` command stated above:
 - `--hostname ghdl`: Make the shells in the container display a human readable machine name.
 - `--interactive --tty`: This makes the started container interactive and not run in the background.
 - `--rm`: Removes the container after the command is finished, your disk will thank you.
 - `--workdir $(pwd)`: Sets the working directory inside the container to the current shell path.
 - `--volumes-from $(cat /proc/self/cgroup | head -n 1 | cut -d '/' -f3)`: If the container is started in the DooD environment provided by [`dev-base`](../dev-base/README.md) in Devcontainers, then this forwards the required volumes from the base container to the _ghdl_ tool container. This is required to access any path in `/workspaces`.

### Alias
To release your fingers from the pain of entering these commands and arguments all the time, use an alias function.

Put the below functions in a script and `source <script>` it in whatever shell you need the gcc toolchain. After this, having ghdl installed locally is almost identical as having it isolated in this self-contained docker image.

```bash
function get_common_args () {
    common_vols="--volumes-from $(cat /proc/self/cgroup | head -n 1 | cut -d '/' -f3)"
    common_misc="--workdir $(pwd) --interactive --tty --rm"
    common_args="$common_vols $common_misc"
    echo $common_args
}
export -f get_common_args

function make () {
    ghdl_args="--hostname ghdl --entrypoint make $(get_common_args)"
    docker run $ghdl_args ghcr.io/nikleberg/ghdl $*
}
export -f make
function ghdl () {
    ghdl_args="--hostname ghdl --entrypoint ghdl $(get_common_args)"
    docker run $ghdl_args ghcr.io/nikleberg/ghdl $*
}
export -f ghdl
function gcc () {
    ghdl_args="--hostname ghdl --entrypoint gcc $(get_common_args)"
    docker run $ghdl_args ghcr.io/nikleberg/ghdl $*
}
function ghdl_bash () {
    ghdl_args="--hostname ghdl --entrypoint bash $(get_common_args)"
    docker run $ghdl_args ghcr.io/nikleberg/ghdl $*
}
export -f ghdl_bash
```

Note the additional `ghdl_bash` alias is for debugging. It overwrites the entrypoint in the image and lets you more easily debug problems by dropping you into a bash shell inside the container.

## License
[MIT](../LICENSE) © [NikLeberg](https://github.com/NikLeberg).
