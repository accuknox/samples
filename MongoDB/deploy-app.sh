#! /bin/bash
kubectl create -f https://raw.githubusercontent.com/accuknox/samples/main/MongoDB/tasksapp.yaml
#kubectl scale deployment tasksapp --replicas=3
kubectl create -f https://raw.githubusercontent.com/accuknox/samples/main/MongoDB/tasksapp-svc.yaml
kubectl create -f https://raw.githubusercontent.com/accuknox/samples/main/MongoDB/mongo-pv.yaml
kubectl create -f https://raw.githubusercontent.com/accuknox/samples/main/MongoDB/mongo-pvc.yaml
kubectl create -f https://raw.githubusercontent.com/accuknox/samples/main/MongoDB/mongo.yaml
kubectl create -f https://raw.githubusercontent.com/accuknox/samples/main/MongoDB/mongo-svc.yaml
