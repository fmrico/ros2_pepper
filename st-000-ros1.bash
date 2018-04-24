#!/bin/bash

export PYTHONHOME="/home/nao/System/Python-2.7.13"
export PATH="${PYTHONHOME}/bin:${PATH}"
export LD_LIBRARY_PATH="/home/nao/System/ros1_dependencies/lib:${PYTHONHOME}/lib:${LD_LIBRARY_PATH}"

export ROS_HOSTNAME=pepper.local
export ROS_IP=10.108.53.9
export ROS_MASTER_URI=http://pepper.local:11311

source /home/nao/System/ros1_inst/setup.bash
