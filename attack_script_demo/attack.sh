#! /bin/bash
bold=`tput bold setaf 2`
reset=`tput sgr0`
red=`tput setaf 1`
attack_deploy() {

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
		kubectl apply -f https://raw.githubusercontent.com/accuknox/samples/main/microservice-demo/release/kubernetes-manifests.yaml -n $ns
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

attack_remove() {

ns="boutique-app"
bold=`tput bold setaf 2`
reset=`tput sgr0`
if [[ -z $(kubectl get ns | grep $ns) ]]
	then
	
  		echo -e "${bold}\n$ns is not found${reset}"
  		
	else
		delete_app
		echo ""
		echo "Removing Security Policy. Please wait..."
		delete_policies
		echo ""
		echo "Removing CronJob. Please wait.."
		delete_cron
		echo ""
		echo "Deleting $ns namespace. Please wait..."
		kubectl delete ns $ns
		echo ""
		echo "Successfully removed all components"
fi

}
delete_app() {

if [[ -z $(kubectl get po -n $ns | grep frontend-) ]]
	then
	
  		echo -e "${bold}\nSample appplication is not found in $ns namespace${reset}"
  		
	else
		echo -e  "\n${bold}Sample application deleting...${reset}"
		kubectl delete -f https://raw.githubusercontent.com/accuknox/samples/main/microservice-demo/release/kubernetes-manifests.yaml -n $ns
fi
}

delete_policies() {

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

delete_cron() {

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

if [[ ( $1 == "install") ||  $1 == "Install" ||  $1 == "INSTALL" || $1 == "ins" || $1 == "" ]]
then

  attack_deploy

elif [[ ( $1 == "delete") ||  $1 == "Delete" ||  $1 == "DELETE" ||  $1 == "del" ]]
then

  attack_remove

else

  echo "Use $0 'ins'tall or $0 'del'ete"
fi
