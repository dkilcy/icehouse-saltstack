###
# Configure a Block Storage service node
# http://docs.openstack.org/icehouse/install-guide/install/yum/content/cinder-node.html
# Icehouse
# Author: David Kilcy
###

###
# 1. 
###

###
# 2. Create the LVM physical and logical volumes. This guide assumes a second disk /dev/sdb that is used for this purpose:
###

###
# 3. Add a filter entry to the devices section in the /etc/lvm/lvm.conf file to keep LVM from scanning devices used by 
#    virtual machines:
###

###
# 4. After you configure the operating system, install the appropriate packages for the Block Storage service:
###

###
# 5. Copy the /etc/cinder/cinder.conf configuration file from the controller, or perform the following steps to
#    set the keystone credentials:
###

###
# 6. Configure Block Storage to use the Qpid message broker:
###

###
# 7. Configure Block Storage to use your MySQL database. Edit the /etc/cinder/cinder.conf file and add the
#    following key to the [database] section. Replace CINDER_DBPASS with the password you chose for the
#    Block Storage database:
###

###
# 8. Configure Block Storage to use the Image Service. Block Storage needs access to images to create bootable volumes. 
#    Edit the /etc/cinder/cinder.conf file and update the glance_host option in the [DEFAULT] section:
###

###
# 9. Configure the iSCSI target service to discover Block Storage volumes. Add the following line to the beginning of 
# the /etc/tgt/targets.conf file, if it is not already present
###

###
# 10. Start and configure the Block Storage services to start when the system boots:
###


