
with (import ./inputs.nix);
pkgs.mkShell {
  buildInputs = [
    mach-nix.mach-nix
    (import ./python.nix)
  ];
}
