#!/bin/bash

export PYTHONHOME="/home/nao/System/Python-2.7.13"
export PATH="${PYTHONHOME}/bin:${PATH}"
export LD_LIBRARY_PATH="/home/nao/System/ros1_dependencies/lib:${PYTHONHOME}/lib:${LD_LIBRARY_PATH}"

source /home/nao/System/ros1_inst/setup.bash
