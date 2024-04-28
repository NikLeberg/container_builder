# container_builder
This project uses the GitHub Actions CI to automatically build and push container images to the [GitHub registry](ghcr.io). The main goal of this is to prebuild CI or [devcontainer](https://containers.dev/) images for other projects. Otherwise the images of those projects would need to be rebuild every time on its own. With this it can just download the prebuilt image.

## Usage
GitHub registry:
- `docker pull ghcr.io/nikleberg/<image_name>:<image_tag>`

For specific usage of each image please have a look at the corresponding `README.md` file in the image subfolder.

## Adding images
Images are organised in subdirectories containing their respective files. To get the automatic CI system to build the image define a file `containers.json` like so:
```json
[
    {
        "name": "<folder_name>",
        "tag": "<image_tag>"
    }
]
```
This instructs the CI to build `<folder_name>/Dockerfile` as docker image, tag it as `ghcr.io/nikleberg/<folder_name>:<image_tag>` and push it to [ghcr.io](ghcr.io).

CI can do much more though. It can build multiple variants / tags from your `Dockerfile`, can build for multiple platforms, scan for vulnerabilities and handle dependencies between image variants.

### Image Variants
You may want to build an image in multiple variants. For example you may want to package `gcc` in different versions. For this you can define multiple image variants in the `containers.json` file:
```json
[
    {
        "name": "gcc",
        "tag": "13",
        "args": [
            "GCC_GIT_TAG=releases/gcc-13.2.0"
        ]
    },
    {
        "name": "gcc",
        "tag": "10",
        "args": [
            "GCC_GIT_TAG=releases/gcc-10.5.0"
        ]
    }
]
```
Inside your `Dockerfile` you can then use `ARG GCC_GIT_TAG` and you'll get the given arguments and can pull the correct version to build.

### Image Dependencies
Some images may depend on other images and extend them with additional functionality or tooling. For this, add the `<name>:<tag>` of said image as `dependsOn`. CI will then ensure that:
 1) the dependent is built after the dependency
 2) whenever the dependency is rebuilt, the dependent is also rebuilt

Example:

> File: `foo/containers.json`
```json
[
    {
        "name": "foo",
        "tag": "1.0"
    }
]
```

> File: `bar/containers.json`
```json
[
    {
        "name": "bar",
        "tag": "1.0",
        "dependsOn": "foo:1.0"
    }
]
```

This also works for the same collection of image variants, i.e. in the same `containers.json`. This lets you separate a base variant that is build before concrete implementations that build ontop of the base. For an example where this is used see [quartus](./quartus/containers.json). It specifies the `dockerfile` that the variant uses, sets the base-variants `intermediate` flag so that is not _released_ to the registry and specifies `dependsOn`.

In short:
```json
[
    {
        "name": "quartus",
        "tag": "18.1",
        "dockerfile": "base.dockerfile",
        "args": [
            "QUARTUS_VERSION=18.1"
        ],
        "intermediate": true
    },
    {
        "name": "quartus",
        "tag": "18.1-cycloneiv",
        "dockerfile": "device.dockerfile",
        "args": [
            "BASE_IMAGE_TAG=18.1",
        ],
        "dependsOn": "quartus:18.1"
    },
]
```

> Note: Even when setting `intermediate`, the image will still get pushed to the `ghcr.io` registry but with `-staging` appended to the tag. This is due to how the CI is setup. It builds and pushes the changes from GitHub PRs into images with `-staging` added. This allows other CI jobs to depend on it and test to be ran. On merge to the `main` branch the image is then built again but this time without the `-staging`. Setting `"intermediate": true` only prevents the last step, i.e. when the CI would push the merged PR without `-staging`.

> Note: Currently the CI only knows how to handle three levels of dependencies. If more are required the CI has to be extended first.

### Multi Platform
Thanks to [moby/buildkit](https://github.com/moby/buildkit) and the underlying [Qemu](https://www.qemu.org/) architecture virtualization, the CI can build your images for multiple architectures/platforms at once. See [here](https://github.com/tonistiigi/binfmt?tab=readme-ov-file#build-test-image) for a list of supported platforms.

To build your image for `amd64` and also `riscv64` add to your `containers.json`:
```json
[
    {
        ...
        "platforms": [
            "linux/amd64",
            "linux/riscv64"
            ...
        ]
        ...
    }
]
```

### Testing
Testing you images is an important step in ensuring they do or contain what you actually intend them to do. For this specify `testScript` with a path inside your `<image_name_folder>`. The script is ran after the staging version of your image has been built, so the tag know by docker will be `ghcr.io/nikleberg/<image_name>:<image_tag>-staging`. The script is called with the `<image_tag>` as its first argument.

```json
[
    {
        ...
        "testScript": "tests.sh"
        ...
    }
]
```

### CI Options
If you build a huge image, GitHub Actions may run out of disk space. For these image you can set `"maximizeBuildSpace": true` and the CI will try to free up as much space as possible beforehand.

[Trivy](https://github.com/aquasecurity/trivy) and [Dockle](https://github.com/goodwithtech/dockle) are scanners that detect vulnerabilities and bad practices in docker images respectively. They are ran by default on any image but can be disabled by setting `"trivySkip": true` or `"dockleSkip": true`. Reasons for disabling can be for example when the scanner step takes too much time and times-out the build, has too many false-positives or is just not providing any valuable insights. Dockle also scans the image filesystem for suspicious files. You may white-list file extensions that should not be treated as suspicious with `"dockleAcceptExt": <file_ext>`.

### `container.json` reference
```json
[
    {
        // Name of the image
        // required, must be identical to the folder this image is in
        "name": "name",
        // Tag of this image variant
        // required
        "tag": "1.2.3",
        // Dockerfile to use for building
        // optional, defaults so "Dockerfile"
        "dockerfile": "Dockerfile",
        // Build time arguments
        // optional
        "args": [
            "FOO=bar",
            "BAR=foo"
        ],
        // Immediate flag
        // optional, if set, the the image variant will never be pushed as "released" i.e. without "-staging"
        // Idea being here that you can build a "base" variant that other variants can depend and extend but the base variant won't get relased.
        "intermediate": true,
        // Dependency on other images or image variants
        // optional, use "<name>:<tag>" to form dependencies, only single-dependency allowed
        "dependsOn": "name:tag",
        // Maximize CI build space
        // optional, defaults to "false", large images may run out of diskspace in GitHub Actions, this tries to help
        "maximizeBuildSpace": false,
        // Test script ran after build
        // optional, gets called with <tag> as first argument to run tests on the just built image
        "testScript": "tests.sh",
        // Skip Trivy vulnerability scanner in CI
        // optional, defaults to "false"
        "trivySkip": false,
        // Skip Dockle scanner in CI
        // optional, defaults to "false"
        "dockleSkip": false,
        // White-List file extensions for dockle
        // optional, defaults to ""
        "dockleAcceptExt": ""
    },
    {
        ... // additional image variants / tags
    }
]
```

## License
[MIT](LICENSE) © [NikLeberg](https://github.com/NikLeberg).
