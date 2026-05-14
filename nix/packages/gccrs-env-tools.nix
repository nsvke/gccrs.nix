{
  writeScriptBin,
  symlinkJoin,
  is32Bit,
}:

let
  buildDirName = if is32Bit then "build32" else "build";
  installDirName = if is32Bit then "install32" else "install";
  setupName = if is32Bit then "gccrs-setup32" else "gccrs-setup";
  buildName = if is32Bit then "gccrs-build32" else "gccrs-build";

  gccrs-setup = writeScriptBin setupName ''
    #!/usr/bin/env bash
    set -e

    ROOT_DIR="$PWD"
    SRC_DIR="$ROOT_DIR/gccrs"
    BUILD_DIR="$ROOT_DIR/${buildDirName}"
    INSTALL_DIR="$ROOT_DIR/${installDirName}"

    SKIP_CLONE=false
    SETUP_DIRENV=false

    for arg in "$@"; do
      case $arg in
        --skip-clone) SKIP_CLONE=true ;;
        --use-direnv) SETUP_DIRENV=true ;;
      esac
    done

    if [ -d "$SRC_DIR" ]; then
        if [ "$SKIP_CLONE" = true ]; then
            echo "Existing 'gccrs' directory found. Skipping clone as requested."
        else
            echo "Warning: '$SRC_DIR' already exists. Rename or remove it and rerun '${setupName}'!"
            echo "If it's ready for build, run: 'gccrs-setup --skip-clone'"
            exit 1
        fi
    else
        if [ "$SKIP_CLONE" = true ]; then
            echo "Warning: --skip-clone flag used but '$SRC_DIR' not found!"
            exit 1
        fi
        git clone https://github.com/Rust-GCC/gccrs.git
    fi

    export CC="ccache gcc"
    export CXX="ccache g++"
    export CFLAGS="-g -O0"
    export CXXFLAGS="-g -O0"

    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    "$SRC_DIR/configure" \
        --prefix="$INSTALL_DIR" \
        --disable-bootstrap \
        --enable-valgrind-annotations \
        --enable-languages=rust \
        --disable-multilib \
        --with-native-system-header-dir="$NIX_GLIBC_INCLUDE" \
        --disable-libatomic \
        --disable-libgomp \
        --disable-libquadmath \
        --disable-libssp \
        --disable-libvtv \
        --disable-libitm \
        --disable-libsanitizer \
        ${if is32Bit then "--host=i686-pc-linux-gnu --build=i686-pc-linux-gnu" else ""}

    bear -- make -j "$(nproc)" \
         WERROR="" \
         STRICT_FLAGS="" \
         CFLAGS="-Wno-error -Wno-format-security" \
         CXXFLAGS="-Wno-error -Wno-format-security"

    # make install

    if [ ! -e "$SRC_DIR/compile_commands.json" ] && [ -f "$BUILD_DIR/compile_commands.json" ]; then
      ln -sf "$BUILD_DIR/compile_commands.json" "$SRC_DIR/compile_commands.json"
    fi

    if [ ! -f "$SRC_DIR/.clangd" ]; then
      cat <<EOF > "$SRC_DIR/.clangd"
CompileFlags:
  Remove: [ccache]
EOF
    fi

    if [ ! -f "$SRC_DIR/.clang-format" ] && [ -f "$SRC_DIR/contrib/clang-format" ]; then
      ln -sf "$SRC_DIR/contrib/clang-format" "$SRC_DIR/.clang-format"
    fi
    
    if [ "$SETUP_DIRENV" = true ]; then
      ${
        if is32Bit then
          ''
            if [ -f "$ROOT_DIR/flake.nix" ]; then
                echo "use flake \"../#gcc32\"" > "$BUILD_DIR/.envrc"
            elif [ -f "$ROOT_DIR/gccrs.nix/flake.nix" ]; then
                echo "use flake \"../gccrs.nix/#gcc32\"" > "$BUILD_DIR/.envrc"
            else
                echo "use flake \"github:nsvke/gccrs.nix#gcc32\"" > "$BUILD_DIR/.envrc"
            fi
            echo "Run 'direnv allow' inside '${buildDirName}' to activate 32-bit direnv."
          ''
        else
          ''
            if [ -f "$ROOT_DIR/flake.nix" ]; then
                echo "use flake \".\"" > "$ROOT_DIR/.envrc"
            elif [ -f "$ROOT_DIR/gccrs.nix/flake.nix" ]; then
                echo "use flake \"./gccrs.nix/.\"" > "$ROOT_DIR/.envrc"
            else
                echo "use flake \"github:nsvke/gccrs.nix\"" > "$ROOT_DIR/.envrc"
            fi
            echo "Run 'direnv allow' inside your project root to activate 64-bit direnv."
          ''
      }
    fi

    echo "Your gccrs build is ready!"
    echo "Use '${buildName}' or 'make' commands to compile it again."
  '';

  gccrs-build = writeScriptBin buildName ''
    #!/usr/bin/env bash
    set -e

    if [[ "$(basename "$PWD")" == "${buildDirName}" ]]; then
        BUILD_DIR="$PWD"
    else
        BUILD_DIR="$PWD/${buildDirName}"
        if [ ! -d "$BUILD_DIR" ]; then
            echo "Warning: '${buildDirName}' folder does not exist. Run '${setupName}' first."
            exit 1
        fi
        cd "$BUILD_DIR"
    fi

    USE_BEAR=false
    if [[ "$1" == "--bear" ]]; then
      USE_BEAR=true
      shift
    fi

    if [ "$USE_BEAR" = true ]; then
      bear --append -- make -j "$(nproc)" \
           WERROR="" \
           STRICT_FLAGS="" \
           CFLAGS="-Wno-error -Wno-format-security" \
           CXXFLAGS="-Wno-error -Wno-format-security" "$@"
    else
      make -j "$(nproc)" \
           WERROR="" \
           STRICT_FLAGS="" \
           CFLAGS="-Wno-error -Wno-format-security" \
           CXXFLAGS="-Wno-error -Wno-format-security" "$@"
    fi
  '';

  gccrs-help = writeScriptBin "gccrs-help" ''
    #!/usr/bin/env bash

    echo "  ${setupName}                  : Start from scratch (clones, configures, builds).    "
    echo "  ${setupName} --skip-clone     : Configure and build an existing 'gccrs' folder.     "
    echo "  ${setupName} --use-direnv     : Automatically setup direnv for your build folder.   "
    echo "  ${buildName}                  : Run incremental build (compiles only changes).      "
    echo "  ${buildName} --bear           : Incremental build and update compile_commands.json. "
    echo ""
    echo "  gccrs-mklog                  : Generate ChangeLog template for STAGED files.        "
    echo "  gccrs-commit-mklog           : Generate ChangeLog and open Git commit editor.       "
    echo "  gccrs-verify                 : Verify your latest commit (HEAD) against GNU std.    "
    echo "  gccrs-verify <hash>          : Verify a specific commit in your history.            "
    echo "  gccrs-fix-changelog          : Attempt to fix minor format typos in HEAD.           "
    echo ""
    echo "  gccrs-style                  : Check GNU C++ style for modifications in HEAD.       "
    echo "  gccrs-style <hash>           : Check style for modifications in a specific commit.  "
  '';
in
symlinkJoin {
  name = "gccrs-env-tools-${if is32Bit then "32" else "64"}";
  paths = [
    gccrs-setup
    gccrs-build
    gccrs-help
  ];
}
