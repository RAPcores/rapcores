#! /usr/bin/bash

export INSTALL_DIR=$(realpath "quicklogic")
echo $INSTALL_DIR
wget https://github.com/QuickLogic-Corp/quicklogic-fpga-toolchain/releases/download/v1.3.1/Symbiflow_v1.3.1.gz.run
bash Symbiflow_v1.3.1.gz.run