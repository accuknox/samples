FROM ubuntu:latest
WORKDIR /tmp
RUN apt-get update

RUN apt-get install curl -y

RUN  /usr/bin/curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
Run mv ./kubectl /usr/local/bin/kubectl
