============
Arcus on AWS
============

This directory contains all AWS related code and infrastructure.

***************
Troubleshooting
***************

Sometimes after a crash etc.::

  terraform apply

an error like this will occur::

  aws_iam_instance_profile.grib-parse-instance-profile: Error creating IAM instance profile grib-parse-instance-profile: EntityAlreadyExists: Instance Profile grib-parse-instance-profile already exists.

Unfortunately the AWS console does not show instance profiles. In that case look for the profile and delete it::

  aws iam list-instance-profiles
  aws iam delete-instance-profile --instance-profile-name grib-parse-instance-profile
