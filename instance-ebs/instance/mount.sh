#!/bin/bash

#set userpassword
myuser="heera"
password="Welcome123"

sudo adduser $myuser --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
echo "$myuser:$password" | sudo chpasswd

# adds user to sudoers

echo "$myuser  ALL=(ALL:ALL) ALL" >> /etc/sudoers

# Enable password authentication
#sudo grep -q "ChallengeResponseAuthentication" /etc/ssh/sshd_config && sed -i "/^[^#]*ChallengeResponseAuthentication[[:space:]]yes.*/c\ChallengeResponseAuthentication no" /etc/ssh/sshd_config || echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config
grep -q "^[^#]*PasswordAuthentication" /etc/ssh/sshd_config && sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config || echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
#also this can be used instead of above line
#sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
service ssh restart
service sshd restart


#edit your disk and mountpath name/directory
device="xvdb"
mount_path="/mnt/disks/data"
fdisk /dev/$device <<EEOF
n
p
1


w
EEOF


sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/"$device"1 <<EEOF
y
EEOF

sudo mkdir -p $mount_path 
sudo mount -o discard,defaults /dev/"$device"1 $mount_path 
sudo chmod a+w $mount_path 
sudo cp /etc/fstab /etc/fstab.backup 
sudo blkid /dev/"$device"1 
echo UUID=`sudo blkid -s UUID -o value /dev/"$device"1` $mount_path ext4 discard,defaults,nofail 0 2 | sudo tee -a /etc/fstab 
exit 0