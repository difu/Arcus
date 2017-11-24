============
Arcus
============

Experimental GRIB Cloud Cache and GRIB query platform

Aim of this project is to evaluate different technologies to analyze, distribute and share GRIB data.

It will use free data of `Deutscher Wetterdienst <http://www.dwd.de/>`_ at ftp://ftp-cdc.dwd.de/pub/REA/COSMO_REA6/

This project uses `eccodes <https://software.ecmwf.int/wiki/display/ECC/ecCodes+Home>`_ from ECMFW for GRIB encoding/decoding.

================================
Quickstart
================================

Infrastructure
""""""""""""""

All infrastructure will be deployed on AWS. To install the AWS command line tools please refer to http://docs.aws.amazon.com/cli/latest/userguide/awscli-install-linux.html.
To create and modify the infrastructure `Terraform <https://www.terraform.io/>`_ is used. Download the ``terraform`` executable and take a look at the `getting started guide <https://www.terraform.io/intro/getting-started/install.html>`_.

- Create a S3 bucket where Arcus stores its internal components etc. and name it like *my_internal_bucket*. Note that this bucket name must have an unique name. Remember that name as it is needed when you want to deploy the infrastructure.
- Download eccodes (e.g. ``eccodes-2.4.0-Source.tar.gz``) and put under ``software/eccodes``, which is the default location.
- Enter

    ``terraform init``

    ``terraform apply -var arcus_internal_bucket_name =`` *my_internal_bucket*

For further configuration see the ``variables.tf`` file in the terraform folder.
