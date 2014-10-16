###
# Configure the Object Storage service for Telemetry
# http://docs.openstack.org/icehouse/install-guide/install/yum/content/ceilometer-install-swift.html
# Icehouse
# Author: David Kilcy
###

###
# 1. To retrieve object store statistics, the Telemetry service needs access to Object Storage with the 
#    ResellerAdmin role. Give this role to your os_username user for the os_tenant_name tenant:
###

###
# 2. You must also add the Telemetry middleware to Object Storage to handle incoming and outgoing traffic.
#    Add these lines to the /etc/swift/proxy-server.conf file:
###

###
# 3. Add ceilometer to the pipeline parameter of that same file:
###

###
# 4. Restart the service with its new settings:
###

