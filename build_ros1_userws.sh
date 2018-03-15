#!/bin/bash
PYTHON2_MAJOR_VERSION=2
PYTHON2_MINOR_VERSION=7
PYTHON2_PATCH_VERSION=13

PYTHON3_MAJOR_VERSION=3
PYTHON3_MINOR_VERSION=6
PYTHON3_PATCH_VERSION=1

PYTHON2_VERSION=${PYTHON2_MAJOR_VERSION}.${PYTHON2_MINOR_VERSION}.${PYTHON2_PATCH_VERSION}
PYTHON3_VERSION=${PYTHON3_MAJOR_VERSION}.${PYTHON3_MINOR_VERSION}.${PYTHON3_PATCH_VERSION}

INSTALL_ROOT=System

set -eu -o pipefail

package=""
package_option=""
workspace=""

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --pkg|--package)
    package="$2"
    shift
    shift
    ;;
    -w|--workspace)
    workspace="$2"
    shift
    shift
    ;;
esac
done

if [ -z "$ALDE_CTC_CROSS" ]; then
  echo "Please define the ALDE_CTC_CROSS variable with the path to Aldebaran's Crosscompiler toolchain"
  exit 1
fi

if [ ! -d User ]; then
  mkdir -p User
fi

if [ "$package" == ""  ]; then
  cp -rf $workspace User
else
  package_option="--pkg $package"
fi

cd User
for i in *_ws
do
  echo "Processing $i"
  cd $i
  mkdir -p cmake
  cp ../../ctc-cmake-toolchain.cmake .
  cp ../../cmake/eigen3-config.cmake ./cmake/
  SYSTEM_DIR=${PWD}/../..

  docker run -it --rm \
  	-e PYTHON2_VERSION=${PYTHON2_VERSION} \
  	-e PYTHON2_MAJOR_VERSION=${PYTHON2_MAJOR_VERSION} \
  	-e PYTHON2_MINOR_VERSION=${PYTHON2_MINOR_VERSION} \
  	-e PYTHON3_VERSION=${PYTHON3_VERSION} \
  	-e ALDE_CTC_CROSS=/home/nao/ctc \
  	-e PKG_CONFIG_PATH=/home/nao/${INSTALL_ROOT}/ros1_dependencies/lib/pkgconfig \
  	-v ${SYSTEM_DIR}/Python-${PYTHON2_VERSION}-host:/home/nao/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}:ro \
  	-v ${SYSTEM_DIR}/Python-${PYTHON2_VERSION}-host:/home/nao/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}-host:ro \
  	-v ${SYSTEM_DIR}/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}:/home/nao/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}-pepper:ro \
  	-v ${SYSTEM_DIR}/Python-${PYTHON3_VERSION}-host:/home/nao/${INSTALL_ROOT}/Python-${PYTHON3_VERSION}:ro \
  	-v ${SYSTEM_DIR}/Python-${PYTHON3_VERSION}-host:/home/nao/${INSTALL_ROOT}/Python-${PYTHON3_VERSION}-host:ro \
  	-v ${SYSTEM_DIR}/${INSTALL_ROOT}/Python-${PYTHON3_VERSION}:/home/nao/${INSTALL_ROOT}/Python-${PYTHON3_VERSION}-pepper:ro \
  	-v ${ALDE_CTC_CROSS}:/home/nao/ctc:ro \
  	-v ${SYSTEM_DIR}/${INSTALL_ROOT}/ros1_dependencies:/home/nao/${INSTALL_ROOT}/ros1_dependencies:ro \
  	-v ${SYSTEM_DIR}/pepper_ros1_ws:/home/nao/${INSTALL_ROOT}/pepper_ros1_ws \
  	-v ${PWD}:/home/nao/User/${i} \
    -v ${SYSTEM_DIR}/${INSTALL_ROOT}/setup_ros1_pepper.bash:/home/nao/${INSTALL_ROOT}/setup_ros1_pepper.bash:ro \
    -v ${SYSTEM_DIR}/${INSTALL_ROOT}/ros1_inst:/home/nao/${INSTALL_ROOT}/ros1_inst:ro \
  	ros1-pepper \
  	bash -c "\
    export LD_LIBRARY_PATH=/home/nao/ctc/openssl/lib:/home/nao/ctc/zlib/lib:/home/nao/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}/lib && \
    export PATH=/home/nao/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}/bin:$PATH && \
    source ${INSTALL_ROOT}/setup_ros1_pepper.bash && \
    cd User/$i && \
    catkin_make $package_option -DCMAKE_BUILD_TYPE=Release \
    --cmake-args \
    -DWITH_QT=OFF \
    -DSETUPTOOLS_DEB_LAYOUT=OFF \
    -DCATKIN_ENABLE_TESTING=OFF \
    -DENABLE_TESTING=OFF \
    -DPYTHON_EXECUTABLE=/home/nao/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}/bin/python \
    -DPYTHON_LIBRARY=/home/nao/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}-pepper/lib/libpython${PYTHON2_MAJOR_VERSION}.${PYTHON2_MINOR_VERSION}.so \
    -DTHIRDPARTY=ON \
    -DCMAKE_TOOLCHAIN_FILE=/home/nao/${INSTALL_ROOT}/pepper_ros1_ws/ctc-cmake-toolchain.cmake \
    -DALDE_CTC_CROSS=/home/nao/ctc \
    -DCMAKE_PREFIX_PATH=/home/nao/${INSTALL_ROOT}/ros1_inst \
    -DCMAKE_FIND_ROOT_PATH=\"/home/nao/${INSTALL_ROOT}/Python-${PYTHON2_VERSION}-pepper;/home/nao/${INSTALL_ROOT}/ros1_dependencies;/home/nao/${INSTALL_ROOT}/ros1_inst;/home/nao/ctc\" \
    "
    cd ../
  done
