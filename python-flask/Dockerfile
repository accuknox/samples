FROM ubuntu
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip netcat mysql-server libmysqlclient-dev
RUN python3 -m pip install flask
RUN python3 -m pip install  flask-mysqldb
COPY . .
RUN python3 -m pip install -r requirements.txt
EXPOSE 8008 4444
CMD ["python3", "damn_pickleable.py"]
