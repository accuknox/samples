**Create persistant voulume and persistant volume claim for your deployment**

    kubectl apply -f pv-pvc.yaml

**Deploy Postgres Server** 

    kubectl apply -f postgres.yaml

**Create service for the deployment**

    kubectl apply -f postgres-service.yaml

**Check everything is running fine** 

    kubectl get po -A


**Connecting to the database**
Let’s try connecting to the Postgres instance that we just deployed. Take note of the pod’s name and try:

    kubectl exec -it <DB_POD_NAME> -- bash

You’ll get a bash session on the container that’s running the database. For me, given the pod’s auto-generated name, it looks like this:

    root@vehicle-quotes-db-5fb576778-gx7j6:/#

From here, you can connect to the database using the psql command line client. Remember that we told the Postgres instance to create a vehicle_quotes user. We set it up via the container environment variables on our deployment configuration. As a result, we can do psql -U vehicle_quotes to connect to the database. Put together, it all looks like this:

    $kubectl exec -it vehicle-quotes-db-5fb576778-gx7j6 -- bash

    root@vehicle-quotes-db-5fb576778-gx7j6:/# psql -U vehicle_quotes
    psql (13.3 (Debian 13.3-1.pgdg100+1))
    Type "help" for help.
    
    
 
    
    vehicle_quotes=# \l
                                                List of databases
          Name      |     Owner      | Encoding |  Collate   |   Ctype    |         Access privileges
    ----------------+----------------+----------+------------+------------+-----------------------------------
     postgres       | vehicle_quotes | UTF8     | en_US.utf8 | en_US.utf8 |
     template0      | vehicle_quotes | UTF8     | en_US.utf8 | en_US.utf8 | =c/vehicle_quotes                +
                    |                |          |            |            | vehicle_quotes=CTc/vehicle_quotes
     template1      | vehicle_quotes | UTF8     | en_US.utf8 | en_US.utf8 | =c/vehicle_quotes                +
                    |                |          |            |            | vehicle_quotes=CTc/vehicle_quotes
     vehicle_quotes | vehicle_quotes | UTF8     | en_US.utf8 | en_US.utf8 |
    (4 rows)

Ref: [https://www.endpointdev.com/blog/2022/01/kubernetes-101/](https://www.endpointdev.com/blog/2022/01/kubernetes-101/)



**CVE-2019–9193 - PostgreSQL 9.3-12.3 Authenticated Remote Code Execution**

***Proof of Concept***
PostgreSQL Database from version 9.3 to 12.3 (latest tested) are vulnerable to Authenticated Remote Code Execution.
Even if it isn't considered to be a vulnerability itself by the development team, this could be leveraged to gain access to a misconfigured system.
