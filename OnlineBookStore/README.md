
**Online Book Store** is a Java-MySQL demo application.
Online Book store consists of a 2-tier microservices application. The application is for selling books online, maintaining books selling history, adding and managing books etc.

This application uses Java for Back-End and database used is MySQL.

 This application works on any Kubernetes cluster, as well as Google
Kubernetes Engine. It’s **easy to deploy**.

If you’re using this demo, please **★Star** this repository.

### Quickstart

1. **Clone this repository.**

```
git clone https://github.com/accuknox/microservices-demo.git
cd microservices-demo/OnlineBookStore/
```

2. **Create a namespace.**



```
kubectl create ns bookstore
```


3. **Deploy the MySQL Database to the cluster.**

```
kubectl apply -f https://raw.githubusercontent.com/accuknox/microservices-demo/main/OnlineBookStore/mysql-deployment.yaml -n bookstore
```

5. **Wait for the Pods and services to be ready.**

```
kubectl get po,svc -n bookstore
```

After a few seconds, you should see:

```
NAME                         READY   STATUS    RESTARTS   AGE
pod/mysql-68579b78bb-ptbm4   1/1     Running   0          17s

NAME            TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
service/mysql   ClusterIP   None         <none>        3306/TCP   18s

```

6. **After deploying MySQL, Log in to MySQL** using the following command.

```
kubectl run -it --rm --image=mysql:5.6 --restart=Never mysql-client1 -- mysql -h mysql.bookstore.svc.cluster.local -uroot -ppassword
```

7. **Dump the following SQL queries**

### Copy and Paste the following MYSQL commands to make a dummy database for this Project :
```
create database onlinebookstore;
```
```
use onlinebookstore;
```
```
create table books(barcode varchar(100) primary key, name varchar(100), author varchar(100), price int, quantity int);
```
```
create table users(username varchar(100) primary key,password
```
```
varchar(100), firstname varchar(100),lastname varchar(100),address text, phone varchar(100),mailid varchar(100),usertype int);
```
```
insert into books values('10101','Programming in C','James k Wick',500,5);
```
```
insert into books values('10102','Learn Java','Scott Mayers',150,13);
```
```
insert into books values('10103','Database Knowledge','Charles Pettzoid',124,360);
```
```
insert into books values('10104','Let us c++','Steve Macclen',90,111);
```
```
insert into books values('10105','Success Key','Shashi Raj',5000,15);
```
```
insert into users values('User','Password','First','User','My Home','42502216225','User@gmail.com',2);
```
```
insert into users values('Admin','Admin','Mr.','Admin','Haldia WB','9584552224521','admin@gmail.com',1);
```
```
insert into users values('shashi','shashi','Shashi','Raj','Bihar','1236547089','shashi@gmail.com',2);
```
```
commit;
```



8. **Deploy the bookstore application.**
```
kubectl apply -f https://raw.githubusercontent.com/accuknox/microservices-demo/main/OnlineBookStore/bookstore.yaml
```
9.  **Access the web frontend in a browser**  using the frontend's  `EXTERNAL_IP`.

```
kubectl get service online-book-store | awk '{print $4}'

```

_Example output - do not copy_

```
EXTERNAL-IP
<your-ip>
```

**Note**- you may see  `<pending>`  while GCP provisions the load balancer. If this happens, wait a few minutes and re-run the command.

10. [Optional] **Clean up**:

```
kubectl delete -f https://raw.githubusercontent.com/accuknox/microservices-demo/main/OnlineBookStore/clean.yaml -n bookstore
```
