# dev-base
A basic devcontainer image with bootstraping tools for development.

Main goal is to provide Docker-outside-of-Docker (DooD) functionality to re-use the hosts docker environment to launch additional containers as needed.

The idea is, that instead of requirng one huge image with every tool baked in, have only a simple base image where additional tools can be _installed_ in on-needed spun-up and self-contained docker containers.

Targets for the decvontainer are GitHub Codespaces and VsCode (Linux or Windows with WSL).


## Usage
The image is meant to be used in a [`devcontainer.json`](https://containers.dev/implementors/json_reference/) file. The minimal example could look something like this:

```json
{
    "image": "ghcr.io/nikleberg/dev-base:staging",
    "runArgs": [
        // forward docker socket to allow Docker-outside-of-Docker (DooD)
        "--volume=/var/run/docker.sock:/var/run/docker.sock"
    ]
}
```

Forwarding the docker socket is required for the _Docker-outside-of-Docker (DooD)_ functionality to work. This is what allows you to spin-up additional tools in on-needed containers from within this basic container. Re-using the docker installation on the host allows to reduce ressource usage and improve performance.

> Alternatively you could also start a fully fledged docker installation within a container. This would be called _Docker inside of Docker (DinD)_ but it is not supported here.

I recommend adding `name: xyz` as key and setting a hostname with `--hostname xyz` for ease of use (and getting rid of cryptic sha's in our environments). With those a `devcontainer.json` file would look as follows:

```json
{
    "name": "${localWorkspaceFolderBasename}",
    "image": "ghcr.io/nikleberg/dev-base:staging",
    "runArgs": [
        // set a human friendly machine name for the container
        "--hostname=${localWorkspaceFolderBasename}",
        // forward docker socket to allow Docker-outside-of-Docker (DooD)
        "--volume=/var/run/docker.sock:/var/run/docker.sock"
    ]
}
```

The `${localWorkspaceFolderBasename}` variable is expanded by VsCode to the name of the opened folder. I.e. if you have a project with `<project_name>/.devcontainer/devcontainer.json` (or `<project_name>/devcontainer.json`) the started container will be named `<project_name>`.

A more fully-fledged `devcontainer.json` that is using this image can be seen in my other project [neorv32_soc](https://github.com/NikLeberg/neorv32_soc/blob/main/.devcontainer/devcontainer.json).


### Alternative, _the CLI way_
If you do not want to use _devcontainers_ ot simply prefer to work from the CLI, then you may also just start a container with:
```bash
docker run --volume=/var/run/docker.sock:/var/run/docker.sock ghcr.io/nikleberg/dev-base
```
Note that this use-case is not tested. There might be some magic that VsCode and _devcontainers_ does behind the scenes to enable the wished for functionality of this image that a simply started container does not provide...


## Integrating additional Tools
The main goal of this image is to enable the use of additional tools, packaged in self-contained docker images.

I.e. inside the base container another tool specific container can be started with `docker run <tool_image>`.

For this to work some things have to be aligned:
 1. DooD functionality i.e. the docker socket must be available (this is fulfilled with the above mentioned `--volume` argument)
 2. The dockerfile of the self-contained tool has to set [`ENTRYPOINT`](https://docs.docker.com/engine/reference/builder/#entrypoint) and [`CMD`](https://docs.docker.com/engine/reference/builder/#cmd).
 3. Only ressources (files, folders, devices, etc.) from the host can be accessed/mapped directly. When the base container and the additional tool container need to share ressources this needs to be done via the host or via shared volumes.
 4. (optional) Setup of alias command(s) in base container that automatically spawn the tool container when needed.


### Dockerfile #1
The tool image can set `ENTRYPOINT` and `CMD` in its `dockerfile`. For an example application `foo` that is started with argument `--bar` this might look like:

```dockerfile
ENTRYPOINT ["foo"]
CMD ["--bar"]
```

Note:
 - The `ENTRYPOINT` can be overridden on container creation (`docker run`) with argument `--entrypoint <command>`.
 - The `CMD` is automatically overridden with the arguments on container creation (`docker run`) that are behind the image name. I.e. `--bar` can be overriden to `--baz` with `docker run <image_name> --baz`.
 - Set these two such that the main functionality of the tool is easily accessible.


### Access to Project Files #2
The tool container can't access the files and folders inside the base container directly. It can only do it via the host or with the use of shared volumes.

Within decvontainers one generally should not store data. The project files are mounted into the devcontainer aka the base container. We can mount the same files and folders into the tool container with the `docker run` argument `--volumes-from $(cat /proc/self/cgroup | head -n 1 | cut -d '/' -f3)` [[source](https://stackoverflow.com/a/46586925)]. This looks up the container sha-id of the base container and mounts all volumes from it to the tool container.


### Setup of Alias #3
To simplify the start of the tool container, a bash alias may be installed that does this automatically.

Considering the previous `foo` example, it's alias could look like:
```bash
alias foo="docker run -it --rm foo:latest"
```

The alias works well for simple things. For more complex tools or argument combinations you could also install a function-like alias:
```bash
function foo () {
    docker run -it --rm foo:latest $*
}
export -f foo
```

After this alias has been installed, simply entering `foo <any> <argument>` gets expanded into `docker run -it --rm foo:latest <any> <argument>` and interactively starts the foo command in the tool container.

Note:
 - _Installing_ the aliases means to put them into a script and sourcing that script where you want to use the command. I.e. `source <script>`.
 - Arguments `-it` lets the container be run interactively and with an attached tty.
 - Argument `--rm` removes the container after use. Otherwise every invocation of the alias would leave a stopped container around.
 - To use the alias for VsCode `tasks.json` you can set the environment variable `BASH_ENV` like so: `"options": { "env": { "BASH_ENV": "<alias_script>" } }`. Each task of `"type": "shell"` will then automatically get the aliases.


### Bonus: GUI
Some tools may want to access the GUI. For this the X11 socket can simply be forwarded to the container. Use the additional `docker run` argument `--env=DISPLAY=:0 --volume=/tmp/.X11-unix/:/tmp/.X11-unix/`.


## Example
I constructed this mainly for my own use-case in project [`neorv32_soc`](https://github.com/NikLeberg/neorv32_soc). There you will find a complete example of how this all comes together:
 - The [`devcontainer.json`](https://github.com/NikLeberg/neorv32_soc/blob/main/.devcontainer/devcontainer.json) that uses this `dev-base` image.
 - The [.env](https://github.com/NikLeberg/neorv32_soc/blob/main/.devcontainer/.env) that defines the environment and aliases for the different tools.
 - The [`tasks.json`](https://github.com/NikLeberg/neorv32_soc/blob/main/.vscode/tasks.json) that installs the aliases via `BASH_ENV` and uses the continerized tools in many tasks.


## License
Parts of the `Dockerfile` are based off:
 - https://github.com/devcontainers/images/blob/main/src/universal/.devcontainer/Dockerfile
 - https://github.com/devcontainers/features/blob/main/src/docker-outside-of-docker/install.sh

which both stand under MIT license.

Additional works are licensed under [MIT](../LICENSE) © [NikLeberg](https://github.com/NikLeberg).
