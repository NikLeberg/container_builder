# oss-cad-suite
> This image is part of the dockerized tools meant to be used with image [`dev-base`](../dev-base/README.md) in GitHub Codespace or VsCode devcontainer environments.
> For answers to general why? and how? consult the [README of dev-base](../dev-base/README.md).

This container contains a continerized version of `oss.cad.suite` - _open source digital design and verification tools_ from [YosysHQ/oss-cad-suite-build](https://github.com/YosysHQ/oss-cad-suite-build).

## Tags
| Tag(s) | Version | Note |
|---|---|---|
| `2025-04-05` `latest` | 2025-04-05 | 14 | - |

Feel free to open an issue to request other versions.

## Usage
The image contains heaps of OSS EDA tools like `GHDL`, `yosys`, `gtkwave` and so much more. See the [README of YosysHQ/oss-cad-suite-build](https://github.com/YosysHQ/oss-cad-suite-build/) for a full list of tools and their usage.

> Note: Diverging from the usual `dev-base` environment, this image does not set a default entrypoint because there would be so many to choose from...

### Additional `docker run` Arguments
For improved functionality and ease-of-use you may want to add some of these arguments to the `docker run` command stated above:
 - `--hostname oss-cad-suite`: Make the shells in the container display a human readable machine name.
 - `--interactive --tty`: This makes the started container interactive and not run in the background.
 - `--rm`: Removes the container after the command is finished, your disk will thank you.
 - `--workdir $(pwd)`: Sets the working directory inside the container to the current shell path.
 - `--volumes-from $(cat /proc/self/cgroup | head -n 1 | cut -d '/' -f3)`: If the container is started in the DooD environment provided by [`dev-base`](../dev-base/README.md) in Devcontainers, then this forwards the required volumes from the base container to the _oss-cad-suite_ tool container. This is required to access any path in `/workspaces`. 

## License
[MIT](../LICENSE) © [NikLeberg](https://github.com/NikLeberg).
