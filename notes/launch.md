#  Launch an instance with OpenStack Networking (neutron)

As devops user on controller

### Add keypair to nova
```
source /home/devops/openstack/auth.sh
source /home/devops/openstack/demo-openrc.sh

ssh-keygen
nova keypair-add --pub-key ~/.ssh/id_rsa.pub demo-key

nova keypair-list
```

### Start an instance
```
neutron net-list
export DEMO_NET_ID=53ff2063-50d0-47b1-8ac9-03e2ca19aca5

nova boot --flavor m1.tiny --image cirros-0.3.2-x86_64 --nic net-id=$DEMO_NET_ID \
 --security-group default --key-name demo-key demo-instance1
 
nova list
```

### Other commands

```
nova flavor-list
nova hypervisor-list
nova image-list
nova secgroup-list
```
