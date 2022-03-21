#!/bin/bash

#function to deploy log4j and necessary components
sysrv_deploy() {

  ns_val="sysrv-poc"

  if [[ -z $(kubectl get ns | grep $ns_val) ]]
  then
      tput bold setaf 2; echo "Creating $ns_val namespace. Please wait..."
      kubectl create ns $ns_val
  fi

  echo 
  tput bold setaf 2; echo "Applying Security Policy. Please wait..."
  kubectl -n $ns_val apply -f https://raw.githubusercontent.com/accuknox/samples/main/sysrv-hello/ksp-block-sysrv-hello-malware.yaml 
  echo
  tput bold setaf 2; echo "Creating CronJob Please wait..."
  cat << eof | kubectl -n $ns_val apply -f-
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cron-sysrv
spec:
  schedule: "*/2 * * * *"
  successfulJobsHistoryLimit: 0
  failedJobsHistoryLimit: 0
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
           app: wordpress
        spec:
          containers:
          - name: wordpress
            image: knoxuser/wordpress
            imagePullPolicy: IfNotPresent
            command:
            - /bin/bash
            - -c 
            - curl -s https://raw.githubusercontent.com/accuknox/samples/main/sysrv-hello/ldr.sh | bash; sleep 240; exit 0
          restartPolicy: Never
eof


}


#function to remove all components deployed during installation phase
sysrv_remove() {

  ns_val="sysrv-poc"

  tput bold setaf 2; echo "Removing CronJob. Please wait.."
  echo
  cat << eof | kubectl -n $ns_val delete -f-
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cron-sysrv
spec:
  schedule: "2 * * * *"
  successfulJobsHistoryLimit: 0
  failedJobsHistoryLimit: 0
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
           app: wordpress
        spec:
          containers:
          - name: wordpress
            image: knoxuser/wordpress
            imagePullPolicy: IfNotPresent
            command:
            - /bin/bash
            - -c 
            - sleep 20; curl -s https://raw.githubusercontent.com/accuknox/samples/main/sysrv-hello/ldr.sh | bash 
          restartPolicy: Never
eof

  echo 
  tput bold setaf 2; echo "Removing Security Policy. Please wait..."
  kubectl -n $ns_val delete -f https://raw.githubusercontent.com/accuknox/samples/main/sysrv-hello/ksp-block-sysrv-hello-malware.yaml 

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

  sysrv_deploy

elif [[ ( $1 == "delete") ||  $1 == "Delete" ||  $1 == "DELETE" ||  $1 == "del" ]]
then

  sysrv_remove

else

  echo "Use $0 'ins'tall or $0 'del'ete"
fi
