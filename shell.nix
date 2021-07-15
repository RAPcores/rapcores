
# nix RAPCore Development Environment

# params

{docs ? false}:


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

      # Python libs
      mach-nix.mach-nix
      (import ./nix/python/python.nix)
       ]
   ++ (lib.optional docs netlistsvg)
   ++ (lib.optional docs sphinx)
   ++ (lib.optional docs mach-nix.mach-nix)
   ++ (lib.optional docs (import ./nix/python/python.nix))
   ;

}