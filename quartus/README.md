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
| `18.1` | 18.1.0 | Cyclone IV | Quartus GUI non functional with WSLg (only window borders), use [`VcXsrv`](https://github.com/marchaesen/vcxsrv). |
| `22.1` | 22.1.2 | Cyclone IV | - |
| `23.1` | 23.1.1 | Cyclone IV | - |
| `24.1` | 24.1.0 | Cyclone IV | Very slow. ~2x slowdown compared to older versions. Regardless if GUI or scripts are used. |
| `25.1` | 25.1.0 | Cyclone IV | - |

Feel free to open an issue to request other versions or additional device support.

## Usage
> Please note that using Quartus implies acceptance of [Intel/Altera FPGA's EULA](http://fpgasoftware.intel.com/eula/) for the appropriate version(s) you use.

The image has `quartus_sh` set as `ENTRYPOINT`. Simply running a container without arguments will invoke `quartus_sh` with the default `CMD` argument `-version` and print the Quartus version:
```
$ docker run ghcr.io/nikleberg/quartus:24.1
> Quartus Prime Shell
  Version 24.1std.0 Build 1077 03/04/2025 SC Lite Edition
  Copyright (C) 2025  Altera Corporation. All rights reserved.
```

For an actual usage you want to override the `CMD` by giving additional arguments to the `docker run` command. For example to run a tcl script you could run:
```
$ docker run ghcr.io/nikleberg/quartus:24.1 -t <script>.tcl
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

### Device Support
To keep the base image lean, it does not ship with any deviceinfo files. To allow quartus to actually build a bitfile for your device you must use one (or multiple) of the provided _data-only_ device docker images. The device images are a bit special to handle but allow for a minimal setup while keeping everything well separeted.

First, just _create_ a named container from the data-only image by running:
```
$ docker create --name quartus-devinfo -v <path to devinfo files> ghcr.io/nikleberg/quartus:<quartus version>-<device type>
```

For _quartus version_ choose one of the table above. For _path to devinfo files_ and _device type_ see the following table. Note that you can also just use one of the given _volume paths_ if there are multiple listed. E.g. if you only use Cyclone IV E (and not GX) products, you can omit the _cycloneivgx_ path.

| Tag | Device Support | Volume Path(s) |
|---|---|---|
| `<quartus version>-cycloneiv` | Cyclone IV (E / GX) | `-v /opt/quartus_lite/quartus/common/devinfo/cycloneive` and `-v /opt/quartus_lite/quartus/common/devinfo/cycloneivgx` |
| `<quartus version>-cyclonev` | Cyclone V (E / GX / GT / SX / SE / ST) | `-v /opt/quartus_lite/quartus/common/devinfo/cyclonev` |

Now, you can start an actual quartus image and include the data from the listed volume paths of the other named container with:
```
$ docker run --volumes-from quartus-devinfo ghcr.io/nikleberg/quartus:24.1
```

To support multiple devices at the same time you may use multiple `--volumes-from` like so:
```
$ docker create --name devinfo-cycloneive -v /opt/quartus_lite/quartus/common/devinfo/cycloneive ghcr.io/nikleberg/quartus:24.1-cycloneiv
$ docker create --name devinfo-cyclonev -v /opt/quartus_lite/quartus/common/devinfo/cyclonev ghcr.io/nikleberg/quartus:24.1-cyclonev
$ docker run --volumes-from devinfo-cycloneive --volumes-from devinfo-cyclonev ghcr.io/nikleberg/quartus:24.1
```

### Additional `docker run` Arguments
For improved functionality and ease-of-use you may want to add some of these arguments to the `docker run` command stated above:
 - Anything mentioned in [`dev-base`](../dev-base/README.md)
 - `--volume=/dev:/dev --privileged`: Allows USB/JTAG access to FPGAs for programming.

## License
[MIT](../LICENSE) © [NikLeberg](https://github.com/NikLeberg).
