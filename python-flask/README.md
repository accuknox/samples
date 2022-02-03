Python Flask demo application 

To deploy the application to k8s 

1. **Clone the repo by git clone**
    ```
    git@github.com:accuknox/samples.git
    ```
2. **Change directory to python-flask**
    ```
    cd python-flask
    ```
3. **Apply using kubectl**
   ```
   kubectl apply -f k8s.yaml
   ```

4. **Use the single command to apply directly**
```
kubectl apply -f https://raw.githubusercontent.com/accuknox/samples/main/python-flask/k8s.yaml
```
