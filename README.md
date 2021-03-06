## Introduction

This project contains a set of patches and scripts to compile and run ROS 1 and ROS 2 onboard a Pepper robot, without the need of a tethered computer.

## Pre-requirements

Download and extract the [NaoQi C++ framework](http://doc.aldebaran.com/2-5/index_dev_guide.html) and Softbanks's crosstool chain and point the `AL_DIR` and `ALDE_CTC_CROSS` environment variables to their respective paths:

```
export AL_DIR=/home/${USER}/NaoQi  <-- Or wherever you installed NaoQi
export ALDE_CTC_CROSS=$AL_DIR/ctc-linux64-atom-2.5.2.74
```

## Prepare cross-compiling environment

We're going to use Docker to set up a container that will compile all the tools for cross-compiling ROS and all of its dependencies. Go to https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository to install it for your Linux distribution.

1. Add your user to docker group and reboot
```
$ sudo usermod -aG docker $USER
$ sudo reboot -h now
```
2. Create a directory containing all Pepper projects, and set BASE_ROOT env to this directory
```
$ mkdir ~/pepper_root
$ echo 'export BASE_ROOT=${HOME}/pepper_root/' >> ~/.bashrc
$ cd pepper_root
```
3. Clone the project's repository, setting MAIN_ROOT
```
$ git clone https://gitlab.com/Intelligent-Robotics/ros2_pepper.git
$ echo 'export MAIN_ROOT=${BASE_ROOT}/ros2_pepper/' >> ~/.bashrc
$ cd ros2_pepper
```
4. Reload .bashrc
```
$ source ~/.bashrc
```

## ROS 1

### Prepare the requirements for ROS 1

The following script will create a Docker image and compile Python interpreters suitable for both the host and the robot.

```
./prepare_requirements_ros1.sh
```

### Build ROS 1 dependencies

Before we actually build ROS for Pepper, there's a bunch of dependencies we'll need to cross compile which are not available in Softbank's CTC:

- console_bridge
- poco
- tinyxml2
- urdfdom
- urdfdom_headers

```
./build_ros1_dependencies.sh
```

### Build ROS 1

Finally! Type the following, go grab a coffee and after a while you'll have an entire base ROS distro built for Pepper.

```
./build_ros1.sh
```

### Copy ROS and its dependencies to the robot

By now you should have the following inside .ros-root in the current directory:

- Python 2.7 built for Pepper (.ros-root/Python-2.7.13)
- All the dependencies required by ROS (.ros-root/ros1_dependencies)
- A ROS workspace with ROS Kinetic built for Pepper (.ros-root/ros1_inst)
- A helper script that will set up the ROS workspace in the robot (.ros-root/setup_ros1_pepper.bash)

We're going to copy these to the robot, assuming that your robot is connected to your network and you can ping your robot using pepper.local, type the following:

```
$ cd ~/pepper_root
$ ln -s ros2_pepper/deploy_in_robot.sh .
$ ./deploy_in_robot.sh [-sun (System, User, naoqi)] -- To the first deploy use -sun option
```

### Run ROS 1 from inside Pepper

Now that we have it all in the robot, let's give it a try:

*SSH into the robot*

```
$ ssh nao@IP_ADDRESS_OF_YOUR_ROBOT
```

*Source (not run) the setup script*

```
$ source System/setup.bash
```

*Start naoqi_driver, note that NETWORK\_INTERFACE may be either wlan0 or eth0, pick the appropriate interface if your robot is connected via wifi or ethernet*

```
$ roslaunch naoqi_driver naoqi_driver.launch nao_ip:=IP_ADDRESS_OF_YOUR_ROBOT \
    roscore_ip:=IP_ADDRESS_OF_YOUR_ROBOT network_interface:=NETWORK_INTERFACE
```

## ROS 2

BEWARE: The ROS 2 port is still experimental and incomplete, simple sensors such as the bumpers work, but the camera driver has not been ported yet.

The following instructions require that you have ROS 1 built for Pepper.

### Prepare the requirements for ROS 2

The following script will create a Docker image and compile Python interpreters suitable for both the host and the robot.

```
./prepare_requirements_ros2.sh
```

### Build ROS 2

Let's now build ROS 2 for Pepper:

```
./build_ros2.sh
```

### Copy ROS 2 and its dependencies to the robot

Besides the ROS 1 binaries and its dependencies, we'll now a few more directories inside .ros-root in our current directory:

- Python 3.6 built for Pepper (.ros-root/Python-3.6.1)
- A ROS 2 workspace built for Pepper (.ros-root/ros2_inst)

We're going to copy these to the robot, assuming that your robot is connected to your network, type the following:

```
$ scp -r .ros-root nao@IP_ADDRESS_OF_YOUR_ROBOT:.ros-root
```

### Run ROS 2 from inside Pepper

Now that we have it all in the robot, let's give it a try:

*SSH into the robot*

```
$ ssh nao@IP_ADDRESS_OF_YOUR_ROBOT
```

*Source (not run) the setup script*

```
$ source .ros-root/setup_ros2_pepper.bash
```

ROS 2 does not have a something like roslaunch yet, so you'll have to run naoqi_driver directly:

*Start naoqi_driver, note that NETWORK\_INTERFACE may be either wlan0 or eth0, pick the appropriate interface if your robot is connected via wifi or ethernet*

```
$ naoqi_driver_node --qi-url=tcp://IP_ADDRESS_OF_YOUR_ROBOT:9559 \
    --roscore_ip=IP_ADDRESS_OF_YOUR_ROBOT --network_interface=NETWORK_INTERFACE \
    --namespace=naoqi_driver
```

## Demos

The folks at the [Universidad Rey Juan Carlos](http://robotica.gsyc.es/) and [Intelligent Robotics](http://inrobots.es/) have produced the following video showing a Pepper robot runnning ROS onboard using the code from this repository:

[![Pepper Navigation](http://img.youtube.com/vi/0wIWJHMchaU/0.jpg)](https://www.youtube.com/watch?v=0wIWJHMchaU "Pepper Navigation")

Enjoy!
