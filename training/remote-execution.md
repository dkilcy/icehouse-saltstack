# Remote Execution

- Returners
- Compound Commands
- Runners
- Job System
- Salt Call
- Salt SSH

### Returners

- Command return data does not need to be returned to the master, can go anywhere
- pluggable modules

By default commands are sent from the master to the minions, executed then the return data from the function is sent back to the master.    

  salt '*' test.ping --return mongo_return
  salt '*' test.ping --return mongo_return, mysql
  
### Compound Commands


### Runners

- Complex commands from the master

Runners are capabilities specific to the master.  They are simple apps to run more complex tasks on the minion and return specific data.

    $ salt-run manage.up
    compute-02.mgmt

    salt-run manage.down

### Job System

### Salt Call

### Salt SSH


  
  
