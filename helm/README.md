# Galera Helm Chart

MariaDB Galera is a product inside MariaDB which enables clusterization of MariaDB databases.

Each node in the cluster stores its own data and Galera synchronizes each data.

galera-k8s makes it easy to deploy Galera cluster into Kubernetes environment.

## Prerequisites

- Kubernetes 1.13+
- Helm 2.0.0+

## Installing the Chart

It is recommended to use fixed release name and namespace.

To install the MariaDB Galera helm chart with a release name `my-release` and namespace `my-ns`:

```bash
## IMPORTANT: the namespace `my-ns` should be created before installing the chart

## Common
# change current directory to your own workspace
$ cd your-workspace
$ git clone https://github.com/josh9191/galera-k8s.git galera-k8s 

## Helm 2
$ helm install --namespace my-ns --name my-release -f ./galera-k8s/helm/values.yaml galera-k8s/helm

## Helm 3
$ helm install --namespace my-ns my-release -f ./galera-k8s/helm/values.yaml galera-k8s/helm
```

## Uninstalling the Chart

To uninstall/delete the 'my-release' deployment in 'my-ns' namespace:

```bash
$ helm delete --namespace my-ns --purge my-release
```

## Configuration
The following table lists the parameters of the galera-k8s

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `global.nodeSelector` | Node selector for pods(which is assigned to `spec.template.spec.nodeSelector`) | `{}` |
| `global.serviceName` | Name for the service whose type is ClusterIP | `galera-k8s-svc` |
| `multiPod.enabled` | If `true`, pods as many as `multiPod.replicaCount` are created(single pod is created otherwise) | `true` |
| `muliPod.replicaCount` | The number of pods created(only when `multiPod.enabled` is `true`) | `3` |
| `nodePort.enabled` | If `true`, the MariaDB server is exposed externally with port `nodePort.port` | `true` |
| `nodePort.nodeServiceName` | Name for the service whose type is NodePort | `galera-k8s-node` |
| `nodePort.port` | The external port number of the MariaDB server(only when `nodePort.enabled` is `true`) | `31002` |
| `image.registry` | Address of registry which galera-k8s image exists in | `docker.io` |
| `image.repository` | Repository of galera-k8s image | `josh9191/galera-k8s` |
| `image.tag` | Tag of galera-k8s image(a tag denotes version) | `v0.0.0` |
| `image.pullPolicy` |  Pulling policy of galera-k8s image | `IfNotPresent` |
| `imageCredentials.name` | The name of the image credential(set it as whatever you like as long as it doesn't exist) | `""` |
| `imageCredentials.registry` | Address of registry which the credential is applied to | `docker.io` |
| `imageCredentials.username` | User name used to login to the registry | `""` |
| `imageCredentials.password` | Password of the user | `""` |
| `resources.limits.cpu` | The CPU usage limit of the container after creation | `1000m` |
| `resources.limits.memory` | The memory usage limit of the container after creation | `1024M` |
| `resources.requests.cpu` | The CPU usage limit of the container when it is created | `500m` |
| `resources.requests.memory` | The memory usage limit of the container when it is created | `1024M` |
| `persistence.enabled` | Use persistent volume or not(it is highly recommended to use persistence) | `true` |
| `persistence.size` | Capacity of persistent volume | `5Gi` |
| `persistence.matchLabels` | `matchLabels` which newly created PVC uses to match a persistent volume(if you already have PV, you can use matchLabels instead of storageClass) | `{}` |
| `persistence.storageClass` | Name of StorageClass(please set to "-" if you don't have it) if you want to create PV dynamically(dynamic volume provisioning) | `nfs-client` |
| `persistence.accessMode` | Access mode of the claim | `ReadWriteMany` |
| `persistence.subPath` | Subpath of the directory in persistent volume which data will be stored in | `mariadb` |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```bash
## Helm 2
$ helm install --namespace my-ns --name my-release \
    --set persistence.size=10Gi \
    --set persistence.storageClassName=my-nfs-sc \
    --set persistence.subPath=my-db-data \
    galera-k8s/helm

## Helm 3
$ helm install --namespace my-ns my-release \
    --set persistence.size=10Gi \
    --set persistence.storageClassName=my-nfs-sc \
    --set persistence.subPath=my-db-data \
    galera-k8s/helm 
```

