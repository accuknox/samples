#!/bin/bash

var=$(docker images -a | sed 1d)
count=$(docker images -a | sed 1d | wc -l)
while read line; 
do
    echo $count
    if [[ $count -gt 2 ]]
    then
	    value=$(echo $line | awk '{print $1}')
	    echo $value
	    docker rmi -f $(echo $line | awk '{print $3}')
	fi
	((count=count-1))
done <<< "$var"

docker rmi -f frontend-google:latest
docker rmi -f vishnusk/frontend-google:latest
docker build -t frontend-google . 
docker image tag frontend-google:latest vishnusk/frontend-google:latest
docker image push vishnusk/frontend-google:latest

