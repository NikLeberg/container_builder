# riscv-gcc
> This image is part of the dockerized tools meant to be used with image [`dev-base`](../dev-base/README.md) in GitHub Codespace or VsCode devcontainer environments.
> For answers to general why? and how? consult the [README of dev-base](../dev-base/README.md).

This container contains a continerized version of the RISC-V GCC cross-compiler toolchain in various versions, see [below](#tags).
Additionally `make`, `openocd` and a host version of a `gcc` toolchain are installed as well.

## Tags
| Tag | Upstream `riscv-gnu-toolchain` tag | GCC version | ARCH | ABI | Note |
|---|---|---|---|---|---|
| `15.1-rv32imac` | 2025.11.04 | 15.1.0 | rv32imac | ilp32 | - |
| `15.1-rv32i`    | 2025.11.04 | 15.1.0 | rv32i    | ilp32 | - |
| `13.2-rv32imac` | 2024.04.12 | 13.2.0 | rv32imac | ilp32 | - |
| `13.2-rv32i`    | 2024.04.12 | 13.2.0 | rv32i    | ilp32 | - |
| `12.2-rv32imac` | 2023.10.06 | 12.2.0 | rv32imac | ilp32 | - |

Feel free to open an issue to request other versions.

## Usage
The image has `riscv32-unknown-elf-gcc` set as `ENTRYPOINT`. Simply running a container without arguments will invoke `riscv32-unknown-elf-gcc` with the default `CMD` argument `--version` and print the GCC version:
```
$ docker run ghcr.io/nikleberg/riscv-gcc:13.2-rv32imac
> riscv32-unknown-elf-gcc () 13.2.0
  Copyright (C) 2023 Free Software Foundation, Inc.
  This is free software; see the source for copying conditions.  There is NO
  warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

For an actual usage you want to override the `CMD` by giving additional arguments to the `docker run` command. For example to actually cross-compile code you could run:
```
$ docker run ghcr.io/nikleberg/riscv-gcc:13.2-rv32imac main.c -I include/
> ...
```

To use `make` or the host `gcc` toolchain you may use the `--entrypoint <binary>` argument when starting the container with `docker run`.

### Additional `docker run` Arguments
For improved functionality and ease-of-use you may want to add some of these arguments to the `docker run` command stated above:
 - `--hostname riscv-gcc`: Make the shells in the container display a human readable machine name.
 - `--interactive --tty`: This makes the started container interactive and not run in the background.
 - `--rm`: Removes the container after the command is finished, your disk will thank you.
 - `--workdir $(pwd)`: Sets the working directory inside the container to the current shell path.
 - `--volumes-from $(cat /proc/self/cgroup | head -n 1 | cut -d '/' -f3)`: If the container is started in the DooD environment provided by [`dev-base`](../dev-base/README.md) in Devcontainers, then this forwards the required volumes from the base container to the _quartus_ tool container. This is required to access any path in `/workspaces`.

### Alias
To release your fingers from the pain of entering these commands and arguments all the time, use an alias function.

Put the below functions in a script and `source <script>` it in whatever shell you need the gcc toolchain. After this, having gcc installed locally is almost identical as having it isolated in this self-contained docker image.

```bash
function get_common_args () {
    common_vols="--volumes-from $(cat /proc/self/cgroup | head -n 1 | cut -d '/' -f3)"
    common_misc="--workdir $(pwd) --interactive --tty --rm"
    common_args="$common_vols $common_misc"
    echo $common_args
}
export -f get_common_args

function make () {
    riscv_args="--hostname riscv-gcc --entrypoint make $(get_common_args)"
    docker run $riscv_args ghcr.io/nikleberg/riscv-gcc:13.2-rv32imac $*
}
export -f make
function riscv32-unknown-elf-gcc () {
    riscv_args="--hostname riscv-gcc --entrypoint riscv32-unknown-elf-gcc $(get_common_args)"
    docker run $riscv_args ghcr.io/nikleberg/riscv-gcc:13.2-rv32imac $*
}
export -f riscv32-unknown-elf-gcc
function gcc () {
    riscv_args="--hostname riscv-gcc --entrypoint gcc $(get_common_args)"
    docker run $riscv_args ghcr.io/nikleberg/riscv-gcc:13.2-rv32imac $*
}
export -f gcc
function openocd () {
    riscv_args="--hostname riscv-gcc --entrypoint openocd $(get_common_args)"
    docker run $riscv_args ghcr.io/nikleberg/riscv-gcc:13.2-rv32imac $*
}
export -f openocd
function riscv_bash () {
    riscv_args="--hostname riscv-gcc --entrypoint bash $(get_common_args)"
    docker run $riscv_args ghcr.io/nikleberg/riscv-gcc:13.2-rv32imac $*
}
export -f riscv_bash
```

Note the additional `riscv_bash` alias is for debugging. It overwrites the entrypoint in the image and lets you more easily debug problems by dropping you into a bash shell inside the container.

## License
[MIT](../LICENSE) © [NikLeberg](https://github.com/NikLeberg).
