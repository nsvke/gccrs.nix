{
  description = "Reproducible Nix environment for GCC Rust (gccrs) development";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      gccrs-setup = pkgs.writeScriptBin "gccrs-setup" ''
        #!/usr/bin/env bash
        set -e

        ROOT_DIR="$PWD"
        SRC_DIR="$ROOT_DIR/gccrs"
        BUILD_DIR="$ROOT_DIR/build"
        INSTALL_DIR="$ROOT_DIR/install"

        SKIP_CLONE=false
        if [[ "''${1:-}" == "--ready" || "''${1:-}" == "-r" ]]; then
            SKIP_CLONE=true
        fi

        if [ -d "$SRC_DIR" ]; then
            if [ "$SKIP_CLONE" = true ]; then
                echo "Existing 'gccrs' directory found. Skipping clone as requested."
            else
                echo "Warning: '$SRC_DIR' already exists. Rename or remove it and rerun 'gccrs-setup'!"
                echo "If it's ready for build, run: 'gccrs-setup --ready'"
                exit 1
            fi
        else
            if [ "$SKIP_CLONE" = true ]; then
                echo "Warning: --ready flag used but '$SRC_DIR' not found!"
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
            --with-native-system-header-dir="$NIX_GLIBC_INCLUDE"

        make -j "$(nproc)" \
             WERROR="" \
             STRICT_FLAGS="" \
             CFLAGS="-Wno-error -Wno-format-security" \
             CXXFLAGS="-Wno-error -Wno-format-security"

        make install

        echo "Your gccrs build is ready!"
        echo "Use 'gccrs-build' or 'make' commands to compile it again."
      '';

      gccrs-build = pkgs.writeScriptBin "gccrs-build" ''
        #!/usr/bin/env bash
        set -e

        if [[ "$(basename "$PWD")" == "build" ]]; then
            BUILD_DIR="$PWD"
        else
            BUILD_DIR="$PWD/build"
            if [ ! -d "$BUILD_DIR" ]; then
                echo "Warning: 'build' folder does not exist. Run 'gccrs-setup' first."
                exit 1
            fi
            cd "$BUILD_DIR"
        fi

        make -j "$(nproc)" \
             WERROR="" \
             STRICT_FLAGS="" \
             CFLAGS="-Wno-error -Wno-format-security" \
             CXXFLAGS="-Wno-error -Wno-format-security" "$@"
      '';

      pythonEnv = pkgs.python3.withPackages (
        ps: with ps; [
          requests
          unidiff
          gitpython
        ]
      );

      gccrs-mklog = pkgs.writeShellApplication {
        name = "gccrs-mklog";
        runtimeInputs = [
          pkgs.git
          pythonEnv
        ];
        text = ''
          if [ ! -f "contrib/mklog.py" ]; then
              echo "Warning: 'contrib/mklog.py' not found! Use in 'gccrs' root folder."
              exit 1
          fi

          git diff --cached | python3 contrib/mklog.py -
        '';
      };

      gccrs-check-commit = pkgs.writeShellApplication {
        name = "gccrs-check-commit";
        runtimeInputs = [
          pkgs.git
          pythonEnv
        ];
        text = ''
          if [ ! -f "contrib/gcc-changelog/git_check_commit.py" ]; then
              echo "Warning: 'contrib/gcc-changelog/git_check_commit.py' not found. Use in 'gccrs' root folder."
              exit 1
          fi

          TARGET_COMMIT="''${1:-HEAD}"
          python3 contrib/gcc-changelog/git_check_commit.py "$TARGET_COMMIT"        '';
      };

    in
    {
      devShells.${system}.default = pkgs.mkShell {
        name = "gccrs-dev";

        packages = [
          gccrs-setup
          gccrs-build
          gccrs-mklog
          gccrs-check-commit
        ];

        nativeBuildInputs = with pkgs; [
          # compile dependices
          gnumake
          pkg-config
          autoconf
          automake
          m4
          flex
          bison
          texinfo
          ccache

          # test dependencies
          dejagnu
          expect
          tcl
          autogen
          check

          # debug dependencies
          gdb
          valgrind
          strace
        ];

        buildInputs = with pkgs; [
          gmp
          mpfr
          libmpc
          isl
          zlib
          zstd
          gettext
        ];

        shellHook = ''
          export GCCRS_INCOMPLETE_AND_EXPERIMENTAL_COMPILER_DO_NOT_USE="1"
          export NIX_GLIBC_INCLUDE="${pkgs.glibc.dev}/include"

          export LIBRARY_PATH="${pkgs.glibc}/lib"

          echo "🦀 GCC Rust (gccrs) Development Environment"
          echo "Run 'gccrs-setup' to start from scratch."
          echo "Run 'gccrs-setup --ready' if you already have the 'gccrs' folder."
          echo "Run 'gccrs-build' for incremental builds."
          echo "Run 'gccrs-mklog' to generate a changelog for your changes."
          echo "Run 'gccrs-check-commit' to verify your commits against GNU standards."
        '';
      };
    };
}
