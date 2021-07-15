{pkgs ? import (builtins.fetchTarball {
  # Descriptive name to make the store path easier to identify
  name = "nixos-2021-05";
  # Commit hash
  url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/21.05.tar.gz";
  # Hash obtained using `nix-prefetch-url --unpack <url>`
  sha256 = "1ckzhh24mgz6jd1xhfgx0i9mijk6xjqxwsshnvq789xsavrmsc36";
}) {}}:
pkgs.stdenv.mkDerivation rec {
  name = "verible";
  version = "0.0.1";

  src = builtins.fetchTarball {
    url = "https://github.com/chipsalliance/verible/releases/download/v0.0-1298-g27add07/verible-v0.0-1298-g27add07-Ubuntu-20.10-groovy-x86_64.tar.gz";
    sha256 = "00mwallkvba6ip4gcwjy773mdwascz4q54g1fkzpasijvf7wgjc0";
  };

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
  ];

  buildInputs = [
    pkgs.stdenv.cc.cc
  ];

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share
    cp -r ${src}/bin $out
    cp -r ${src}/share $out
  '';

  meta = with pkgs.lib; {
    homepage = "https://chipsalliance.github.io/verible/";
    description = "SystemVerilog developer tools, including a parser, style-linter, and formatter.";
    platforms = platforms.linux;
  };
}