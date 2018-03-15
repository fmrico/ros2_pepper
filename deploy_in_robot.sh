#!/bin/bash
system=0
user=0
naoqi=0
help="Use [s] option to deploy System dir and [u] option to deploy User dir, ./deploy_in_robot.sh -[s,u]"
while getopts ":hsun" opt; do
    case "$opt" in
    s)
        system=1
        ;;
    u)  user=1
        ;;
    n)  naoqi=1
        ;;
    h)  echo $help
        exit 0
        ;;
    esac
done

if [ "$system" == 1 ]; then
  rsync -avzh ./System nao@pepper.local:~/
fi
if [ "$user" == 1 ]; then
  rsync -avzh ./User nao@pepper.local:~/
fi
if [ "$naoqi" == 1 ]; then
  naoqi_dir=$(find . -type d -name 'naoqi')
  rsync -avzh $naoqi_dir nao@pepper.local:~/
fi
if [ "$system" == 0 ] && [ "$user" == 0 ] && [ "$naoqi" == 0 ]; then
  echo $help
fi
