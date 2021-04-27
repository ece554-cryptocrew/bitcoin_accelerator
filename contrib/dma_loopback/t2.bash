#!/bin/bash

# make the bash file executable
# chmod +x path-to-bash-file

# run bash file
# sh path-to-bash-file

export ASE_WORKDIR= <the path shown in your simulation window>
cd intel-training-modules/RTL/examples/dma_loopback
cd sw
make clean
make
./afu_ase 1024 1

