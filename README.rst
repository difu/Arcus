============
Arcus
============

Experimental GRIB Cloud Cache and Raster Data query platform

Aim of this project is to evaluate different technologies to analyze, distribute and share GRIB data.

It will use free data of `Deutscher Wetterdienst <http://www.dwd.de/>`_ at ftp://ftp-cdc.dwd.de/pub/REA/COSMO_REA6/

This project uses `eccodes <https://software.ecmwf.int/wiki/display/ECC/ecCodes+Home>`_ from ECMFW and `gdal <https://www.gdal.org>`_ for GRIB encoding/decoding.

================================
Quickstart
================================

Infrastructure
""""""""""""""

All infrastructure will be deployed on AWS. To install the AWS command line tools please refer to http://docs.aws.amazon.com/cli/latest/userguide/awscli-install-linux.html.
To create and modify the infrastructure `Terraform <https://www.terraform.io/>`_ is used. Download the ``terraform`` executable and take a look at the `getting started guide <https://www.terraform.io/intro/getting-started/install.html>`_.

- Create an AWS user and grant this user

  - AWS managed policies

    - SystemAdministrator
    - AmazonElasticFileSystemFullAccess
    - AmazonElasticMapReduceRole

  - Inline policy

  .. code-block:: json

    {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1500631120000",
            "Effect": "Allow",
            "Action": [
                "iam:CreatePolicy",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:CreateRole",
                "iam:AttachRolePolicy",
                "iam:CreateInstanceProfile",
                "iam:AddRoleToInstanceProfile",
                "iam:PassRole",
                "iam:DetachRolePolicy",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:DeleteInstanceProfile",
                "iam:DeleteRole",
                "iam:DeleteUserPolicy",
                "iam:DeletePolicy",
                "elasticmapreduce:RunJobFlow",
                "elasticmapreduce:DescribeCluster",
                "elasticmapreduce:TerminateJobFlows"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
    }


- Create a S3 bucket where Arcus stores its internal components etc. and name it like *my_internal_bucket*. Note that this bucket name must have an unique name. Remember that name as it is needed when you want to deploy the infrastructure.
- Download from Oracle OTN

  - oracle-instantclient18.3-basic-18.3.0.0.0-1.x86_64.rpm
  - oracle-instantclient18.3-sqlplus-18.3.0.0.0-1.x86_64.rpm
  - oracle-instantclient18.3-devel-18.3.0.0.0-1.x86_64.rpm

  and put the files under ``software/oracle/``

- Enter

  ``terraform init``

  ``terraform apply -var arcus_internal_bucket_name =`` *my_internal_bucket*

For further configuration see the ``variables.tf`` file in the terraform folder.
