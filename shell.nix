
# nix RAPCore Development Environment

# params

{docs ? true,
 prog ? true}:


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

      # Support
      svlint verible
      
      # Formal
      symbiyosys yices 

      # Bitstream Generation
      nextpnr icestorm trellis

    ]
    ++ (lib.optional docs netlistsvg)
    ++ (lib.optional docs sphinx)
    ++ (lib.optional docs mach-nix.mach-nix)
    ++ (lib.optional docs (import ./nix/python/python.nix))
    ++ (lib.optional docs yosys_symbiflow_plugin)
    ++ (lib.optional prog tinyprog)
    ++ (lib.optional prog fujprog)
    ++ (lib.optional prog openocd)
    ;

}