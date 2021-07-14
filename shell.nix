
# nix.shell: RAPCore Development Environment

# Pin the nixpkgs to stable
with (import ./nix/inputs.nix);

with import (./nix/npm/default.nix) {};

let 
verible = import ./nix/verible.nix { inherit pkgs; }; # TODO Upstream?
yosys_symbiflow_plugin = import ./nix/yosys_symbiflow_plugin.nix { inherit pkgs; };

in pkgs.mkShell {
  buildInputs = with pkgs;
    [ 

      # Frontends
      yosys verilog verilator
      yosys_symbiflow_plugin

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
      sphinx

      # Python libs
      mach-nix.mach-nix
      (import ./nix/python/python.nix)
       ];

}