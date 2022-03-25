#! /bin/bash
kubectl create -f tasksapp.yaml
#kubectl scale deployment tasksapp --replicas=3
kubectl create -f tasksapp-svc.yaml
kubectl create -f mongo-pv.yaml
kubectl create -f mongo-pvc.yaml
kubectl create -f mongo.yaml
kubectl create -f mongo-svc.yaml
