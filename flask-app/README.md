
# Flask App

#### 1. Build the docker image:
First, built the docker image of the flask server using the provided Dockerfile.
```
docker build -t flask-app .
```
#### 2.  Start the container:
You can just open another terminal or anywhere in your local network, just start the server as follows:
```
docker run -d -p 8080:5000 flask-app
```
You will get an image id. To verify the docker container is running use:
```
 docker ps
 docker logs $(docker ps -q)
```

