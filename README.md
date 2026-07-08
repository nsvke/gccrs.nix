## UNMAINTAINED
# https://github.com/nsvke/gccrs/blob/gccrs-nix/contrib/nix/flake.nix

# gccrs.nix

A pure, reproducible, and strictly isolated development environment for [GCC Rust (gccrs)](https://github.com/Rust-GCC/gccrs).

## Prerequisites

- [Nix](https://nixos.org/download) (with Flakes enabled)
- _Optional but highly recommended:_ [direnv](https://direnv.net/)

## 🚀 Usage

You don't even need to clone `gccrs` manually. The environment handles the bootstrapping.

### The Standard Way

1.  Enter the development environment directly from GitHub (or clone this repo and run `nix develop`):

```bash
    nix develop github:nsvke/gccrs.nix
    # or
    git clone https://github.com/nsvke/gccrs.nix.git
    cd gccrs.nix
    nix develop
```

2. Run the setup script. This will clone the gccrs repository, configure the build system, and run the initial compilation:

```bash
gccrs-setup
```

(If you already have a gccrs folder, use `gccrs-setup --skip-clone`)

3. For subsequent incremental builds, just use:

```bash
gccrs-build
```

### The Direnv Way

If you want to avoid typing nix develop every time you work on the project:

1. Initialize the environment with the direnv flag:

```bash
nix develop github:nsvke/gccrs.nix
```

2. Run the setup script with `--use-direnv` flag:

```bash
gccrs-setup --use-direnv
```

3. Navigate into the newly created build directory and allow direnv:

```bash
cd build
direnv allow
```

Now, whenever you cd into the build/ directory, your terminal automatically loads the exact gccrs toolchain. When you cd out, your host environment is restored.

### 32-Bit Development

1. To compile and debug gccrs for a 32-bit target without cross-compilation linker conflicts:

```bash
nix develop github:nsvke/gccrs.nix#gcc32
# or
git clone https://github.com/nsvke/gccrs.nix.git
cd gccrs.nix
nix develop .#gcc32
```

2. Run the 32-bit setup:

```bash
gccrs-setup32
```

This automatically creates a build32/ directory, pulls a 32-bit rustc toolchain to compile proc_macros safely, and configures the build system with `--host=i686-pc-linux-gnu --build=i686-pc-linux-gnu` to bypass sanity check failures.

## Included Tools

_Note: If you are using the 32-bit environment, use the `32` suffixed versions of the setup and build commands._

- `gccrs-setup` (or `gccrs-setup32`) : Starts from scratch (clones, configures, and builds the compiler).
- `gccrs-setup --skip-clone` : Configures and builds using an existing `gccrs` folder.
- `gccrs-setup --use-direnv` : Automatically sets up direnv integration for the build environment.
- `gccrs-build` (or `gccrs-build32`) : Runs an incremental build (compiles only the changed files).
- `gccrs-build --bear` : Runs an incremental build and generates/updates `compile_commands.json` for LSP support (e.g., clangd).
- `gccrs-test [args...]` : Run gccrs testsuite.
- `gccrs-test --build [args...]` : Build and run gccrs testsuite.
- `gx <binary> [args...]` : Use built gccrs binaries.

The environment provides isolated wrappers around GCC's upstream `contrib` scripts to help you format commits and check code style.

- `gccrs-mklog` : Generates a GNU ChangeLog template for your currently STAGED files (`git add`).
- `gccrs-commit-mklog` : Generates the ChangeLog template and immediately opens the Git commit editor.
- `gccrs-verify [hash]` : Verifies the commit message format of `HEAD` (or a specific commit) against strict GNU standards.
- `gccrs-fix-changelog` : Attempts to automatically fix minor typographical or formatting errors in the ChangeLog of `HEAD`.
- `gccrs-style [hash]` : Checks the modifications in `HEAD` (or a specific commit) against the GNU C++ coding style guidelines.
