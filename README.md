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

- `gccrs-setup` / `gccrs-setup32`: Bootstraps the workspace.

- `gccrs-build` / `gccrs-build32`: Context-aware make wrapper for incremental builds.

- `gccrs-mklog`: Wraps contrib/mklog.py to easily generate GNU-style changelogs from your staged git commits.

- `gccrs-check-commit`: Wraps contrib/gcc-changelog/git_check_commit.py to verify your commits against strict GNU standards before pushing.
