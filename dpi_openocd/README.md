# dpi_openocd
This container wraps a version of `openocd` - _Open On-Chip Debugger_ with enabled `jtag_dpi` driver.

Main use of the `jtag_dpi` driver is to connect OpenOCD with a simulated CPU that is running inside an HDL simulator. It _sort of_ uses `DPI` aka the _SystemVerilog Direct Programming Interface_. But any other simulator of any HDL language may use it as nothing in the `jtag_dpi` driver is specific to SystemVerilog. It simply connects to an TCP port and runs on a very minimalistic protocol:
 - `reset\n`
    - trigger JTAG reset _trst_
 - `ib N\n` + _N_ bits of data
    - run an instruction register scan chain
    - must be responded with _N_ bits of captured data
 - `db N\n` + _N_ bits of data
    - run a data register scan chain
    - must be responded with _N_ bits of captured data

See [NikLeberg/cosim_jtag](https://github.com/NikLeberg/cosim_jtag) for a VHDL implementation of the other side to this driver. It exposes an easy to use JTAG TAP which should be compatible to debug/connect _any_ VHDL softcore.

## Tags
| Tag(s) | OpenOCD Version | Note |
|---|---|---|
| `latest` | `master` | At time of writing, master points to `v0.12.0+dev`. |

## Usage
The image has an `entrypoint.sh` that runs two stages:

1. The first stage runs a _wait-connect-loop_. It indefinitely tries to connect to the configured DPI TCP port. Only if that suceeded then the second stage is executed.
2. The second stage simply invokes OpenOCD with a default configuration. Once that instance is teminated (reached end of config script or shutdown command) the container will stop.

### Environment Variables
You can modify the behaviour of the default configuration with some environment variables:

- `DPI_PORT`: Port to where the `jtag_dpi` driver will try to connect to. Default: _5555_.
- `GDB_PORT`: Port to where you may connect with GDB i.e. `target extended-remote :XXXX`. Default: _3333_.
- `CHIPNAME`: Name for OpenOCD of the RISC-V JTAG TAP. OpenOCD target will be named _CHIPNAME + cpu_. Default: _riscv_.
- `CPUTAPID`: Hexadecimal value of the expected TAP id (IDCODE). Default: _0x00000001_.

To set them, add them to the docker run command:
```shell
docker run --env DPI_PORT=1234 ghcr.io/nikleberg/dpi_openocd
```

### Default Configuration
If you don't specify any additional run commands, the default configuration will start OpenOCD using the above env vars. See [default.cfg](./default.cfg).

Alternatively you can overwrite everything alltogether by specifiying your own OpenOCD CLI arguments after the container name, like so:
```shell
docker run ghcr.io/nikleberg/dpi_openocd -c <your_config>.cfg
```
All arguments are forwared as-is to OpenOCD.

> [!NOTE]
> The initial _wait-connect-loop_ is still ran. So without overwriting `DPI_PORT` it will default to port _5555_.

> [!NOTE]
> If you want to load your own configuration e.g. `-c <config>.cfg`, then ensure that the file is readable from inside the container. I.e. you must mount it into the container.

### Port Mapping and Connectivity
To get access to the DPI and GDB TCP ports you must make them available from outside the container.
```shell
docker run --publish 5555:5555 --publish 3333:3333 ghcr.io/nikleberg/dpi_openocd
```

If you run the simulator or GDB in another container side-by-side, it may be easier to have all container share the same network. You could do that most elegantly with docker-compose. A crude alternative is to name one container and let the other re-use that containers network-stack, like so:
```shell
docker run --name openocd ghcr.io/nikleberg/dpi_openocd # name the container
docker run --network container:openocd <other_image> # re-use container network
```

## License
[MIT](../LICENSE) © [NikLeberg](https://github.com/NikLeberg).
