# Smollinux!

**Smollinux!** is a simple and extensible build system for creating a custom Linux distribution from scratch. It is designed to be easy to understand and modify, making it a great tool for learning how a Linux system is built.

## Features

-   **Package-based**: The system is built around packages. Each software component is defined in a simple `.pkg` file.
-   **Content-aware caching**: The build system is fast. It uses a sophisticated caching mechanism that tracks changes to package definitions and source files, so it only rebuilds what is necessary.
-   **Extensible**: Adding new software to your custom Linux distribution is as simple as creating a new package file.
-   **Minimalistic**: The goal of Smollinux! is to be small and simple, but also a great base to build upon.

## Getting Started

### Prerequisites

-   A Linux environment.
-   Standard build tools (`gcc`, `make`, `curl`, etc.).
-   `jq` for parsing JSON.

### Building Smollinux!

1.  **Clone the repository:**

    ```bash
    git clone <repository-url>
    cd smollinux-r1
    ```

2.  **Clean the build environment (optional):**

    To start from a clean slate, you can remove all previous build artifacts.

    ```bash
    ./smolpkg clean
    ```

3.  **Build the initramfs:**

    The main goal is to build an `initramfs.cpio.gz` file, which can be used to boot a Linux kernel.

    First, you need to build and install the base packages into a staging directory.

    ```bash
    # Install the base layout and busybox
    ./smolpkg install initramfs-base busybox --target initramfs
    ```

    Then, you can create the initramfs image:

    ```bash
    # Package the initramfs directory into an image
    ./smolpkg mkinitramfsimg --target initramfs
    ```

    The final image will be located at `build/initramfs.cpio.gz`.

### Forcing a rebuild

If you need to force a rebuild of a package, bypassing the cache, you can use the `--force` flag:

```bash
./smolpkg install <package-name> --force
```

## How it Works

Smollinux! is a collection of shell scripts that automate the process of building a Linux system. The main script is `smolpkg`, which acts as a package manager.

### Packages

Each software component is defined by a `.pkg` file in the `packages/` directory. These files contain the necessary information to download, configure, build, and install the software.

### Caching

To make the build process fast and efficient, Smollinux! uses a content-aware caching system. It stores hashes of package definitions, downloaded files, and even the output directory tree in a `build/cache.json` file. This ensures that no work is repeated unnecessarily.

## How to Contribute

Contributions are welcome! If you want to improve Smollinux!, please feel free to fork the repository, make your changes, and submit a pull request.

Here are some ideas for contributions:

-   Add more packages.
-   Improve the build scripts.
-   Write more documentation.

## License

This project is licensed under the GNU General Public License v3.0. See the `LICENSE` file for details.
## Thank You

A special thank you to everyone who has contributed to this project and to the open-source community for providing the tools and software that make this project possible.

A very special thank you to myself (devonjeff) and AI models for helping me making this project.