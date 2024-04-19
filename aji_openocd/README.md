# aji_openocd
> This image is part of the dockerized tools meant to be used with image [`dev-base`](../dev-base/README.md) in GitHub Codespace or VsCode devcontainer environments.
> For answers to general why? and how? consult the [README of dev-base](../dev-base/README.md).
Companion to the [`quartus`](../quartus/README.md) image with AJI virtual JTAG infrastructure and OpenOCD. It allows to use this virtual JTAG system with OpenOCD for example to debug IP Cores in the FPGA.

This image contains a continerized version of the following [OpenOCD](https://github.com/intel/aji_openocd) fork from Intel that enables aji.

## WIP
This is a work-in-progress. To do:
 - document how to integrate with the dev-base style container images
 - how to network forward the openocd sockets
 - actually get it to work with NEORV32

## What is AJI?
AJI stands for Altera Virtual JTAG Interface. It enables the extenstion of the physical JTAG chain with ore or multiple virtual JTAG chains inside the FPGA fabric. This is extensively used for Altera's own products like _Signal Tap Logic Analyzer_ or _NIOS II Debugger_. But by instanciating the [`sld_virtual_jtag`](https://cdrdv2-public.intel.com/666577/ug_virtualjtag-683705-666577.pdf) entity one can extend this with custom JTAG TAPs. The required System Level Debug (SLD) infrastructure is then automatically instantiated when synthesizing with quartus. See the excellent [blog](https://tomverbeure.github.io/2021/05/02/Intel-JTAG-UART.html#the-intels-virtual-jtag-system) of tomverbeure for more in depth explanation.

## Usage
To access the _USB Blaster_ hardware we need to forward the USB tree to the docker container. We do this by mounting the full `/dev` tree and giving it privileged access. One could also only map the specific USB device but this would not survive a un-plug / re-plug.
Forwarding can be done with the following run flags:
```shell
docker run --privileged -v /dev/bus/usb:/dev/bus/usb ghcr.io/nikleberg/aji_openocd
```

Inside the container you need to start the jtag server of quartus before you can connect with OpenOCD. The quartus programmer uses the same server, so either start the programmer after which the server will live on for about ~2 mins, or start the server manually with the below command. The server should stay around and allow every access from the local host (e.g. OpenOCD).
```shell
jtagd
```

To check if the USB Blaster is detected correctly run the following command:
```shell
jtagconfig --enum
```
It should output the detected cable name and the attached FPGA. Something like so:
```
root@aji_openocd:~# jtagconfig --enum
1) USB-Blaster [1-1]
  020F20DD   10CL016(Y|Z)/EP3C16/EP4CE15
```

After that you can start OpenOCD and connect to the virtual JTAG inside the FPGA. OpenOCD expects a script with name `openocd.cfg` in the current directory. Alternatively you can specify the exact script file to run with the `-f` flag.
```bash
/opt/aji_openocd/openocd -f <script.cfg>
```
See the example script [`neorv32.cfg`](neorv32.cfg) that sets this up for the excellent [NEORV32](https://github.com/stnolting/neorv32) soft core running on a Cyclone IV E. Or have a look at the Intel examples in `/opt/aji_openocd/tcl/boards` where you find `altera_arria10__aji_client.cfg` and `altera_arria10_niosv__aji_client.cfg`.

OpenOCD now exposes a GDB server on port `3333` (default) and you may debug the soft core if you have specified it. Alternatively if you only have simple IR / DR registers in your virtual JTAG TAP you can access them with the lowlevel JTAG commands `irscan` and `drscan` in OpenOCD. See [here](https://openocd.org/doc-release/html/JTAG-Commands.html) for documentation.

## Additional Information
Note that OpenOCD was only compiled with AJI support. All other adapters (USB, FTDI, etc.) are not compiled in.

To debug the enumeration of virtual SLD JTAG TAPs there is the `system-console` that lists the detected endpoints. To use it you need to install an additional package beforehand:
```bash
apt update
apt install libxi-dev
$QUARTUS_ROOTDIR/quartus/sopc_builder/bin/system-console
```
In the left side of the window in the _System Explorer_ expand _devices_ > \<FPGA type\> > _(link)_ > _JTAG_. There you find the SLD nodes that are described within in the FPGA.

## License
[MIT](./../LICENSE) © [NikLeberg](https://github.com/NikLeberg).
