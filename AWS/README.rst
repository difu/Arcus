============
Arcus on AWS
============

This directory contains all AWS related code and infrastructure.

***************
Setup
***************

Python
""""""""""""""""""
Install Python requirements::

  pip install -r requirements.txt


Boto
""""""""""""""""""
Configure your AWS credentials in ``~/.boto``::

  [Credentials]
  aws_access_key_id = YOUR_ACCESS_KEY_ID
  aws_secret_access_key = YOUR_SECRET_ACCESS_KEY

Now test it with::

  ./ec2.py --list

**Note**: For debugging purpose it may be better to deactivate the cache ``cache_max_age`` in ``ec2.ini``

AWS cli
"""""""
run::

  aws configure

and provide credentials

SSH
""""""""""""""""""

All private ssh-keys will be stored in your ``~/.ssh/`` directory.

****
VPC
****

VPC, Subnets, Routing
"""""""""""""""""""""

Run the following playbook, to setup VPC::

  ansible-playbook -i ec2.y VPC.yml -e my_ip="INSERT_YOUR_IP_HERE"

the ``myip`` parameter configures the IP that is allowed to connect to the bastion host.
