#!/bin/bash
kubectl delete -f https://raw.githubusercontent.com/accuknox/microservices-demo/main/php-mysql-webapp/mysql-svc.yaml
kubectl delete -f https://raw.githubusercontent.com/accuknox/microservices-demo/main/php-mysql-webapp/mysql.yaml
kubectl delete -f https://raw.githubusercontent.com/accuknox/microservices-demo/main/php-mysql-webapp/mysql-pv-claim.yaml
kubectl delete -f https://raw.githubusercontent.com/accuknox/microservices-demo/main/php-mysql-webapp/webserver-svc.yaml
kubectl delete -f https://raw.githubusercontent.com/accuknox/microservices-demo/main/php-mysql-webapp/webserver.yaml
