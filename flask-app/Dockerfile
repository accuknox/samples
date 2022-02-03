FROM python:3.6.10-alpine

RUN pip3 install flask

COPY . /app
WORKDIR /app

ENTRYPOINT ["python3", "app.py"]
