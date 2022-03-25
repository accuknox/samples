Part 4: Testing your application
Prerequisite: curl is to be installed on the master node.
Now that we can access our application at 10.103.82.106:8080, lets try to test all the functionalities that our app offers.
myuser@master1:~$ curl 10.103.82.106:8080
{
  "message": "Welcome to Tasks app! I am running inside tasksapp-645b67dfbc-ncrt7 pod!"
}
myuser@master1:~$ curl 10.103.82.106:8080/tasks
{
  "data": []
}
myuser@master1:~$ curl -X POST -d "{\"task\": \"Task 1\"}" http://10.103.82.106:8080/task
{
  "message": "Task saved successfully!"
}
myuser@master1:~$ curl -X POST -d "{\"task\": \"Task 2\"}" http://10.103.82.106:8080/task
{
  "message": "Task saved successfully!"
}
myuser@master1:~$ curl -X POST -d "{\"task\": \"Task 3\"}" http://10.103.82.106:8080/task
{
  "message": "Task saved successfully!"
}
myuser@master1:~$ curl 10.103.82.106:8080/tasks
{
  "data": [
    {
      "id": "5ef8bce7df44b8194ee30c9a",
      "task": "Task 1"
    },
    {
      "id": "5ef8bcef7bc5ec979ae73a43",
      "task": "Task 2"
    },
    {
      "id": "5ef8bcf742b0630f70328296",
      "task": "Task 3"
    }
  ]
}
myuser@master1:~$ curl -X PUT -d "{\"task\": \"Task 1 Updated\"}" http://10.103.82.106:8080/task/5ef8bce7df44b8194ee30c9a
{
  "message": "Task updated successfully!"
}
myuser@master1:~$ curl 10.103.82.106:8080/tasks
{
  "data": [
    {
      "id": "5ef8bce7df44b8194ee30c9a",
      "task": "Task 1 Updated"
    },
    {
      "id": "5ef8bcef7bc5ec979ae73a43",
      "task": "Task 2"
    },
    {
      "id": "5ef8bcf742b0630f70328296",
      "task": "Task 3"
    }
  ]
}
myuser@master1:~$ curl -X DELETE http://10.103.82.106:8080/task/5ef8bce7df44b8194ee30c9a
{
  "message": "Task deleted successfully!"
}
myuser@master1:~$ curl 10.103.82.106:8080/tasks
{
  "data": [
    {
      "id": "5ef8bcef7bc5ec979ae73a43",
      "task": "Task 2"
    },
    {
      "id": "5ef8bcf742b0630f70328296",
      "task": "Task 3"
    }
  ]
}
myuser@master1:~$ curl -X POST http://10.103.82.106:8080/tasks/delete
{
  "message": "All Tasks deleted!"
}
myuser@master1:~$ curl 10.103.82.106:8080/tasks
{
  "data": []
}


Ref: https://levelup.gitconnected.com/deploy-your-first-flask-mongodb-app-on-kubernetes-8f5a33fa43b4
