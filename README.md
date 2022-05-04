# container_builder
This project uses the GitHub Actions CI to automatically build and push container images to [dockerhub](https://hub.docker.com/) and the GitHub registry. The main goal of this is to prebuild CI images for other projects. Otherwise the CI of those projects would need to rebuild the image every time on its own. With this it can just download the prebuilt image.

## Usage
dockerhub:
- `docker pull nikolodion/<image_name>`

GitHub registry:
- `docker pull ghcr.io/nikleberg/<image_name>`

## Adding images
To build the different images, [matrix builds](https://docs.github.com/en/actions/using-jobs/using-a-build-matrix-for-your-jobs) in [CI.yml](.github/workflows/CI.yml) are defined. Additional images can be added by extending the toplevel `env` variable with the image name. In a subfolder of the same name place the coresponding Dockerfile. Optionally one can add `pre_build.sh` and `post_build.sh` scripts that will be run before and after the image is build. This allows for example to download support files, disabling Trivy/Dockle scanner steps or running tests against the image. 

## License
[MIT](LICENSE) © [NikLeberg](https://github.com/NikLeberg).
