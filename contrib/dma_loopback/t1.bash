#!/bin/bash

# make the bash file executable
# chmod +x path-to-bash-file

# run bash file
# sh path-to-bash-file

rm -rf sim
git pull
afu_sim_setup -t VCS --source hw/filelist.txt sim
cd sim
make
make sim
[SIM]  bash/zsh | export ASE_WORKDIR=/filespace/m/mikko/intel-training-modules/RTL/examples/dma_loopback/sim/work

