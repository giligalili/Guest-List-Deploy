# 🌐 Guest List API on Kubernetes

This project demonstrates how to deploy the Guest List API in a Kubernetes cluster with multiple replicas and load balancing.

---

## 📦 Deployment Overview

- **3 replicas** of the application across separate Pods  
- **LoadBalancer** service for external access  
- Container image: `giligalili/guestlistapi:ver03`

---

## 🚀 Deployment Steps

### 1️⃣ Create the Deployment

Save the following content in a file called `guestlistapideploy.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: guestlistdeploy
  labels:
    app: guestlist-deploy
spec:
  replicas: 3
  selector:
    matchLabels:
      the-app-is: guestlist-pod
  template:
    metadata:
      labels:
        the-app-is: guestlist-pod
    spec:
      containers:
      - name: guestlistcontainer
        image: giligalili/guestlistapi:ver03
```

Apply the deployment using:
```bash
kubectl apply -f guestlistapideploy.yaml
```

---

### 2️⃣ Create a LoadBalancer Service

Save the following content in `guestlistapi-LB-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: guestlist-service
spec:
  selector:
    the-app-is: guestlist-pod
  type: LoadBalancer
  ports:
  - protocol: TCP
    port: 80
    targetPort: 1111
```

Apply the service:
```bash
kubectl apply -f guestlistapi-LB-service.yaml
```

---

## 🌍 Accessing the API

Once deployed, the LoadBalancer will expose the API externally. To get the external IP address, run:
```bash
kubectl get services
```

---

## 🧪 Testing

You can test the `/guests` endpoint using:
```bash
curl http://<EXTERNAL-IP>/guests
```

---

Let me know if you'd like to add features like Ingress, environment variables, or a ConfigMap for cleaner configuration. I can also help write internal documentation or scripts for automation.
