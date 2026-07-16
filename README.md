## Standart
```bash 
git clone https://github.com/Rust-GCC/gccrs.git
nix develop "github:nsvke/gccrs/gccrs-nix?dir=contrib/nix" -c "gccrs-setup"
## using manual
nix develop "github:nsvke/gccrs/gccrs-nix?dir=contrib/nix"
# or
# nix develop "github:nsvke/gccrs/gccrs-nix?dir=contrib/nix#gprefix"
##
```

## With Direnv
```bash
git clone https://github.com/Rust-GCC/gccrs.git
nix develop "github:nsvke/gccrs/gccrs-nix?dir=contrib/nix" -c "gccrs-setup --use-direnv"
# or
# nix develop "github:nsvke/gccrs/gccrs-nix?dir=contrib/nix" -c "gccrs-setup --use-direnv --use-gprefix"
## using auto
```

## help
```txt
gccrs-setup                   : Start from scratch (configures, builds).
gccrs-setup --use-direnv      : Automatically setup direnv for your build folder.
gccrs-setup --use-gprefix     : Use prefix as 'g' instead of 'gccrs-'.
gccrs-build                   : Run incremental build (compiles only changes).
gccrs-build --bear            : Incremental build and update compile_commands.json.
gccrs-test <args...>          : Run gccrs testsuite.
gccrs-test --build <args...>  : Build and run gccrs testsuite.
gccrs-exec <binary> <args...> : Use built gccrs binaries.
gccrs-git <args...>           : Use git within the gccrs source directory.

gccrs-mklog                   : Generate ChangeLog template for STAGED files.
gccrs-commit-mklog            : Generate ChangeLog and open Git commit editor.
gccrs-verify                  : Verify your latest commit (HEAD) against GNU std.
gccrs-verify <hash>           : Verify a specific commit in your history.
gccrs-fix-changelog           : Attempt to fix minor format typos in HEAD.

gccrs-style                   : Check GNU C++ style for modifications in HEAD.
gccrs-style <hash>            : Check style for modifications in a specific commit.
```
