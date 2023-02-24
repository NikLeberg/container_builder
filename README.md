# container_builder
This project uses the GitHub Actions CI to automatically build and push container images to the [GitHub registry](ghcr.io). The main goal of this is to prebuild CI images for other projects. Otherwise the CI of those projects would need to rebuild the image every time on its own. With this it can just download the prebuilt image.

## Usage
GitHub registry:
- `docker pull ghcr.io/nikleberg/<image_name>`

For specific usage of each image please have a look at the corresponding `README.md` file in the image subfolder.

## Adding images
To build the different images, [matrix builds](https://docs.github.com/en/actions/using-jobs/using-a-build-matrix-for-your-jobs) in [CI.yml](.github/workflows/CI.yml) are defined. Additional images can be added by extending the toplevel `env` variable with the image name. In a subfolder of the same name place the coresponding Dockerfile. Optionally one can add `pre_build.sh` and `post_build.sh` scripts that will be run before and after the image is build. This allows for example to download support files, disabling Trivy/Dockle scanner steps or running tests against the image.

### Dependency Resolution
Three stages exists that run one after the other to allow for dependencies between repository internal images.
If for example a new image `image_new` depends on `image_a`, then add the new image to the `env.stage_2` entry in [CI.yml](.github/workflows/CI.yml). This assumes the base image `image_a` was in `env.stage_1`.
Additionally you must add a `depends.on` file to the image folder that contains a single line naming the base image, in the example this would be `image_a`. Otherwise the new image will not be rebuilt if the base image changes.

## Tags
During build of images (i.e. in pull requests) the tag `staging` is pushed. If the build is successful, then the same image will be released with `latest` tag. Images that depend on previous repository internal images shall use the `staging` tag.

## License
[MIT](LICENSE) © [NikLeberg](https://github.com/NikLeberg).
