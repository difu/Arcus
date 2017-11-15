#!/usr/bin/env bash

set -x
exec > /var/log/install_eccodes.log 2>&1

yum update -y
yum install gcc -y
yum install cmake -y
yum install libpng-devel -y


pip install numpy


aws s3 --region eu-central-1 cp s3://${internal_bucket_name}/${eccodes_path}/${eccodes_version}.tar.gz .
tar xf ${eccodes_version}.tar.gz
mkdir build ; cd build

cmake -DCMAKE_INSTALL_PREFIX=/opt/eccodes -DENABLE_FORTRAN=false -DENABLE_PYTHON=true -DENABLE_PNG=true ../${eccodes_version}
make
make install
