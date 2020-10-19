
# nix.shell: RAPCore Development Environment

with import <nixpkgs> {};

let

  # These are all the packages that will be available inside the nix-shell
  # environment.
  buildInputs = with pkgs;
    # these are generally useful packages for tests, verification, synthesis
    # and deployment, etc
    [ yosys symbiyosys nextpnr icestorm trellis
      z3 boolector yices tinyprog fujprog
    ];

# Export a usable shell environment
in runCommand "rapcore-shell" { inherit buildInputs; } ""
