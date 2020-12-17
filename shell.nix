
# nix.shell: RAPCore Development Environment

# Pin the nixpkgs to stable
with import (builtins.fetchTarball {
  # Descriptive name to make the store path easier to identify
  name = "nixos-unstable-2020-09";
  # Commit hash
  url = "https://github.com/NixOS/nixpkgs/archive/20.09.tar.gz";
  # Hash obtained using `nix-prefetch-url --unpack <url>`
  sha256 = "1wg61h4gndm3vcprdcg7rc4s1v3jkm5xd7lw8r2f67w502y94gcy";
}) {};

let

  # These are all the packages that will be available inside the nix-shell
  # environment.
  buildInputs = with pkgs;
    # these are generally useful packages for tests, verification, synthesis
    # and deployment, etc
    [ yosys verilog verilator symbiyosys nextpnr icestorm trellis
      z3 boolector yices tinyprog fujprog
    ];

# Export a usable shell environment
in runCommand "rapcore-shell" { inherit buildInputs; } ""
