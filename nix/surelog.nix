{pkgs ? import (builtins.fetchTarball {
  # Descriptive name to make the store path easier to identify
  name = "nixos-2021-05";
  # Commit hash
  url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/21.05.tar.gz";
  # Hash obtained using `nix-prefetch-url --unpack <url>`
  sha256 = "1ckzhh24mgz6jd1xhfgx0i9mijk6xjqxwsshnvq789xsavrmsc36";
}) {}}:
pkgs.stdenv.mkDerivation rec {
  name = "surelog";
  version = "0.0.1";

  src = pkgs.fetchFromGitHub {
    owner  = "chipsalliance";
    repo   = "Surelog";
    rev    = "792de2fcc5f51d233dbb677ca6f1a1a05e483483";
    sha256 = "1iqqd887rqyr8qj2w9sy7bhad8fmgyzmh39gzspz2j67y0x5dfx3";
    fetchSubmodules = true;
  };



  buildInputs = with pkgs; [
      git
      stdenv.cc.cc
      cmake
      swig
      tcl
      jre8
      antlr4
      pkg-config
      libuuid
  ];
  nativeBuildInputs = [  ];

  buildPhase = ''
    echo $PWD; make SHELL=`which bash`
  '';

  installPhase = ''
    make install DESTDIR=$out
  '';

  meta = with pkgs.lib; {
    homepage = "https://chipsalliance.github.io/verible/";
    description = "SystemVerilog 2017 Pre-processor, Parser, Elaborator, UHDM Compiler. Provides IEEE Design/TB C/C++ VPI and Python AST API. ";
    platforms = platforms.linux;
  };
}