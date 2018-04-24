#!/bin/bash

for script_file in $(ls /home/nao/System/startup_scripts|sort); do
  echo $script_file
  source /home/nao/System/startup_scripts/${script_file}
done
