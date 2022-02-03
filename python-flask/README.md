Python Flask demo application 

To deploy the application to k8s 

1. **Clone the repo by git clone**
    ```
    https://github.com/vsk-coding/flask-app-demo.git
    ```
2. **Apply using kubectl**
   ```
   kubectl apply -f k8s.yaml
   ```

3. **Use the single command to apply directly**
```
kubectl apply -f https://raw.githubusercontent.com/vsk-coding/flask-app-demo/main/k8s.yaml
```
