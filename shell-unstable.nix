
# nix.shell: RAPCore Development Environment
# Latest unstable nix-shell

with import <nixpkgs> {};

let

  # These are all the packages that will be available inside the nix-shell
  # environment.
  buildInputs = with pkgs;
    # these are generally useful packages for tests, verification, synthesis
    # and deployment, etc
    [ yosys verilog verilator symbiyosys nextpnr icestorm trellis
      yices tinyprog fujprog openocd
    ];

# For other formal modes, may need:
# z3 boolector

# Export a usable shell environment
in runCommand "rapcore-shell" { inherit buildInputs; } ""
