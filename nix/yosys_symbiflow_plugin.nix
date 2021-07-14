{pkgs ? import (builtins.fetchTarball {
  # Descriptive name to make the store path easier to identify
  name = "nixos-2021-05";
  # Commit hash
  url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/21.05.tar.gz";
  # Hash obtained using `nix-prefetch-url --unpack <url>`
  sha256 = "1ckzhh24mgz6jd1xhfgx0i9mijk6xjqxwsshnvq789xsavrmsc36";
}) {}}:
pkgs.stdenv.mkDerivation rec {
  name = "yosys-symbiflow-plugins";
  version = "0.0.1";


  src = pkgs.fetchFromGitHub {
    owner  = "symbiflow";
    repo   = "yosys-symbiflow-plugins";
    rev    = "5d91d446535d0ae349fbdb49a6a2867c9f7f41ef";
    sha256 = "0gl5fmw1lslg11x2l8ph6qxlw10g0qrbazmk4px0a4dwh8k8i5j6";
  };


  buildInputs = [ pkgs.yosys pkgs.zlib pkgs.readline];
  nativeBuildInputs = [  ];

  doCheck = true;

  buildPhase = ''
    make plugins PLUGIN_LIST=fasm PLUGINS_DIR=$out/share/yosys/plugins
    make plugins PLUGIN_LIST=params PLUGINS_DIR=$out/share/yosys/plugins
    make plugins PLUGIN_LIST=sdc PLUGINS_DIR=$out/share/yosys/plugins
    make plugins PLUGIN_LIST=design_introspection PLUGINS_DIR=$out/share/yosys/plugins
  '';

  installPhase = ''
    mkdir -p $out/share/yosys/plugins
    install fasm-plugin/fasm.so $out/share/yosys/plugins
    install params-plugin/params.so $out/share/yosys/plugins
    install sdc-plugin/sdc.so $out/share/yosys/plugins
    install design_introspection-plugin/design_introspection.so $out/share/yosys/plugins
  '';

  meta = with pkgs.lib; {
    homepage = "https://symbiflow.github.io";
    description = "Plugins for Yosys developed as part of the SymbiFlow project.";
    platforms = platforms.linux;
  };
}