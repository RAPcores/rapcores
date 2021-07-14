
# nix.shell: RAPCore Development Environment

# Pin the nixpkgs to stable
with (import ./nix/inputs.nix);

with import (./nix/npm/default.nix) {};

let 
verible = import ./nix/verible.nix { inherit pkgs; }; # TODO Upstream?

in pkgs.mkShell {
  buildInputs = with pkgs;
    [ 

      # Frontends
      yosys verilog verilator
      
      # Support
      svlint verible
      
      # Formal
      symbiyosys yices 

      # Bitstream Generation
      nextpnr icestorm trellis

      # Programming tools
      tinyprog fujprog openocd

      # Docs
      netlistsvg

      # Python libs
      mach-nix.mach-nix
      (import ./nix/python/python.nix)
       ];
}