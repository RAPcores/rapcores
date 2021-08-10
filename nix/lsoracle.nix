{pkgs ? import (builtins.fetchTarball {
  # Descriptive name to make the store path easier to identify
  name = "nixos-2021-05";
  # Commit hash
  url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/21.05.tar.gz";
  # Hash obtained using `nix-prefetch-url --unpack <url>`
  sha256 = "1ckzhh24mgz6jd1xhfgx0i9mijk6xjqxwsshnvq789xsavrmsc36";
}) {}}:
pkgs.stdenv.mkDerivation rec {
  name = "lsoracle";
  version = "0.0.1";

  src = pkgs.fetchFromGitHub {
    owner  = "lnis-uofu";
    repo   = "LSOracle";
    rev    = "21688c5d542740dfc8577349fa615ee655acd92c";
    sha256 = "1s0hp6wri7hwzgi03h4k63xfhv7a8ic0mhify49ff8ikchbl7908";
  };

  buildInputs = with pkgs; [
    boost
    cmake
    python3
    readline
  ];
  nativeBuildInputs = [  ];

  preConfigure = ''
    mkdir build
    cd build
    cmake .. -DCMAKE_BUILD_TYPE=RELEASE -DINSTALL_PREFIX=$out
  '';

  buildPhase = ''
    cd ..
    echo pwd: $PWD; make
  '';

  installPhase = ''
    make install
  '';

  meta = with pkgs.lib; {
    homepage = "https://github.com/lnis-uofu/LSOracle";
    description = "The Logic Synthesis oracle unlocks efficient logic manipulation.";
    platforms = platforms.linux;
  };
}