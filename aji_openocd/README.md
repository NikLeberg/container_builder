# aji_openocd
> This image is part of the dockerized tools meant to be used with image [`dev-base`](../dev-base/README.md) in GitHub Codespace or VsCode devcontainer environments.
> For answers to general why? and how? consult the [README of dev-base](../dev-base/README.md).
Companion to the [`quartus`](../quartus/README.md) image with AJI virtual JTAG infrastructure and OpenOCD. It allows to use this virtual JTAG system with OpenOCD for example to debug IP Cores in the FPGA.

This image contains a containerized version of the following [OpenOCD](https://github.com/intel/aji_openocd) fork from Intel that enables AJI.

Note that OpenOCD was only compiled with AJI support. All other adapters (USB, FTDI, etc.) are not compiled in.

## What is AJI?
AJI stands for Altera Virtual JTAG Interface (sometimes also abbreviated to VJI). It enables the extension of the physical JTAG chain with one or multiple virtual JTAG chains inside the FPGA fabric. This is extensively used for Altera's own products like _Signal Tap Logic Analyzer_ or _NIOS II Debugger_. But by instantiating the [`sld_virtual_jtag`](https://docs.altera.com/r/docs/683705/current) entity one can extend this with custom JTAG TAPs. The required System Level Debug (SLD) infrastructure is then automatically instantiated when synthesizing with quartus. See the excellent [blog post](https://tomverbeure.github.io/2021/05/02/Intel-JTAG-UART.html#the-intels-virtual-jtag-system) of tomverbeure for a more in depth explanation.

## Usage
To start, the `jtagd` server from the [quartus](../quartus/README.md) image must be accessible. The simplest solution is to augment the quartus image's run arguments with `--net=host` to make it use the host network.

Then start a container from this image with the same `--net=host` flag to be able to connect to the JTAG server:
```shell
$ docker run --net=host ghcr.io/nikleberg/aji_openocd
```

After that you can start OpenOCD inside the container and connect to the virtual JTAG inside the FPGA. OpenOCD expects a script with name `openocd.cfg` in the current directory. Alternatively you can specify the exact script file to run with the `-f` flag.
```bash
$ openocd -f <script.cfg>
```
See the example script [`neorv32_aji.cfg`](neorv32_aji.cfg) that sets this up for the excellent [NEORV32](https://github.com/stnolting/neorv32) soft core running on a Cyclone IV E. Or have a look at the Intel examples in `/opt/aji_openocd/tcl/boards` where you find `altera_arria10__aji_client.cfg` and `altera_arria10_niosv__aji_client.cfg`.

Output of OpenOCD should look something like this:
```
Open On-Chip Debugger 0.11.0-R22.4-gc5bf4f3-dirty (2026-06-21-10:20)
Licensed under GNU GPL v2
For bug reports, read
        http://openocd.org/doc/doxygen/bugs.html
Info : only one transport option; autoselect 'jtag'
Info : Application name is OpenOCD.20260628174710
Info : No cable specified, so will be searching for cables

Info : At present, The first hardware cable will be used [1 cable(s) detected]
Info : Cable 1: device_name=(null), hw_name=USB-Blaster, server=(null), port=1-4, chain_id=0x55677f515100, persistent_id=1, chain_type=1, features=14336, server_version_info=Version 25.1std.0 Build 1129 10/21/2025 SC Standard Edition
Info : TAP position 0 (20F20DD) has 5 SLD nodes
Info :     node  0 idcode=0C006E00 position_n=0
Info :     node  1 idcode=00406E00 position_n=0
Info :     node  2 idcode=0C006E01 position_n=0
Info :     node  3 idcode=0C006E02 position_n=0
Info :     node  4 idcode=30006E00 position_n=0
Info : Discovered 1 TAP devices
Info : Detected device (tap_position=0) device_id=020f20dd, instruction_length=10, features=4, device_name=10CL016(Y|Z)/EP3C16/EP4CE15
Info : Found an Intel device at tap_position 0.Currently assuming it is SLD Hub
Info : This adapter doesn't support configurable speed
Info : JTAG tap: cycloneive.tap tap/device found: 0x020f20dd (mfg: 0x06e (Altera), part: 0x20f2, ver: 0x0)
Info : JTAG tap: cycloneive.tap Parent Tap found: 0x020f20dd (mfg: 0x06e (Altera), part: 0x20f2, ver: 0x0)
Info : Virtual Tap/SLD node 0x00406E00 found at tap position 0 vtap position 1
Info : datacount=1 progbufsize=2
Info : Disabling abstract command reads from CSRs.
Info : Examined RISC-V core; found 2 harts
Info :  hart 0: XLEN=32, misa=0x40800100
Info :  hart 1: currently disabled
Info : starting gdb server for cycloneive.neorv32_cpu on 3333
Info : Listening on port 3333 for gdb connections
Info : Listening on port 6666 for tcl connections
Info : Listening on port 4444 for telnet connections
```

If all went well then OpenOCD is now exposing a GDB server on port `3333` (default) and you may debug the soft core if you have specified it. Alternatively if you only have simple IR / DR registers in your virtual JTAG TAP you can access them with the lowlevel JTAG commands `irscan` and `drscan` in OpenOCD. See [here](https://openocd.org/doc-release/html/JTAG-Commands.html) for documentation.

### Additional Debugging
The whole AJI system has a _LOT_ of moving parts and many things can go wrong. The following are some known failure modes and how to mitigate or debug them.

If OpenOCD reports:
```
Error: Failed to query server for hardware cable information.  Return Status is 82 (AJI_SERVER_ERROR)
Error: Cannot select JTAG Cable. Return status is 82 (AJI_SERVER_ERROR)
```
Then this likely means that the `jtagd` server isn't running. Start it inside the quartus container by running `jtagd` in a shell or by simply programming the FPGA once with the Quartus Programmer which will start the server for you.
This error also manifests if the two containers can't connect to each other i.e. don't share the same network. Ensure you really started both of them in the same container network or with the `--net=host` flag.

Or if you encounter:
```
Error: JTAG server reports that it has no hardware cable
Error: Cannot select JTAG Cable. Return status is 86 (AJI_BAD_HARDWARE)
```
Then this likely means that your FPGA board isn't plugged in. I'd plug it in if I were you.
If it still can't detect the download cable, check the jtag enumeration by running (in the quartus container):
```shell
$ jtagconfig --enum
```
It should output the detected cable name and the attached FPGA. Something like:
```
1) USB-Blaster [1-1]
  020F20DD   10CL016(Y|Z)/EP3C16/EP4CE15
```

To debug the enumeration of virtual SLD JTAG TAPs there is the `system-console` GUI program that lists the detected endpoints. Run it inside the quartus container with:
```bash
$ $QUARTUS_ROOTDIR/quartus/sopc_builder/bin/system-console
```
In the left side of the window in the _System Explorer_ expand _devices_ > \<FPGA type\> > _(link)_ > _JTAG_. There you find the SLD nodes that are described within the FPGA.

### Additional `docker run` Arguments
For improved functionality and ease-of-use you may want to add some of these arguments to the `docker run` command stated above:
 - Anything mentioned in [`dev-base`](../dev-base/README.md)
 - `--volume=/dev:/dev --privileged`: Allows USB/JTAG access to FPGAs for programming.
 - `--net=host`: Use host network. This allows OpenOCD to access the JTAG server from Quartus. Additionally this then allows other containers to connect to the GDB server. Alternatively you may configure a shared container network.

## License
[MIT](./../LICENSE) © [NikLeberg](https://github.com/NikLeberg).
