
# nix RAPCore Development Environment

# params

{docs ? false,
 prog ? true,
 svng ? false}:


# Pin the nixpkgs to stable
with (import ./nix/inputs.nix);

with import (fetchGit {
    url = "https://github.com/RAPcores/nix-rapcores-support.git";
    rev = "5ac21598b927af16b2d6600cfa9d6ed9dc1b712c";}) {};

let 
verible = import ./nix/verible.nix { inherit pkgs; }; # TODO Upstream?
yosys_symbiflow_plugin = import ./nix/yosys_symbiflow_plugin.nix { inherit pkgs; };
lsoracle = import ./nix/lsoracle.nix { inherit pkgs; }; # TODO Upstream?

in pkgs.mkShell {
  buildInputs = with pkgs;
    [ 

      # Frontends
      yosys verilog verilator

      # Support
      verible
      
      # Formal
      symbiyosys yices 

      # Bitstream Generation
      nextpnr icestorm trellis

    ]
    # ++ (lib.optional docs netlistsvg)
    ++ (lib.optional docs python38Packages.cairocffi)
    ++ (lib.optional docs jsteros)
    ++ (lib.optional docs mach-nix.mach-nix)
    ++ (lib.optional docs (import ./nix/python/python.nix))
    # ++ (lib.optional docs yosys_symbiflow_plugin)
    ++ (lib.optional prog tinyprog)
    ++ (lib.optional prog fujprog)
    ++ (lib.optional prog openocd)
    ++ (lib.optional svng lsoracle)
    ;

}