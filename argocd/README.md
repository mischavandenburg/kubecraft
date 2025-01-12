### Introduction:

In this guide, we will go through the installation of argocd manually first and then make the argocd self-manage itself declaratively through creation of argocd 'application'.  For manual installation, we will make use of the [helm](https://artifacthub.io/packages/helm/argo/argo-cd) and for self-managing through the argocd 'application', we will still make use of the argocd helm chart but we will follow app of apps pattern. So if there is any change (argocd version update) to the `argocd-app.yaml` file shown below, then root-app will make sure that the argocd-app is marked as out-of-sync.  

---
### Directory structure:

```
├── apps-children
│   └── argocd-app.yaml
├── manifests
├── root-app.yaml
└── values
    └── values.yaml
```

Here we are following app of apps pattern. As per this pattern, we put all our argocd 'applications' in the apps-children directory and root application will list this folder as source. For each app in the apps-children folder, the corresponding manifests such as deployment.yaml, service.yaml etc can be stored in the manifests folder. This directory structure allows us to expand the application list in the `apps-children` folder in the future.

---
### 1. Creating manifest files:

- First, create these three files based on the required configuration:


(i) argocd-app.yaml (HA with autoscaling enabled)

Note: values are embedded in this file instead of keeping in a separate file for synchronization to trigger automatically.

```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd-app
  namespace: argocd
spec:
  project: default
  destination:
    namespace: argocd
    server: https://kubernetes.default.svc
  source:
    repoURL: https://argoproj.github.io/argo-helm
    targetRevision: 7.7.15
    chart: argo-cd
    helm:
      releaseName: argo-cd
      values: |
        redis-ha:
          enabled: true

        controller:
          replicas: 1

        server:
          autoscaling:
            enabled: true
            minReplicas: 1

        repoServer:
          autoscaling:
            enabled: true
            minReplicas: 1

        applicationSet:
          replicas: 1
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
    automated:
      prune: true
      selfHeal: true
```


(ii) root-app.yaml

```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/vikramreddym/lab.git
    targetRevision: HEAD
    path: "./devops engineering/argocd/argocd-self-manage/apps-children/"
  destination:
    namespace: argocd
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

(iii) values.yaml (for manual step)

Quote from [artifacthub](https://artifacthub.io/packages/helm/argo/argo-cd#high-availability):
> Warning: You need at least 3 worker nodes as the HA mode of redis enforces Pods to run on separate nodes.

```
redis-ha:
  enabled: true

controller:
  replicas: 1

server:
  autoscaling:
    enabled: true
    minReplicas: 1

repoServer:
  autoscaling:
    enabled: true
    minReplicas: 1

applicationSet:
  replicas: 1
```


---
### 2. Initial installation (manual):

*  **Step 1**:

Add Helm Repo:

```
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```


* **Step 2**:

create argocd manually using the below command:

`helm install argo-cd argo/argo-cd --version 7.7.15 -n argocd --create-namespace -f values/values.yaml`

Output:
```
$ helm install argo-cd argo/argo-cd --version 7.7.15 -n argocd --create-namespace -f values/values.yaml
NAME: argo-cd
LAST DEPLOYED: Sat Jan 11 22:39:21 2025
NAMESPACE: argocd
STATUS: deployed
REVISION: 1
NOTES:
In order to access the server UI you have the following options:

1. kubectl port-forward service/argo-cd-argocd-server -n argocd 8080:443

    and then open the browser on http://localhost:8080 and accept the certificate

2. enable ingress in the values file `server.ingress.enabled` and either
      - Add the annotation for ssl passthrough: https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#option-1-ssl-passthrough
      - Set the `configs.params."server.insecure"` in the values file and terminate SSL at your ingress: https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#option-2-multiple-ingress-objects-and-hosts


After reaching the UI the first time you can login with username: admin and the random password generated during the installation. You can find the password by running:

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

(You should delete the initial secret afterwards as suggested by the Getting Started Guide: https://argo-cd.readthedocs.io/en/stable/getting_started/#4-login-using-the-cli)

```


You should see something similar in `argocd` namespace:

```
$ k get all -n argocd
NAME                                                            READY   STATUS    RESTARTS        AGE
pod/argo-cd-argocd-application-controller-0                     1/1     Running   2 (4m3s ago)    7m19s
pod/argo-cd-argocd-applicationset-controller-568bc6f7d9-bc6q9   1/1     Running   2 (4m3s ago)    7m20s
pod/argo-cd-argocd-dex-server-7f9566b558-pptjv                  1/1     Running   2 (4m3s ago)    7m20s
pod/argo-cd-argocd-notifications-controller-5d4cddcf5c-b74nn    1/1     Running   2 (4m4s ago)    7m20s
pod/argo-cd-argocd-repo-server-77d9d49ffd-tkcr9                 1/1     Running   2 (4m4s ago)    7m20s
pod/argo-cd-argocd-server-575dc6fcfd-w89kt                      1/1     Running   2 (4m3s ago)    7m19s
pod/argo-cd-redis-ha-haproxy-7888b67cc6-25n8b                   1/1     Running   1 (4m56s ago)   7m20s
pod/argo-cd-redis-ha-haproxy-7888b67cc6-85l5t                   0/1     Pending   0               7m20s
pod/argo-cd-redis-ha-haproxy-7888b67cc6-mcdl8                   0/1     Pending   0               7m20s
pod/argo-cd-redis-ha-server-0                                   3/3     Running   3 (4m38s ago)   7m19s
pod/argo-cd-redis-ha-server-1                                   0/3     Pending   0               6m4s

NAME                                               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)              AGE
service/argo-cd-argocd-applicationset-controller   ClusterIP   10.97.56.137     <none>        7000/TCP             7m20s
service/argo-cd-argocd-dex-server                  ClusterIP   10.101.90.220    <none>        5556/TCP,5557/TCP    7m20s
service/argo-cd-argocd-repo-server                 ClusterIP   10.111.157.176   <none>        8081/TCP             7m20s
service/argo-cd-argocd-server                      ClusterIP   10.111.47.17     <none>        80/TCP,443/TCP       7m20s
service/argo-cd-redis-ha                           ClusterIP   None             <none>        6379/TCP,26379/TCP   7m20s
service/argo-cd-redis-ha-announce-0                ClusterIP   10.111.146.32    <none>        6379/TCP,26379/TCP   7m20s
service/argo-cd-redis-ha-announce-1                ClusterIP   10.107.60.246    <none>        6379/TCP,26379/TCP   7m20s
service/argo-cd-redis-ha-announce-2                ClusterIP   10.107.162.255   <none>        6379/TCP,26379/TCP   7m20s
service/argo-cd-redis-ha-haproxy                   ClusterIP   10.103.54.218    <none>        6379/TCP,9101/TCP    7m20s

NAME                                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/argo-cd-argocd-applicationset-controller   1/1     1            1           7m20s
deployment.apps/argo-cd-argocd-dex-server                  1/1     1            1           7m20s
deployment.apps/argo-cd-argocd-notifications-controller    1/1     1            1           7m20s
deployment.apps/argo-cd-argocd-repo-server                 1/1     1            1           7m20s
deployment.apps/argo-cd-argocd-server                      1/1     1            1           7m20s
deployment.apps/argo-cd-redis-ha-haproxy                   1/3     3            1           7m20s

NAME                                                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/argo-cd-argocd-applicationset-controller-568bc6f7d9   1         1         1       7m20s
replicaset.apps/argo-cd-argocd-dex-server-7f9566b558                  1         1         1       7m20s
replicaset.apps/argo-cd-argocd-notifications-controller-5d4cddcf5c    1         1         1       7m20s
replicaset.apps/argo-cd-argocd-repo-server-77d9d49ffd                 1         1         1       7m20s
replicaset.apps/argo-cd-argocd-server-575dc6fcfd                      1         1         1       7m20s
replicaset.apps/argo-cd-redis-ha-haproxy-7888b67cc6                   3         3         1       7m20s

NAME                                                     READY   AGE
statefulset.apps/argo-cd-argocd-application-controller   1/1     7m20s
statefulset.apps/argo-cd-redis-ha-server                 1/3     7m20s

NAME                                                             REFERENCE                               TARGETS                                     MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/argo-cd-argocd-repo-server   Deployment/argo-cd-argocd-repo-server   memory: <unknown>/50%, cpu: <unknown>/50%   1         5         1          7m20s
horizontalpodautoscaler.autoscaling/argo-cd-argocd-server        Deployment/argo-cd-argocd-server        memory: <unknown>/50%, cpu: <unknown>/50%   1         5         1          7m20s
```

---
### 3. Create argocd application (declarative):

* **Step 1 Using the same release version, release name, configuration in values.yaml as above, apply the below command**:

```
$ k apply -f root-app.yaml -n argocd
application.argoproj.io/root-app created
```

* **Step 2 Remove helm control over the argocd release by deleting the secret**:

```
$ kubectl delete secret -n argocd -l name=argo-cd

secret "sh.helm.release.v1.argo-cd.v1" deleted
```

* After that, `helm list` will no longer return the original installation it created:

```
$ helm list -n argocd
NAME    NAMESPACE       REVISION        UPDATED STATUS  CHART   APP VERSION

```

* From now, responsibility to manage the argo cd is taken over by itself using the application that we have created.

---
### Argocd cli

* Use `brew install argocd` to install the cli or download the binary from [github releases page](https://github.com/argoproj/argo-cd/releases) and place it in `/usr/local/bin`
* Get the password for argocd-server:
```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
GTXX8JFdA0YORhmW
```

* Login to argocd cli (use the ui server address in place of localhost):
```
argocd login localhost:8080
WARNING: server certificate had error: tls: failed to verify certificate: x509: certificate signed by unknown authority. Proceed insecurely (y/n)? y
Username: admin
Password:
'admin:login' logged in successfully
Context 'localhost:8080' updated
```

* Now argocd cli should list the application:
```
$ argocd app list
NAME               CLUSTER                         NAMESPACE  PROJECT  STATUS  HEALTH   SYNCPOLICY  CONDITIONS  REPO                                     PATH                                                           TARGET
argocd/argocd-app  https://kubernetes.default.svc  argocd     default  Synced  Healthy  Auto-Prune  <none>      https://argoproj.github.io/argo-helm                                                                    7.7.15
argocd/root-app    https://kubernetes.default.svc  argocd     default  Synced  Healthy  Auto-Prune  <none>      https://github.com/vikramreddym/lab.git  ./devops engineering/argocd/argocd-self-manage/apps-children/  HEAD


```

### Upgrades/Downgrades/modifications:

* Now to upgrade/downgrade argocd to a specific version, just update `targetRevision` in the argocd-app.yaml file with the desired version. Argo cd will automatically synchronize to the version specified in git repo.
* Any changes to the argocd app file in git repo will automatically be reflected in the argocd.
