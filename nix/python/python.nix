
with (import ../inputs.nix);
mach-nix.mkPython {
  requirements = builtins.readFile ../../docs/requirements.txt;
}
