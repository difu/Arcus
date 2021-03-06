#!/usr/bin/env bash

set -x
exec > /var/log/bootstrap_all.log 2>&1


cd /tmp


if grep -q "Amazon Linux AMI" /etc/os-release; then
    echo "Running on Amazon Linux"
else
    echo "Running not an Amazon Linux, assuming centos. Installing aws cli first"
    curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
    yum -y install unzip wget
    unzip awscli-bundle.zip
    ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

fi

yum upgrade -y
yum install -y git
yum -y groupinstall "Development Tools"


REGION=`wget -qO- http://instance-data/latest/meta-data/placement/availability-zone | sed 's/.$//'`
FSID=`aws efs describe-file-systems --region $$REGION --output=text | awk '{ print $5 }'`
INSTANCE_ID=`wget -qO- http://instance-data/latest/meta-data/instance-id`
MYIP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`


echo "Region: $REGION FSID $FSID INSTANCE_ID $INSTANCE_ID"


# mount shared efs storage on each instance
EFS_MOUNT_POINT="/mnt/efs"
echo "mounting efs $FSID on $EFS_MOUNT_POINT"

mkdir -p $EFS_MOUNT_POINT
mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $FSID.efs.$REGION.amazonaws.com:/ $EFS_MOUNT_POINT
chmod 777 $EFS_MOUNT_POINT
cd /tmp

aws ec2 describe-tags --region $${REGION} --filter "Name=resource-id,Values=$INSTANCE_ID" --output=text | sed -r 's/TAGS\t(.*)\t.*\t.*\t(.*)/\1="\2"/' > ec2-tags

SW=`cat ec2-tags | sed -E -n "s/software=\"(.+)\"/\1/p"`
array=( $SW )
for i in "$${array[@]}" # $$ Terraform escaping
do
    case $i in
    docker)
        yum install -y docker
        service docker start
        usermod -a -G docker ec2-user
        curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        ;;
    eccodes)
        echo "Installing eccodes"
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
        ;;
    gdal)
        echo "Installing gdal"
        ;;
    oracleclient)
        echo "Installing Oracle Client"
        aws s3 --region eu-central-1 cp s3://${internal_bucket_name}/software/oracle/oracle-instantclient18.3-basic-18.3.0.0.0-1.x86_64.rpm .
        aws s3 --region eu-central-1 cp s3://${internal_bucket_name}/software/oracle/oracle-instantclient18.3-sqlplus-18.3.0.0.0-1.x86_64.rpm .
        aws s3 --region eu-central-1 cp s3://${internal_bucket_name}/software/oracle/oracle-instantclient18.3-devel-18.3.0.0.0-1.x86_64.rpm .

        rpm -i oracle-instantclient18.3-basic-18.3.0.0.0-1.x86_64.rpm
        rpm -i oracle-instantclient18.3-sqlplus-18.3.0.0.0-1.x86_64.rpm
        rpm -i oracle-instantclient18.3-devel-18.3.0.0.0-1.x86_64.rpm

        ;;
    oracledb)
        echo "vm.nr_hugepages = 46" >> /etc/sysctl.conf
        sysctl -p
        yum -y install wget install bc bind-utils compat-libcap1 compat-libstdc++-33 glibc-devel ksh libaio libaio-devel libstdc++-devel psmisc smartmontools sysstat xorg-x11-utils xorg-x11-xauth
        aws s3 --region eu-central-1 cp s3://${internal_bucket_name}/software/oracle/oracle-database-preinstall-18c-1.0-1.el7.x86_64.rpm .
        aws s3 --region eu-central-1 cp s3://${internal_bucket_name}/software/oracle/oracle-database-xe-18c-1.0-1.x86_64.rpm .

        yum -y install oracle-database-preinstall-18c-1.0-1.el7.x86_64.rpm
        mkdir -p $EFS_MOUNT_POINT/oracle/network/admin
cat <<EOF > $EFS_MOUNT_POINT/oracle/network/admin/tnsnames.ora
xepdb1 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = $MYIP)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = xepdb1 )
    )
  )
EOF
        chown oracle $EFS_MOUNT_POINT/oracle/network/admin/tnsnames.ora
        chmod -R o+r $EFS_MOUNT_POINT/oracle
        chmod 644 $EFS_MOUNT_POINT/oracle/network/admin/tnsnames.ora

        yum -y install oracle-database-xe-18c-1.0-1.x86_64.rpm

        (echo "password"; echo "password";) | /etc/init.d/oracle-xe-18c configure
        ;;
    *)
        echo "Unknown Software $i"
    esac
done
