#!/bin/bash

set -e

test -d /aosp || mkdir /aosp

grep -q 'sdb1$' /proc/partitions || {
  echo "# fdisk /dev/sdb"
  fdisk /dev/sdb <<EOF
n
p



w
EOF

  echo "# mkfs.ext4 /dev/sdb1"
  mkfs.ext4 /dev/sdb1
}

grep -q /aosp /etc/rc.local || {
  echo "# mount -n /dev/sdb1 /aosp" 

  sed -i.bak '/^exit 0/i \
# Provision android souce code partition \
mount /dev/sdb1 /aosp \
' /etc/rc.local

  grep -q /aosp /etc/rc.local || echo '
# Provision android souce code partition
mount /dev/sdb1 /aosp
' >> /etc/rc.local

  grep -q /aosp /proc/mounts || mount -n /dev/sdb1 /aosp
}
