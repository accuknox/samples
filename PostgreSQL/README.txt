Connecting to the database
Let’s try connecting to the Postgres instance that we just deployed. Take note of the pod’s name and try:

$ kubectl exec -it <DB_POD_NAME> -- bash
You’ll get a bash session on the container that’s running the database. For me, given the pod’s auto-generated name, it looks like this:

root@vehicle-quotes-db-5fb576778-gx7j6:/#
From here, you can connect to the database using the psql command line client. Remember that we told the Postgres instance to create a vehicle_quotes user. We set it up via the container environment variables on our deployment configuration. As a result, we can do psql -U vehicle_quotes to connect to the database. Put together, it all looks like this:

$ kubectl exec -it vehicle-quotes-db-5fb576778-gx7j6 -- bash
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



Checking Persistant volume 

Now, try connecting to the database (using kubectl exec -it <VEHICLE_QUOTES_DB_POD_NAME> -- bash and then psql -U vehicle_quotes) and creating some tables. Something simple like this would work:

CREATE TABLE test (test_field varchar);
Now, close psql and the bash in the pod and delete the objects:

$ kubectl delete -f db-deployment.yaml
$ kubectl delete -f db-persistent-volume-claim.yaml
$ kubectl delete -f db-persistent-volume.yaml
Create them again:

$ kubectl apply -f db-persistent-volume.yaml
$ kubectl apply -f db-persistent-volume-claim.yaml
$ kubectl apply -f db-deployment.yaml
Connect to the database again and you should see that the table is still there:

vehicle_quotes=# \c vehicle_quotes
You are now connected to database "vehicle_quotes" as user "vehicle_quotes".
vehicle_quotes=# \dt
           List of relations
 Schema | Name | Type  |     Owner
--------+------+-------+----------------
 public | test | table | vehicle_quotes
(1 row)
