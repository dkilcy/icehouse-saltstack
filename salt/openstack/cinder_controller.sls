###
# Configure a Block Storage service controller
# http://docs.openstack.org/icehouse/install-guide/install/yum/content/cinder-controller.html
# Icehouse
# Author: David Kilcy
###

###
# 1. Install the appropriate packages for the Block Storage service:
###

###
# 2. Configure Block Storage to use your database.
###

###
# 3. Use the password that you set to log in as root to create a cinder database:
###

###
# 4. Create the database tables for the Block Storage service:
###

###
# 5. Create a cinder user.
#    The Block Storage service uses this user to authenticate with the Identity service.
#    Use the service tenant and give the user the admin role:
###

###
# 6. Edit the /etc/cinder/cinder.conf configuration file:
###

###
# 7. Configure Block Storage to use the Qpid message broker:
###

###
# 8. Register the Block Storage service with the Identity service so that other OpenStack services can locate it:
###

###
# 9. Register a service and endpoint for version 2 of the Block Storage service API:
###

###
# 10. Start and configure the Block Storage services to start when the system boots:
###

