# quartus-prime
[Intel Quartus Prime Lite Edition v21.1](https://www.intel.de/content/www/de/de/products/details/fpga/development-tools/quartus-prime/resource.html) development environment prepackaged into a container.

This container contains the following:
* Intel Quartus Prime Lite Edition v21.1.1
* Questa Intel Starter FPGA Edition-64 Version 2021.2
* All default support Files for:
  * Arria Lite
  * Cyclone IV
  * Cyclone V
  * Cyclone 10 LP
  * Max
  * Max 10

To reduce the size some per default installed parts were removed:
* Intel / Altera IP blocks
* Nios II EDS

But even with these removed, the image is still very big (> 6 GB). The large _Quartus install_ image layer is split up into multiple smaller layers to help speed up image pull / download and make it more robust.

## Usage
Generally the container can just be used with:
```shell
docker run ghcr.io/nikleberg/quartus-prime
```
And inside the running container you could for example run tcl scripts for synthesis or simulation like so:
```bash
quartus_sh -t <script>.tcl  # Quartus Shell
vsim -c -do <script>.tcl    # QuestaSim Shell
```
To use the Quartus or QuestaSim with a GUI, forward your X11 `DISPLAY` environment variable to the container like so:
```shell
docker run -e DISPLAY ghcr.io/nikleberg/quartus-prime
```
If you are running in _WSL2_ see this [blog post](https://aalonso.dev/blog/how-to-use-gui-apps-in-wsl2-forwarding-x-server-cdj) on how to setup `VcXsrc` as X11 Server on the Windows Host. This allows you to access the X11 server from WSL. To further forward this to the docker container you can use the following argument when starting the container: `-e DISPLAY=host.docker.internal:0.0`. This special host name only works when the docker host is the _Docker Desktop for Windows_ application.

### Questasim License
Since v21.1 of Quartus, ModelSim was replaced by QuestaSim. It requires a valid license that can be obtained from [intel](https://licensing.intel.com/). For ease of use a valid license is already included. But it is bound to a specific NIC id e.g. MAC address `00:ab:ab:ab:ab:ab`. Depending on where you want to use the container you have to set the MAC address differently:

#### Local
To use the container locally just add the `mac-address` option to the docker run command:
```shell
docker run --mac-address=00:ab:ab:ab:ab:ab ghcr.io/nikleberg/quartus-prime
```

#### GitHub Action
For using this container as image in the CI environment of GitHub Actions add the `mac-address` option to `jobs.<job_id>.container.options` in the yaml:
```yaml
jobs:
  example:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/nikleberg/quartus-prime:latest
      options: --mac-address=00:ab:ab:ab:ab:ab
    steps:
    - ...
```
See the full example [github-ci-example.yml](github-ci-example.yml).

#### GitLab CI
The GitLab CI yaml syntax i.e. its docker runner has [currently](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2344) no capability to set additional docker run options. But if the runner has the `CAP_NET` capability then one can change the MAC address within the container itself. For example with `ifconfig`:
```yaml
example:
  image: ghcr.io/nikleberg/quartus-prime:latest
  before_script: |
    apt-get -q -y update && apt-get -q -y install net-tools
    ifconfig eth0 down
    ifconfig eth0 hw ether "00:ab:ab:ab:ab:ab"
    ifconfig eth0 up
  script: ...
```
See the full example [gitlab-ci-example.yml](gitlab-ci-example.yml).

## Additional Information

### Environment Variables
* `$QUARTUS_ROOTDIR` - Root install directory of quartus
* `$LM_LICENSE_FILE` - Location of the QuestaSim license, overwrite with your own if you have one

## License
[MIT](./../LICENSE) © [NikLeberg](https://github.com/NikLeberg).
