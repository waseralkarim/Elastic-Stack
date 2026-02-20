# Filebeat DaemonSet on K3s - Kubernetes Log Collection

## Overview

This guide covers deploying Filebeat as a **DaemonSet** on a 3-node **K3s** Kubernetes cluster to collect all pod/container logs and ship them to a remote Elasticsearch server secured with a trusted wildcard SSL certificate.

> **Environment:**
> 
> - K3s cluster: 3 nodes (k3s-master, k3s-worker, k3s-worker-2)
> - Container runtime: containerd (K3s default)
> - Elasticsearch: `https://elasticsearch.your-domain.com:9200`
> - Kibana: `https://kibana.your-domain.com:443`
> - Filebeat version: 9.x.x
> - SSL: Publicly trusted wildcard certificate

---

## K3s Log Structure

K3s uses **containerd** as its container runtime. Container logs are stored at:

| Path | Description |
| --- | --- |
| `/var/log/containers/*.log` | Symlinks to pod log files |
| `/var/log/pods/` | Actual pod log files |
| `/var/lib/rancher/k3s/agent/containerd` | Containerd data directory |

> **Note:** `/var/log/containers/` contains symlinks, not actual log files. Filebeat must be configured with `prospector.scanner.symlinks: true` to follow them.
> 

---

## Step 1: Create Namespace

```jsx
kubectl create namespace elastic
```

---

## Step 2: Create Elasticsearch Credentials Secret

```jsx
kubectl create secret generic elasticsearch-credentials \
  --namespace=elastic \
  --from-literal=username=elastic \
  --from-literal=password='YOUR_SECURE_PASSWORD'
```

---

## Step 3: Create Filebeat Manifest

```jsx
vim filebeat-k3s.yaml
```

### Complete Manifest

```jsx
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: filebeat-config
  namespace: elastic
  labels:
    app: filebeat
data:
  filebeat.yml: |-
    filebeat.inputs:
      - type: filestream
        id: kubernetes-containers
        paths:
          - /var/log/containers/*.log
        parsers:
          - container: ~
        prospector:
          scanner:
            symlinks: true
        processors:
          - add_kubernetes_metadata:
              host: ${NODE_NAME}
              matchers:
                - logs_path:
                    logs_path: "/var/log/containers/"

    output.elasticsearch:
      hosts: ["https://elasticsearch.your-domain.com:9200"]
      username: ${ELASTICSEARCH_USERNAME}
      password: ${ELASTICSEARCH_PASSWORD}
      ssl:
        enabled: true
        verification_mode: full

    setup.kibana:
      host: "https://kibana.your-domain.com:443"

    setup.dashboards.enabled: false

    processors:
      - add_cloud_metadata: ~
      - add_host_metadata: ~
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: filebeat
  namespace: elastic
  labels:
    app: filebeat
spec:
  selector:
    matchLabels:
      app: filebeat
  template:
    metadata:
      labels:
        app: filebeat
    spec:
      serviceAccountName: filebeat
      terminationGracePeriodSeconds: 30
      tolerations:
        - effect: NoSchedule
          operator: Exists
        - effect: NoExecute
          operator: Exists
      containers:
        - name: filebeat
          image: docker.elastic.co/beats/filebeat:9.x.x
          args: ["-c", "/etc/filebeat.yml", "-e"]
          env:
            - name: ELASTICSEARCH_USERNAME
              valueFrom:
                secretKeyRef:
                  name: elasticsearch-credentials
                  key: username
            - name: ELASTICSEARCH_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: elasticsearch-credentials
                  key: password
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
          securityContext:
            runAsUser: 0
          resources:
            limits:
              memory: 300Mi
              cpu: 200m
            requests:
              memory: 100Mi
              cpu: 100m
          volumeMounts:
            - name: config
              mountPath: /etc/filebeat.yml
              readOnly: true
              subPath: filebeat.yml
            - name: data
              mountPath: /usr/share/filebeat/data
            - name: varlogcontainers
              mountPath: /var/log/containers
              readOnly: true
            - name: varlogpods
              mountPath: /var/log/pods
              readOnly: true
            - name: containerdlogs
              mountPath: /var/lib/rancher/k3s/agent/containerd
              readOnly: true
      volumes:
        - name: config
          configMap:
            name: filebeat-config
            defaultMode: 0640
        - name: data
          hostPath:
            path: /var/lib/filebeat-data
            type: DirectoryOrCreate
        - name: varlogcontainers
          hostPath:
            path: /var/log/containers
        - name: varlogpods
          hostPath:
            path: /var/log/pods
        - name: containerdlogs
          hostPath:
            path: /var/lib/rancher/k3s/agent/containerd
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: filebeat
  namespace: elastic
  labels:
    app: filebeat
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: filebeat
  labels:
    app: filebeat
rules:
  - apiGroups: [""]
    resources:
      - namespaces
      - pods
      - nodes
    verbs: ["get", "watch", "list"]
  - apiGroups: ["apps"]
    resources:
      - replicasets
    verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: filebeat
  labels:
    app: filebeat
subjects:
  - kind: ServiceAccount
    name: filebeat
    namespace: elastic
roleRef:
  kind: ClusterRole
  name: filebeat
  apiGroup: rbac.authorization.k8s.io
```

## Step 4: Apply the Manifest

```jsx
kubectl apply -f filebeat-k3s.yaml
```

---

## Step 5: Verify Deployment

Check all pods are running (one per node):

```jsx
kubectl get pods -n elastic -o wide
```

Expected output:
```
NAME             READY   STATUS    AGE   NODE
filebeat-xxxxx   1/1     Running   8s    k3s-worker
filebeat-xxxxx   1/1     Running   8s    k3s-worker-2
filebeat-xxxxx   1/1     Running   8s    k3s-master
```

Verify DaemonSet status:

```jsx
kubectl get daemonset filebeat -n elastic
```

Expected output:
```
NAME       DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   AGE
filebeat   3         3         3       3             3           1m
```

Check Filebeat logs:

```jsx
kubectl logs -n elastic -l app=filebeat --tail=20
```

---

## Step 6: Generate Test Logs

Create a test pod that generates log output:

```jsx
kubectl run test-logger --image=busybox --restart=Never -- \
  sh -c 'for i in $(seq 1 50); do echo "Test log message $i from K3s cluster"; sleep 1; done'
```

Clean up after testing:

```jsx
kubectl delete pod test-logger
```

---

## Step 7: Verify in Kibana

1. Open Kibana at `https://kibana.your-domain.com`
2. Go to **Discover**
3. Select the `filebeat-*` data view
4. You should see logs with Kubernetes metadata fields:
    - `kubernetes.pod.name`
    - `kubernetes.namespace`
    - `kubernetes.node.name`
    - `kubernetes.container.name`
    - `kubernetes.labels.*`
