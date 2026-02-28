# nvc
> This image is part of the dockerized tools meant to be used with image [`dev-base`](../dev-base/README.md) in GitHub Codespace or VsCode devcontainer environments.
> For answers to general why? and how? consult the [README of dev-base](../dev-base/README.md).

This container contains a continerized version of `nvc` - _VHDL compiler and simulator_ from [nickg/nvc](www.nickg.me.uk/nvc/).

## Tags
| Tag(s) | NVC Version | LLVM Version | Note |
|---|---|---|---|
| `master` | master | 14 | This uses the current nvc git master branch at time of build and may be unstable. |
| `1.19` `latest` | 1.19.2 | 14 | - |
| `1.18` | 1.18.2 | 14 | - |
| `1.17` | 1.17.2 | 14 | - |
| `1.16` | 1.16.2 | 14 | - |
| `1.15` | 1.15.2 | 14 | - |

Feel free to open an issue to request other versions.

## Usage
The image has `nvc` set as `ENTRYPOINT`. Simply running a container without arguments will invoke `nvc` with the default `CMD` argument `--version` and print the nvc version:
```shell
$ docker run ghcr.io/nikleberg/nvc
> nvc 1.19.2 (Using LLVM 14.0.0)
> Copyright (C) 2011-2026  Nick Gasson
> This program comes with ABSOLUTELY NO WARRANTY. This is free software, and
> you are welcome to redistribute it under certain conditions. See the GNU
> General Public Licence for details.
```

For an actual usage you want to override the `CMD` by giving additional arguments to the `docker run` command. For example to run a tcl script you could run:
```bash
$ docker run ghcr.io/nikleberg/nvc --do <script>.tcl
```

See the [official manual](https://www.nickg.me.uk/nvc/manual.html) for more options.

### Additional `docker run` Arguments
For improved functionality and ease-of-use you may want to add some of these arguments to the `docker run` command stated above:
 - `--hostname nvc`: Make the shells in the container display a human readable machine name.
 - `--interactive --tty`: This makes the started container interactive and not run in the background.
 - `--rm`: Removes the container after the command is finished, your disk will thank you.
 - `--workdir $(pwd)`: Sets the working directory inside the container to the current shell path.
 - `--volumes-from $(cat /proc/self/cgroup | head -n 1 | cut -d '/' -f3)`: If the container is started in the DooD environment provided by [`dev-base`](../dev-base/README.md) in Devcontainers, then this forwards the required volumes from the base container to the _nvc_ tool container. This is required to access any path in `/workspaces`. 

### Alias
To release your fingers from the pain of entering these commands and arguments all the time, use an alias function.

Put the below functions in a script and `source <script>` it in whatever shell you need the `nvc` command. After this, having `nvc` installed locally is almost identical as having it isolated in this self-contained docker image.

```bash
function get_common_args () {
    common_vols="--volumes-from $(cat /proc/self/cgroup | head -n 1 | cut -d '/' -f3)"
    common_misc="--workdir $(pwd) --interactive --tty --rm"
    common_args="$common_vols $common_misc"
    echo $common_args
}
export -f get_common_args

function nvc () {
    nvc_args="--hostname nvc $(get_common_args)"
    docker run $nvc_args ghcr.io/nikleberg/nvc $*
}
export -f nvc
function nvc_bash () {
    nvc_args="--hostname nvc --entrypoint bash $(get_common_args)"
    docker run $nvc_args ghcr.io/nikleberg/nvc $*
}
export -f nvc_bash
```

Note the additional `nvc_bash` alias. It overwrites the entrypoint in the image and lets you more easily debug problems by dropping you into a bash shell inside the container.

## License
[MIT](../LICENSE) © [NikLeberg](https://github.com/NikLeberg).
