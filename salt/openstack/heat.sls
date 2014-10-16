###
# Install the Orchestration service
# http://docs.openstack.org/icehouse/install-guide/install/yum/content/heat-install.html
# Icehouse
# Author: David Kilcy
###

###
# 1. Install the Orchestration module on the controller node:
###

###
# 2. In the configuration file, specify the location of the database where the Orchestration service stores data.
#    These examples use a MySQL database with a heat user on the controller node. Replace HEAT_DBPASS with the
#    password for the database user:
###

###
# 3. Use the password that you set previously to log in as root and create a heat database user:
###

###
# 4. Create the heat service tables:
###

###
# 5. Configure the Orchestration Service to use the Qpid message broker:
###

###
# 6. Create a heat user that the Orchestration service can use to authenticate with the Identity Service. 
#    Use the service tenant and give the user the admin role:
###

###
# 7. Run the following commands to configure the Orchestration service to authenticate with the Identity service:
###

###
# 8. Register the Heat and CloudFormation APIs with the Identity Service so that other OpenStack services can 
#    locate these APIs. Register the services and specify the endpoints:
###

###
# 9. Create the heat_stack_user role.
#    This role is used as the default role for users created by the Orchestration module.
###

###
# 10. Configure the metadata and waitcondition servers' URLs.
###

###
# 11. Start the heat-api, heat-api-cfn and heat-engine services and configure them to start when the system boots:
###


