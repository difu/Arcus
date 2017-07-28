#!/usr/bin/env bash

set -x
exec > /var/log/install_eccodes.log 2>&1

yum update -y
yum install gcc -y
yum install cmake -y
yum install libpng-devel -y


pip install numpy


aws s3 --region eu-central-1 cp s3://devel-arcus-internal/software/eccodes/eccodes-2.4.0-Source.tar.gz .
tar xf eccodes-2.4.0-Source.tar.gz
mkdir build ; cd build

cmake -DCMAKE_INSTALL_PREFIX=/opt/eccodes -DENABLE_FORTRAN=false -DENABLE_PYTHON=true -DENABLE_PNG=true ../eccodes-2.4.0-Source
make
make install
