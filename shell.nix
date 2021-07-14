
# nix.shell: RAPCore Development Environment

# Pin the nixpkgs to stable
with import (builtins.fetchTarball {
  # Descriptive name to make the store path easier to identify
  name = "nixos-2021-05";
  # Commit hash
  url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/21.05.tar.gz";
  # Hash obtained using `nix-prefetch-url --unpack <url>`
  sha256 = "1ckzhh24mgz6jd1xhfgx0i9mijk6xjqxwsshnvq789xsavrmsc36";
}) {};

with import (./nix/npm/default.nix) {};

pkgs.mkShell {
  # These are all the packages that will be available inside the nix-shell
  # environment.
  buildInputs = with pkgs;
    # these are generally useful packages for tests, verification, synthesis
    # and deployment, etc
    [ yosys verilog verilator svlint symbiyosys nextpnr icestorm trellis
      yices tinyprog fujprog openocd
      netlistsvg
       ];
}