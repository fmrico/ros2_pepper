#!/bin/bash

set -euf -o pipefail

PYTHON3_VERSION=3.6.1

INSTALL_ROOT=System

if [ -z "$ALDE_CTC_CROSS" ]; then
  echo "Please define the ALDE_CTC_CROSS variable with the path to Aldebaran's Crosscompiler toolchain"
  exit 1
fi

docker build -t ros1-pepper -f docker/Dockerfile_ros1 docker/

if [ ! -e "Python-${PYTHON3_VERSION}.tar.xz" ]; then
  wget -cN https://www.python.org/ftp/python/$PYTHON3_VERSION/Python-${PYTHON3_VERSION}.tar.xz
  tar xvf Python-${PYTHON3_VERSION}.tar.xz
fi

mkdir -p ${PWD}/Python-${PYTHON3_VERSION}-host
mkdir -p ${PWD}/${INSTALL_ROOT}/Python-${PYTHON3_VERSION}


docker run -it --rm \
  -u $(id -u $USER) \
  -e PYTHON3_VERSION=${PYTHON3_VERSION} \
  -v ${PWD}/Python-${PYTHON3_VERSION}:/home/nao/Python-${PYTHON3_VERSION}-src \
  -v ${PWD}/Python-${PYTHON3_VERSION}-host:/home/nao/${INSTALL_ROOT}/Python-${PYTHON3_VERSION} \
  -v ${ALDE_CTC_CROSS}:/home/nao/ctc \
  -e CC \
  -e CPP \
  -e CXX \
  -e RANLIB \
  -e AR \
  -e AAL \
  -e LD \
  -e READELF \
  -e CFLAGS \
  -e CPPFLAGS \
  -e LDFLAGS \
  ros1-pepper \
  bash -c "\
    set -euf -o pipefail && \
    wget http://bzip.org/1.0.6/bzip2-1.0.6.tar.gz && \
    tar -xvf bzip2-1.0.6.tar.gz && \
    cd bzip2-1.0.6 && \
    make -f Makefile-libbz2_so && \
    make && \
    make install PREFIX=/home/nao/${INSTALL_ROOT}/Python-${PYTHON3_VERSION} && \
    cd .. && \
    mkdir -p Python-${PYTHON3_VERSION}-src/build-host && \
    cd Python-${PYTHON3_VERSION}-src/build-host && \
    export PATH=/home/nao/${INSTALL_ROOT}/Python-${PYTHON3_VERSION}/bin:$PATH && \
    ../configure \
      --prefix=/home/nao/${INSTALL_ROOT}/Python-${PYTHON3_VERSION} \
      --disable-ipv6 \
      ac_cv_file__dev_ptmx=yes \
      ac_cv_file__dev_ptc=no && \
    export LD_LIBRARY_PATH=/home/nao/ctc/openssl/lib:/home/nao/ctc/zlib/lib:/home/nao/${INSTALL_ROOT}/Python-${PYTHON3_VERSION}/lib && \
    make -j4 install && \
    wget -O - -q https://bootstrap.pypa.io/get-pip.py | /home/nao/${INSTALL_ROOT}/Python-${PYTHON3_VERSION}/bin/python3 && \
    /home/nao/${INSTALL_ROOT}/Python-${PYTHON3_VERSION}/bin/pip3 install empy catkin-pkg setuptools vcstool numpy rospkg defusedxml netifaces Twisted"

docker run -it --rm \
  -u $(id -u $USER) \
  -e PYTHON3_VERSION=${PYTHON3_VERSION} \
  -v ${PWD}/Python-${PYTHON3_VERSION}:/home/nao/Python-${PYTHON3_VERSION}-src \
  -v ${PWD}/${INSTALL_ROOT}/Python-${PYTHON3_VERSION}:/home/nao/${INSTALL_ROOT}/Python-${PYTHON3_VERSION} \
  -v ${PWD}/Python-${PYTHON3_VERSION}-host:/home/nao/Python-${PYTHON3_VERSION} \
  -v ${ALDE_CTC_CROSS}:/home/nao/ctc \
  ros1-pepper \
  bash -c "\
    set -euf -o pipefail && \
    mkdir -p Python-${PYTHON3_VERSION}-src/build-pepper && \
    cd Python-${PYTHON3_VERSION}-src/build-pepper && \
    export LD_LIBRARY_PATH=/home/nao/ctc/openssl/lib:/home/nao/ctc/zlib/lib:/home/nao/${INSTALL_ROOT}/Python-${PYTHON3_VERSION}/lib && \
    export PATH=/home/nao/Python-${PYTHON3_VERSION}/bin:$PATH && \
    ../configure \
      --prefix=/home/nao/${INSTALL_ROOT}/Python-${PYTHON3_VERSION} \
      --host=i686-aldebaran-linux-gnu \
      --build=x86_64-linux \
      --enable-shared \
      --disable-ipv6 \
      ac_cv_file__dev_ptmx=yes \
      ac_cv_file__dev_ptc=no && \
    make -j4 install && \
    wget -O - -q https://bootstrap.pypa.io/get-pip.py | /home/nao/${INSTALL_ROOT}/Python-${PYTHON3_VERSION}/bin/python3 && \
    /home/nao/${INSTALL_ROOT}/Python-${PYTHON3_VERSION}/bin/pip3 install empy catkin-pkg setuptools vcstool numpy rospkg defusedxml netifaces pymongo image && \
    cd .. && \
    wget https://twistedmatrix.com/Releases/Twisted/16.0/Twisted-16.0.0.tar.bz2 && \
    tar -xjvf Twisted-16.0.0.tar.bz2 && \
    cd Twisted-16.0.0 && \
    /home/nao/${INSTALL_ROOT}/Python-${PYTHON3_VERSION}/bin/python3 setup.py install"
