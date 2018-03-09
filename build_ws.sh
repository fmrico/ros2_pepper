#!/bin/bash
PYTHON2_MAJOR_VERSION=2
PYTHON2_MINOR_VERSION=7
PYTHON2_PATCH_VERSION=13

PYTHON3_MAJOR_VERSION=3
PYTHON3_MINOR_VERSION=6
PYTHON3_PATCH_VERSION=1

PYTHON2_VERSION=${PYTHON2_MAJOR_VERSION}.${PYTHON2_MINOR_VERSION}.${PYTHON2_PATCH_VERSION}
PYTHON3_VERSION=${PYTHON3_MAJOR_VERSION}.${PYTHON3_MINOR_VERSION}.${PYTHON3_PATCH_VERSION}

WORKSPACE=${1}
WORKSPACE_NAME=`basename ${WORKSPACE}`

echo "Compiling workspace ${WORKSPACE}"

if [ ! -d ${WORKSPACE} ]; then
  echo "Workspace ${WORKSPACE} does not exist"
  exit 1
fi

ROS1_INSTALL_ROOT=.ros-root

set -euf -o pipefail

if [ -z "$ALDE_CTC_CROSS" ]; then
  echo "Please define the ALDE_CTC_CROSS variable with the path to Aldebaran's Crosscompiler toolchain"
  exit 1
fi

if [ ! -d ${WORKSPACE}/cmake ]; then
  mkdir ${WORKSPACE}/cmake
fi
cp ctc-cmake-toolchain.cmake ${WORKSPACE}/cmake

if [ ! -d ${WORKSPACE}/src ]; then
  mkdir ${WORKSPACE}/src
fi

docker run -it --rm \
  -u $(id -u $USER) \
  -e PYTHON2_VERSION=${PYTHON2_VERSION} \
  -e PYTHON2_MAJOR_VERSION=${PYTHON2_MAJOR_VERSION} \
  -e PYTHON2_MINOR_VERSION=${PYTHON2_MINOR_VERSION} \
  -e PYTHON3_VERSION=${PYTHON3_VERSION} \
  -e ALDE_CTC_CROSS=/home/nao/ctc \
  -e WORKSPACE_NAME=$WORKSPACE_NAME \
  -e ROS1_INSTALL_ROOT=$ROS1_INSTALL_ROOT \
  -v ${PWD}/Python-${PYTHON2_VERSION}-host:/home/nao/${ROS1_INSTALL_ROOT}/Python-${PYTHON2_VERSION}:ro \
  -v ${PWD}/Python-${PYTHON2_VERSION}-host:/home/nao/Python-${PYTHON2_VERSION}-host:ro \
  -v ${PWD}/${ROS1_INSTALL_ROOT}/Python-${PYTHON2_VERSION}:/home/nao/${ROS1_INSTALL_ROOT}/Python-${PYTHON2_VERSION}-pepper:ro \
  -v ${PWD}/Python-${PYTHON3_VERSION}-host:/home/nao/${ROS1_INSTALL_ROOT}/Python-${PYTHON3_VERSION}:ro \
  -v ${PWD}/Python-${PYTHON3_VERSION}-host:/home/nao/Python-${PYTHON3_VERSION}-host:ro \
  -v ${PWD}/${ROS1_INSTALL_ROOT}/Python-${PYTHON3_VERSION}:/home/nao/${ROS1_INSTALL_ROOT}/Python-${PYTHON3_VERSION}-pepper:ro \
  -v ${ALDE_CTC_CROSS}:/home/nao/ctc:ro \
  -v ${PWD}/${ROS1_INSTALL_ROOT}/ros1_dependencies:/home/nao/${ROS1_INSTALL_ROOT}/ros1_dependencies:ro \
  -v ${PWD}/${ROS1_INSTALL_ROOT}/ros1_inst:/home/nao/${ROS1_INSTALL_ROOT}/ros1_inst:ro \
  -v ${WORKSPACE}:/home/nao/${WORKSPACE_NAME}:rw \
  ros1-pepper \
  bash -c "\
    set -euf -o pipefail && \
    export LD_LIBRARY_PATH=/home/nao/ctc/openssl/lib:/home/nao/ctc/zlib/lib:/home/nao/${ROS1_INSTALL_ROOT}/Python-${PYTHON2_VERSION}/lib && \
    export PATH=/home/nao/${ROS1_INSTALL_ROOT}/Python-${PYTHON2_VERSION}/bin:$PATH && \
    export PKG_CONFIG_PATH=/home/nao/${ROS1_INSTALL_ROOT}/ros1_dependencies/lib/pkgconfig && \
    source .ros-root/ros1_inst/setup.bash &
    cd ${WORKSPACE_NAME} && \
    vcs import src < *.repos && \
    catkin_make_isolated --install --install-space /home/nao/${WORKSPACE_NAME} -DCMAKE_BUILD_TYPE=Release \
    --cmake-args \
      -DWITH_QT=OFF \
      -DSETUPTOOLS_DEB_LAYOUT=OFF \
      -DCATKIN_ENABLE_TESTING=OFF \
      -DENABLE_TESTING=OFF \
      -DPYTHON_EXECUTABLE=/home/nao/${ROS1_INSTALL_ROOT}/Python-${PYTHON2_VERSION}/bin/python \
      -DPYTHON_LIBRARY=/home/nao/${ROS1_INSTALL_ROOT}/Python-${PYTHON2_VERSION}-pepper/lib/libpython${PYTHON2_MAJOR_VERSION}.${PYTHON2_MINOR_VERSION}.so \
      -DTHIRDPARTY=ON \
      -DCMAKE_TOOLCHAIN_FILE=/home/nao/navigation_ws/cmake/ctc-cmake-toolchain.cmake \
      -DALDE_CTC_CROSS=/home/nao/ctc \
      -DCMAKE_PREFIX_PATH=\"/home/nao/${ROS1_INSTALL_ROOT}\" \
      -DCMAKE_FIND_ROOT_PATH=\"/home/nao/${ROS1_INSTALL_ROOT}/Python-${PYTHON2_VERSION}-pepper;/home/nao/${ROS1_INSTALL_ROOT}/ros1_dependencies;/home/nao/${WORKSPACE};/home/nao/ctc\" \
    "
