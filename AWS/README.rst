============
Arcus on AWS
============

This directory contains all AWS related code and infrastructure.

***************
Setup
***************

Boto
""""""""""""""""""
Configure your AWS credentials in ``~/.boto``::

  [Credentials]
  aws_access_key_id = YOUR_ACCESS_KEY_ID
  aws_secret_access_key = YOUR_SECRET_ACCESS_KEY

Now test it with::

  ./ec2.py --list

**Note**: For debugging purpose it may be better to deactivate the cache ``cache_max_age`` in ``ec2.ini``

SSH
""""""""""""""""""

All private ssh-keys will be stored in your ``~/.ssh/`` directory.