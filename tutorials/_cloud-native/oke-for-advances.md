---
title: "在 Oracle Container Engine for Kubernetes (OKE) 上部署示例微服务应用程序并使用可观察性工具"
excerpt: "让您体验使用 OKE 的示例微服务应用程序的部署和可观察性的内容。我们将使用 OSS Istio、Prometheus、Grafana、Loki、Jaeger 和 Kiali 作为第三方。"
order: "031"
tags:
---

在本次实践中，我们将在 Oracle Container Engine for Kubernetes (OKE) 之上部署一个微服务应用程序。然后，使用 OSS 可观察性工具，您将通过动手实践学习监控、日志记录和跟踪。

作为可观察性工具，我们使用：

***监控***

* [普罗米修斯](https://github.com/prometheus/prometheus) + [Grafana](https://github.com/grafana/grafana)

***记录***

* [Grafana Loki](https://github.com/grafana/loki)

*** 追踪 ***

* [Jaeger](https://github.com/jaegertracing/jaeger)

***服务网格可观察性***

* [Kiali](https://github.com/kiali/kiali)

动手流程如下。

---
1、搭建OKE集群
    1.从OCI仪表板构建OKE集群
    2. 使用 Cloud Shell 操作集群

2、Service Mesh和可观察环境的搭建
    1. 安装 Istio（插件：Prometheus、Grafana、Jaeger、Kiali）
    2. Grafana Loki 安装
    3. 设置 Grafana Loki
    4.安装节点导出器
    5. 从 Prometheus WebUI 运行 PromQL

3. 通过示例应用程序体验可观察性
    1. 示例应用程序概述
    2. 构建和部署示例应用程序
    3. 使用 Grafana Loki 进行日志监控
    4. 使用 Jaeger 进行跟踪
    5. 使用 Kiali 实现 Service Mesh 的可视化

4. 使用 Istio 发布金丝雀
    1. 金丝雀发布

---

1、搭建OKE集群
---------------------------------

### 1-1 从 OCI 仪表板构建 OKE 集群

展开左上角的汉堡菜单，从“开发者服务”中选择“Kubernetes Cluster (OKE)”。

![](1-001.png)

单击创建集群按钮。

![](1-002.png)

确保选择了快速创建并单击启动工作流按钮。

![](1-003.png)

设置以下内容：

Kubernetes Worker 节点：Public Workers
“形状”：“VM Standard.E3.Flex”
“选择 OCPU 数量”：“2”
“内存量（GB）”：“32”

![](1-004.png)

单击屏幕左下方的“下一步”按钮。

![](1-005.png)

单击屏幕左下方的“创建集群”按钮。

![](1-006.png)

单击屏幕左下方的“关闭”按钮。

![](1-007.png)

确认它从黄色的“Creating”变为绿色的“Active”。如果是“Active”，则集群创建完成。

![](1-008.png)

### 1-2 使用 Cloud Shell 操作集群

使用 Cloud Shell 连接到创建的 Kubernetes 集群。

单击访问集群按钮。

![](1-009.png)

单击“启动 Cloud Shell”按钮，然后单击“复制”链接文本，然后单击“关闭”按钮。

![](1-010.png)

启动 Cloud Shell 后，粘贴“复制”的内容，然后按 Enter 键。

![](1-011.png)

执行以下命令确认3个节点的“STATUS”为“Ready”。

```sh
kubectl get nodes
```
***命令结果***
```sh
NAME          STATUS   ROLES   AGE   VERSION
10.0.10.111   Ready    node    61m   v1.20.8
10.0.10.254   Ready    node    61m   v1.20.8
10.0.10.87    Ready    node    61m   v1.20.8
```

2、Service Mesh和可观察性环境搭建
---------------------------------

### 2-1 安装 Istio（插件：Prometheus、Grafana、Jaeger、Kiali）

安装“Istio 1.11.0”。

使版本值成为变量。

```sh
ISTIO_VERSION=1.11.0
```

从官方下载你需要安装的东西。

```sh
curl -L https://istio.io/downloadIstio | ISTIO_VERSION="${ISTIO_VERSION}" sh -
```
***命令结果***
```sh
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   102  100   102    0     0    213      0 --:--:-- --:--:-- --:--:--   212
100  4549  100  4549    0     0   6425      0 --:--:-- --:--:-- --:--:--  6425

Downloading istio-1.11.0 from https://github.com/istio/istio/releases/download/1.11.0/istio-1.11.0-linux-amd64.tar.gz ...

Istio 1.11.0 Download Complete!

Istio has been successfully downloaded into the istio-1.11.0 folder on your system.

Next Steps:
See https://istio.io/latest/docs/setup/install/ to add Istio to your Kubernetes cluster.

To configure the istioctl client tool for your workstation,
add the /home/yutaka_ich/istio-1.11.0/bin directory to your environment path variable with:
         export PATH="$PATH:/home/yutaka_ich/istio-1.11.0/bin"

Begin the Istio pre-installation check by running:
         istioctl x precheck 

Need more information? Visit https://istio.io/latest/docs/setup/install/ 
```

传递路径，以便执行 istioctl 命令。

```sh
export PATH="${PWD}/istio-${ISTIO_VERSION}/bin:${PATH}"
```

检查 Istio 的版本。 通过显示版本，可以使用 istioctl 命令。

```sh
istioctl version
```
***命令结果***
```sh
no running Istio pods in "istio-system"
1.11.0
```

安装 Istio 组件。

```sh
istioctl install --set profile=demo --skip-confirmation
```
***命令结果***
```sh
✔ Istio core installed                                                                                                                           
✔ Istiod installed                                                                                                                               
✔ Egress gateways installed                                                                                                                      
✔ Ingress gateways installed                                                                                                                     
✔ Installation complete                                                                                                                          
Thank you for installing Istio 1.11.  Please take a few minutes to tell us about your install/upgrade experience!  https://forms.gle/kWULBRjUv7hHci7T6
```

安装必要的附加组件（Prometheus、Grafana、Kiali、Jaeger 等）。

```sh
kubectl apply -f "istio-${ISTIO_VERSION}/samples/addons/"
```
***命令结果***
```sh
serviceaccount/grafana created
configmap/grafana created
service/grafana created
deployment.apps/grafana created
configmap/istio-grafana-dashboards created
configmap/istio-services-grafana-dashboards created
deployment.apps/jaeger created
service/tracing created
service/zipkin created
service/jaeger-collector created
serviceaccount/kiali created
configmap/kiali created
clusterrole.rbac.authorization.k8s.io/kiali-viewer created
clusterrole.rbac.authorization.k8s.io/kiali created
clusterrolebinding.rbac.authorization.k8s.io/kiali created
role.rbac.authorization.k8s.io/kiali-controlplane created
rolebinding.rbac.authorization.k8s.io/kiali-controlplane created
service/kiali created
deployment.apps/kiali created
serviceaccount/prometheus created
configmap/prometheus created
clusterrole.rbac.authorization.k8s.io/prometheus created
clusterrolebinding.rbac.authorization.k8s.io/prometheus created
service/prometheus created
deployment.apps/prometheus created
```

添加设置以自动将 Istio 使用的 sidecar 代理插入 Pod。

```sh
kubectl label namespace default istio-injection=enabled
```
***命令结果***
```sh
namespace/default labeled
```

目前，无法从 Kubernetes 集群外部访问它。
这样您就可以从浏览器访问作为附加组件安装的 Prometheus、Grafana、Kiali 和 Jaeger 的 Web 控制台，
在每个组件的 Service 对象中设置 `NodePort`。

```sh
kubectl patch service prometheus -n istio-system -p '{"spec": {"type": "NodePort"}}'
```
***命令结果***
```sh
service/prometheus patched
```

---

```sh
kubectl patch service grafana -n istio-system -p '{"spec": {"type": "NodePort"}}'
```
***命令结果***
```sh
service/grafana patched
```

---

```sh
kubectl patch service kiali -n istio-system -p '{"spec": {"type": "NodePort"}}'
```
***命令结果***
```sh
service/kiali patched
```

---

```sh
kubectl patch service tracing -n istio-system -p '{"spec": {"type": "NodePort"}}'
```
***命令结果***
```sh
service/tracing patched
```

---

检查服务和部署的状态。
确保“service/prometheus”、“service/grafana”、“service/kiali”和“service/tracing”的TYPE是`NodePort`。 对于“service/istio-ingressgateway”，一段时间后会自动分配一个EXTERNAL-IP地址。

```sh
kubectl get services,deployments -n istio-system -o wide
```
***命令结果***
```sh
NAME                           TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                                                                      AGE     SELECTOR
service/grafana                NodePort       10.96.142.228   <none>           3000:30536/TCP                                                               96s     app.kubernetes.io/instance=grafana,app.kubernetes.io/name=grafana
service/istio-egressgateway    ClusterIP      10.96.50.236    <none>           80/TCP,443/TCP                                                               2m9s    app=istio-egressgateway,istio=egressgateway
service/istio-ingressgateway   LoadBalancer   10.96.197.12    168.138.xx.xxx   15021:31268/TCP,80:32151/TCP,443:30143/TCP,31400:30084/TCP,15443:32534/TCP   2m9s    app=istio-ingressgateway,istio=ingressgateway
service/istiod                 ClusterIP      10.96.80.173    <none>           15010/TCP,15012/TCP,443/TCP,15014/TCP                                        2m28s   app=istiod,istio=pilot
service/jaeger-collector       ClusterIP      10.96.223.176   <none>           14268/TCP,14250/TCP,9411/TCP                                                 95s     app=jaeger
service/kiali                  NodePort       10.96.65.161    <none>           20001:32446/TCP,9090:31546/TCP                                               95s     app.kubernetes.io/instance=kiali,app.kubernetes.io/name=kiali
service/prometheus             NodePort       10.96.227.118   <none>           9090:32582/TCP                                                               94s     app=prometheus,component=server,release=prometheus
service/tracing                NodePort       10.96.67.34     <none>           80:31870/TCP,16685:32400/TCP                                                 95s     app=jaeger
service/zipkin                 ClusterIP      10.96.222.186   <none>           9411/TCP                                                                     95s     app=jaeger

NAME                                   READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS                                             IMAGES                                                       SELECTOR
deployment.apps/grafana                1/1     1            1           95s     grafana                                                grafana/grafana:7.5.5                                        app.kubernetes.io/instance=grafana,app.kubernetes.io/name=grafana
deployment.apps/istio-egressgateway    1/1     1            1           2m9s    istio-proxy                                            docker.io/istio/proxyv2:1.11.0                               app=istio-egressgateway,istio=egressgateway
deployment.apps/istio-ingressgateway   1/1     1            1           2m9s    istio-proxy                                            docker.io/istio/proxyv2:1.11.0                               app=istio-ingressgateway,istio=ingressgateway
deployment.apps/istiod                 1/1     1            1           2m28s   discovery                                              docker.io/istio/pilot:1.11.0                                 istio=pilot
deployment.apps/jaeger                 1/1     1            1           95s     jaeger                                                 docker.io/jaegertracing/all-in-one:1.23                      app=jaeger
deployment.apps/kiali                  1/1     1            1           95s     kiali                                                  quay.io/kiali/kiali:v1.38                                    app.kubernetes.io/instance=kiali,app.kubernetes.io/name=kiali
deployment.apps/prometheus             1/1     1            1           94s     prometheus-server-configmap-reload,prometheus-server   jimmidyson/configmap-reload:v0.5.0,prom/prometheus:v2.26.0   app=prometheus,component=server,release=prometheus
```
接下来，更改安全列表以允许从 Web 浏览器通过 NodePort 进行访问。

在 OCI 控制台中，选择 [Networking]-[Virtual Cloud Network] 并选择目标 `oke-vcn-quick-cluster1-xxxxxxxxx`。

![](1-027.png)

![](1-032.png)

在三个子网中，选择worker节点所属的子网`oke-nodesubnet-quick-cluster1-xxxxxxxxx-regional`。

![](1-028.png)

从列表中选择“oke-nodeseclist-quick-cluster1-xxxxxxxxx”。

![](1-029.png)

单击添加入口规则按钮。

![](1-030.png)

设置以下内容并单击添加入口规则按钮。

`源 CIDR：0.0.0.0/0`<br>
`目标端口范围：30000-65535`

![](1-031.png)

这样就完成了安全列表的修改。

接下来，检查使用 Web 浏览器访问的节点的“EXTERNAL-IP”。
可以使用任何要使用的“EXTERNAL-IP”。使用网络浏览器时请选择一项。

```sh
kubectl get nodes -o wide
```
***命令结果***
```sh
NAME          STATUS   ROLES   AGE   VERSION   INTERNAL-IP   EXTERNAL-IP     OS-IMAGE                  KERNEL-VERSION                      CONTAINER-RUNTIME
10.0.10.111   Ready    node    61m   v1.20.8   10.0.10.111   140.83.60.38    Oracle Linux Server 7.9   5.4.17-2102.204.4.4.el7uek.x86_64   cri-o://1.20.2
10.0.10.254   Ready    node    60m   v1.20.8   10.0.10.254   140.83.50.44    Oracle Linux Server 7.9   5.4.17-2102.204.4.4.el7uek.x86_64   cri-o://1.20.2
10.0.10.87    Ready    node    60m   v1.20.8   10.0.10.87    140.83.84.231   Oracle Linux Server 7.9   5.4.17-2102.204.4.4.el7uek.x86_64   cri-o://1.20.2
```

检查 Prometheus、Grafana、Kiali 和 Jaeger 的 `NodePort`。
PORT(S) ``xxxxx:30000'' TYPE 为 `NodePort` 的 Service，冒号后 30000 以上的端口号为 `NodePort` 号。

**关于 Jaeger 服务名称**
请注意，服务名称仅针对 Jaeger 进行跟踪。
{: .notice--warning}

* Prometheus:prometheus
* Grafana:grafana
* Kiali:kiali
* Jaeger:tracing

```sh
kubectl get services -n istio-system
```
***命令结果***
```sh
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                                                                      AGE
grafana                NodePort       10.96.142.228   <none>           3000:30536/TCP                                                               11m
istio-egressgateway    ClusterIP      10.96.50.236    <none>           80/TCP,443/TCP                                                               11m
istio-ingressgateway   LoadBalancer   10.96.197.12    168.138.xx.xxx   15021:31268/TCP,80:32151/TCP,443:30143/TCP,31400:30084/TCP,15443:32534/TCP   11m
istiod                 ClusterIP      10.96.80.173    <none>           15010/TCP,15012/TCP,443/TCP,15014/TCP                                        12m
jaeger-collector       ClusterIP      10.96.223.176   <none>           14268/TCP,14250/TCP,9411/TCP                                                 11m
kiali                  NodePort       10.96.65.161    <none>           20001:32446/TCP,9090:31546/TCP                                               11m
prometheus             NodePort       10.96.227.118   <none>           9090:32582/TCP                                                               11m
tracing                NodePort       10.96.67.34     <none>           80:31870/TCP,16685:32400/TCP                                                 11m
zipkin                 ClusterIP      10.96.222.186   <none>           9411/TCP                                                                     11m
```

以上面的命令结果为例，冒号后面的端口号将是30000或更多。
请用你自己的替换它。

* Prometheus 9090:32582
* Grafana 3000:30536
* Kiali 20001:32446
* Jaeger 80:31870

指定您之前检查的 EXTERNAL-IP 和每个“NodePort”，并从 Web 浏览器访问。

`http://EXTERNAL-IP:NodePort/`

### 2-2 Grafana Loki 安装

使用 Helm 安装 Grafana Loki。

**关于 Helm**
Helm 是 Kubernetes 的包管理器。 该包称为 Chart 并有一个存储库。
将 Helm 想象为 Linux 的 dnf 和 apt，将 Chart 想象为 rpm 和 deb。
chart是一个manifest模板（模型），模板中指定的变量的参数定义在values.yaml中，
这个 Chart 和 values.yaml 的组合是一种生成新清单并在 Kubernetes 集群中注册的机制。
通过使用这个 Helm 模板化 manifest，可以提高管理效率，使 manifest 不会变大。
{: .notice--info}

添加 Grafana 官方 Helm 图表存储库。

```sh
helm repo add grafana https://grafana.github.io/helm-charts
```
***命令结果***
```sh
WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: /home/yutaka_ich/.kube/config
WARNING: Kubernetes configuration file is world-readable. This is insecure. Location: /home/yutaka_ich/.kube/config
"grafana" has been added to your repositories
```

更新 Helm 仓库。

```sh
helm repo update
```
***命令结果***
```sh
WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: /home/yutaka_ich/.kube/config
WARNING: Kubernetes configuration file is world-readable. This is insecure. Location: /home/yutaka_ich/.kube/config
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "argo" chart repository
...Successfully got an update from the "grafana" chart repository
Update Complete. ⎈Happy Helming!⎈
```

安装 Grafana Loki。

```sh
helm upgrade --install loki --namespace=istio-system grafana/loki-stack
```
***命令结果***
```sh
WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: /home/yutaka_ich/.kube/config
WARNING: Kubernetes configuration file is world-readable. This is insecure. Location: /home/yutaka_ich/.kube/config
Release "loki" does not exist. Installing it now.
NAME: loki
LAST DEPLOYED: Sun Aug 22 07:22:15 2021
NAMESPACE: istio-system
STATUS: deployed
REVISION: 1
NOTES:
The Loki stack has been deployed to your cluster. Loki can now be added as a datasource in Grafana.

See http://docs.grafana.org/features/datasources/loki/ for more detail.
```

确认“Loki-0”和“loki-promtail-xxxxx”（3 件）正在运行。

```sh
kubectl get pods -n istio-system
```
***命令结果***
```sh
NAME                                    READY   STATUS    RESTARTS   AGE
grafana-556f8998cd-bkrw8                1/1     Running   0          36m
istio-egressgateway-9dc6cbc49-rv9ll     1/1     Running   0          37m
istio-ingressgateway-7975cdb749-tk4rf   1/1     Running   0          37m
istiod-77b4d7b55d-tq7hh                 1/1     Running   0          37m
jaeger-5f65fdbf9b-28v7w                 1/1     Running   0          36m
kiali-787bc487b7-jkc22                  1/1     Running   0          36m
loki-0                                  1/1     Running   0          2m46s
loki-promtail-lzxg5                     1/1     Running   0          2m46s
loki-promtail-rlrq2                     1/1     Running   0          2m46s
loki-promtail-s7rfz                     1/1     Running   0          2m46s
prometheus-9f4947649-c7swm              2/2     Running   0          36m
```

### 2-3 设置 Grafana Loki

去格拉法纳。

```sh
kubectl get services grafana -n istio-system
```
***命令结果***
```
NAME      TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
grafana   NodePort   10.96.142.228   <none>        3000:30536/TCP   127m
```

NodePort 用于访问 Grafana。
NodePort 是 `PORT(S)` 中 `:` 后面的端口号。
在上述情况下，请访问以下 URL。
http://[WorkerNode公网IP]:30536

从左侧菜单中选择【配置】-【数据源】。

![](1-012.png)

单击添加数据源按钮。

![](1-013.png)

将光标移动到“日志和文档数据库”中的“Loki”，然后单击“选择”按钮。

![](1-014.png)

在 Loki 设置画面的“URL”中输入`http://loki:3100/`，在“Maximum lines”中输入`1000`，然后单击“Save & Test”按钮。

![](1-015.png)

在左侧菜单中选择“探索”。

![](1-016.png)

画面切换后，从画面左上方的下拉菜单中选择“Loki”。

![](1-017.png)

在“日志浏览器”中输入 `{app="istiod"}`，然后单击“运行查询”按钮。

![](1-018.png)

如果可以看到日志，则说明设置完成。

### 2-4 安装节点导出器

在每个节点上部署节点导出器以收集每个节点的指标。

使用已经创建的节点导出器清单并将其应用到 Kubernetes 集群。

```sh
kubectl apply -f https://raw.githubusercontent.com/oracle-japan/ochacafe-s4-6/main/manifests/node-exporter-handson.yaml
```
***命令结果***
```sh
serviceaccount/node-exporter-handson created
service/node-exporter-handson created
daemonset.apps/node-exporter-handson created
```

确保名为“node-exporter-handson”的 pod 的状态为“正在运行”。

```sh
kubectl get pods
```
***命令结果***
```
NAME                          READY   STATUS    RESTARTS   AGE
node-exporter-handson-56m4h   1/1     Running   0          25s
node-exporter-handson-r7br8   1/1     Running   0          25s
node-exporter-handson-rr2rf   1/1     Running   0          25s
```
### 2-5 从 Prometheus WebUI 执行 PromQL

从 Prometheus WebUI 执行 PromQL，查看 3 个节点中每个节点的空闲内存空间和 3 个节点的总空闲内存空间。
首先，在浏览器中访问 Prometheus WebUI。

```sh
kubectl get services prometheus -n istio-system
```
***命令结果***
```
NAME         TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
prometheus   NodePort   10.96.227.118   <none>        9090:32582/TCP   136m
```

NodePort 用于访问 Grafana。
NodePort 是 `PORT(S)` 中 `:` 后面的端口号。
在上述情况下，请访问以下 URL。
http://[WorkerNode公网IP]:32582

![](1-019.png)

输入 `node_memory_MemAvailable_bytes` 并单击“执行”按钮。

![](1-020.png)

显示每个节点的可用内存容量。单击“图表”选项卡以查看图表。

![](1-021.png)

![](1-022.png)

单击“表格”选项卡后，检查最后 3 分钟的情况。

![](1-023.png)

输入 `node_memory_MemAvailable_bytes[3m]` 并单击“执行”按钮。
显示每个节点最近3分钟的空闲内存容量状态。

![](1-024.png)

接下来，检查3个节点的空闲内存空间。

输入 `sum without (instance, kubernetes_node) (node_memory_MemAvailable_bytes)` 并点击“执行”按钮。

PromQL 使用 without 排除实例和 kubernetes_node 标签并输出 3 个节点的总和。

![](1-025.png)

您还可以通过单击“图表”选项卡来检查图表。

![](1-026.png)

PromQL 是 Prometheus 自己的查询语言，专门用于度量聚合。本实践中使用的查询就是一个示例。
有很多方法可以使用它。更多信息请参见【官方参考】（https://prometheus.io/docs/prometheus/latest/querying/basics/）。

3.通过示例应用程序体验可观察性
---------------------------------

在这一步中，我们将针对步骤 1 和 2 中构建的 Observability 环境部署示例应用程序。

### 3-1 示例应用程序概述

首先，移动到您的主目录并克隆以下 Git 存储库。

```sh
cd ~
```

```sh
git clone https://github.com/oracle-japan/code-at-customer-handson
```

为此实践创建的示例应用程序。
我将简要介绍一下内容。

```sh
.
├── README.md
├── k8s ==> KubernetesのMainifest群
├── olympic_backend ==> バックエンドアプリケーション
├── olympic_datasource ==> データソースアプリケーション
├── olympic_frontend ==> フロントエンドアプリケーション
.
```
此示例应用程序主要包含以下内容：

* [Helidon](https://oracle-japan-oss-docs.github.io/helidon/docs/v2/#/about/01_overview)
  * Oracle 作为开源提供的 Java 微服务框架
* [Oracle JavaScript 扩展工具包 (Oracle JET)](https://www.oracle.com/jp/application-development/technologies/jet/oracle-jet.html)
  * Oracle 开发的开源 Javascript 框架
  * 添加高级功能和服务，以帮助开发人员更快地构建更好的应用程序，基于行业标准的开源框架

让我们快速浏览一下应用程序的组成。
完成此步骤后，整体图像应如下所示：

![](3-001.png)

它由顶部的示例应用程序和底部的可观察性环境组成。
因此，从现在开始，我们将主要看顶部的示例应用程序。

另外，这次我们将使用 istio-ingressgateway 和 NodePort 来访问应用程序。
作为一个实体，istio-ingressgateway 使用 Oracle 云基础设施负载平衡服务，NodePort 使用将成为工作节点的计算实例的公共 IP 和端口。
因此，Oracle Cloud Infrastructure 的配置如下图所示。

![](3-031.png)

此示例应用程序由三个组件组成：

* 前端应用（图中`Olympics`）
  由 Helidon 和 Oracle JET 组成的应用程序。
  Oracle JET 内容放置在 Helidon 的静态内容根目录中（在本例中位于“resources/web”下）。
  此应用程序调用后端服务之一 (v1/v2/v3)。

* 后端应用（图中绿框部分）
  由 Helidon 组成的应用程序。
  此应用程序有三个版本，每个版本都会返回金牌得主 (v3)、银牌得主 (v2) 和铜牌得主 (v1) 的列表。
  版本信息存储为环境变量。
  该应用程序向数据源应用程序调用版本对应的API端点来获取数据。

* 数据源应用（图中`Medal Info`）
  该应用程序由 Helidon 和 [H2 Database](https://www.h2database.com/html/main.html) 组成，后者是一个运行在内存中的数据库。
  在这个应用程序中，存储了奖牌获得者和获得奖牌的颜色，并根据后端应用调用的端点返回奖牌获得者和奖牌颜色。

### 3-2 构建和部署示例应用程序

现在让我们构建一个包含这些应用程序的容器镜像。

首先，从前端应用程序构建。

**关于Helidon **
Helidon 可以使用 `Maven` 创建项目模板。
有关命令，请查看 [此处](https://helidon.io/docs/v2/#/mp/guides/02_quickstart)。
默认情况下，它还包含一个 Dockerfile。
后面用到的 Dockerfile 也基本使用了上面的模板文件。
Helidon 还有一个方便的 CLI 工具，称为 Helidon CLI。
对于 Helidon CLI，请查看 [此处](https://oracle-japan.github.io/ocitutorials/cloud-native/helidon-mp-for-beginners/)。
{: .notice--info}

```sh
cd code-at-customer-handson/olympic_frontend
```

```sh
docker image build -t code-at-customer/frontend-app .
```

***命令结果***
```sh
~~~~
Status: Downloaded newer image for openjdk:11-jre-slim
 ---> e4beed9b17a3
Step 9/13 : WORKDIR /helidon
 ---> Running in bbbeffe84be8
Removing intermediate container bbbeffe84be8
 ---> 518c68977ccc
Step 10/13 : COPY --from=build /helidon/target/olympic_frontend.jar ./
 ---> 6eb033c8d5ab
Step 11/13 : COPY --from=build /helidon/target/libs ./libs
 ---> d46766254734
Step 12/13 : CMD ["java", "-jar", "olympic_frontend.jar"]
 ---> Running in b2e205e5b9ed
Removing intermediate container b2e205e5b9ed
 ---> a042893b3e8e
Step 13/13 : EXPOSE 8080
 ---> Running in 7e3a2bb12ed4
Removing intermediate container 7e3a2bb12ed4
 ---> b96ac0669f0d
Successfully built b96ac0669f0d
Successfully tagged code-at-customer/frontend-app:latest
```

构建现已完成。 ​​​​

让我们检查构建的容器映像。

```sh
docker image ls
```

***命令结果***
```sh
REPOSITORY                           TAG        IMAGE ID       CREATED         SIZE
code-at-customer/frontend-app        latest     5ee35f1e2a49   3 minutes ago   270MB
~~~~
```
通常，您会将构建的镜像推送到 OCIR（Oracle Cloud Infrastructure Registry），但这次容器镜像已经推送，所以我将省略它。

**关于推送到 OCIR（Oracle 云基础设施注册表）**
将构建的容器映像推送到 OCIR 时，需要使用 Oracle Cloud Infrastructure 命名空间和 OCIR 区域对其进行标记。
详情 [这里](https://oracle-japan.github.io/ocitutorials/cloud-native/oke-for-beginners/#2ocir%E3%81%B8%E3%81%AE%E3%83%97 % E3%83%83%E3%82%B7%E3%83%A5%E3%81%A8oke%E3%81%B8%E3%81%AE%E3%83%87%E3%83%97%E3 % 83%AD%E3%82%A4)。
{: .notice--info}

回到你的主目录。

``` 嘘
光盘~
```

让我们以相同的方式构建后端应用程序容器。

如上所述，后端应用程序具有三个版本。
这一次，我们准备了一个将版本信息作为环境变量的 Dockerfile，因此请分别构建。

例如，返回 v1 铜牌获得者的后端应用程序具有以下 Dockerfile，并使用 ENV 和 ARG 指令进行定义。

```Dockerfile

# 1st stage, build the app
FROM maven:3.6-jdk-11 as build

WORKDIR /helidon

# Create a first layer to cache the "Maven World" in the local repository.
# Incremental docker builds will always resume after that, unless you update
# the pom
ADD pom.xml .
RUN mvn package -Dmaven.test.skip -Declipselink.weave.skip

# Do the Maven build!
# Incremental docker builds will resume here when you change sources
ADD src src
RUN mvn package -DskipTests
RUN echo "done!"

# 2nd stage, build the runtime image
FROM openjdk:11-jre-slim
WORKDIR /helidon

# Copy the binary built in the 1st stage
COPY --from=build /helidon/target/olympic_backend.jar ./
COPY --from=build /helidon/target/libs ./libs

ARG SERVICE_VERSION=V1
ENV SERVICE_VERSION=${SERVICE_VERSION}

CMD ["java", "-jar", "olympic_backend.jar"]

EXPOSE 8080
```
`ARG SERVICE_VERSION=V1`（默认值为V1）在构建时获取`--build-arg`选项指定的版本，
它被定义为带有`ENV SERVICE_VERSION=${SERVICE_VERSION}`的环境变量。

**ENV 和 ARG 指令**
在 Dockerfile 中，在处理容器内的环境变量时会准备 ENV 指令。
ENV 指令是一组环境变量和值，可用于从 Dockerfile 派生的所有命令环境。
此外，如果使用 ARG 命令，则可以在执行 `docker image build` 命令时使用 `--build-arg` 选项指定的变量。
详情请查看[这里](https://docs.docker.jp/engine/reference/builder.html)。
{: .notice--info}

这次有三个版本，所以让我们构建每个版本。

```sh
cd code-at-customer-handson/olympic_backend
```

构建 V1。
V1 是默认值，所以你不必给出 `--build-arg` 选项，但是这次我们将尝试使用该选项进行构建。

```sh
docker image build -t code-at-customer/backend-app-v1 --build-arg SERVICE_VERSION=V1 .
```

***命令结果***

```sh
~~~~
Successfully tagged code-at-customer/backend-app-v1:latest
```

让我们检查构建的容器映像。

```sh
docker image ls
```

***命令结果***(順不同になる可能性があります)
```sh
REPOSITORY                           TAG        IMAGE ID       CREATED          SIZE
code-at-customer/frontend-app        latest     5ee35f1e2a49   13 minutes ago   270MB
code-at-customer/backend-app-v1      latest     f585e32a1147   27 minutes ago   243MB
~~~~
```

我们将以相同的方式构建 V2 和 V3，但由于需要时间，因此我们将省略它。
构建 V2 和 V3 会创建一个容器镜像，如下所示。

```sh
REPOSITORY                           TAG        IMAGE ID       CREATED          SIZE
code-at-customer/frontend-app        latest     5ee35f1e2a49   15 minutes ago   270MB
code-at-customer/backend-app-v1      latest     9ba2a2183e29   39 minutes ago   243MB
code-at-customer/backend-app-v2      latest     9ba2a2183e29   39 minutes ago   243MB
code-at-customer/backend-app-v3      latest     bb7e737e4940   About a minute ago   243MB
~~~~
```

通常，您会将构建的镜像推送到 OCIR（Oracle Cloud Infrastructure Registry），但这次容器镜像已经推送，所以我将省略它。

回到你的主目录。

```sh
cd ~
```

最后，让我们也构建数据源应用程序容器。

```sh
cd code-at-customer-handson/olympic_datasource
```

```sh
docker image build -t code-at-customer/datasource-app .
```

***命令结果***

```sh
~~~~
Successfully tagged code-at-customer/datasource-app:latest
```

让我们检查构建的容器映像。

```sh
docker image ls
```

***命令结果***(順不同になる可能性があります)
```sh
REPOSITORY                           TAG        IMAGE ID       CREATED          SIZE
code-at-customer/frontend-app        latest     5ee35f1e2a49   15 minutes ago   270MB
code-at-customer/backend-app-v1      latest     9ba2a2183e29   39 minutes ago   243MB
code-at-customer/backend-app-v2      latest     9ba2a2183e29   39 minutes ago   243MB
code-at-customer/backend-app-v3      latest     9ba2a2183e29   39 minutes ago   243MB
code-at-customer/datasource-app      latest     3a542bedb13a   43 seconds ago   261MB
~~~~
```

通常，您会将构建的镜像推送到 OCIR（Oracle Cloud Infrastructure Registry），但这次容器镜像已经推送，所以我将省略它。

现在所有应用程序都已构建。

回到你的主目录。

```sh
cd ~
```

接下来，我们将容器应用部署到 k8s。

移动到刚刚克隆的存储库中的“k8s”目录。

```sh
cd code-at-customer-handson/k8s
```

部署之前构建的容器应用的Manifest在`app`目录下，所以部署下所有文件。
```sh
cd app/plain
```

```sh
kubectl apply -f .
```

***命令结果***

```sh
deployment.apps/backend-app-v1 created
deployment.apps/backend-app-v2 created
deployment.apps/backend-app-v3 created
service/backend-app created
deployment.apps/datasource-app created
service/datasource-app created
deployment.apps/frontend-app created
service/frontend-app created
ingress.networking.k8s.io/gateway created
```

示例应用程序现在部署在 OKE 上。

检查部署状态。

```sh
kubectl get pods
```

***命令结果***

```sh
NAME                              READY   STATUS    RESTARTS   AGE
backend-app-v1-5c674f559f-fg2dq   2/2     Running   0          1m
backend-app-v1-5c674f559f-npjk4   2/2     Running   0          1m
backend-app-v2-84f5859c9f-gr6dd   2/2     Running   0          1m
backend-app-v2-84f5859c9f-pmnfl   2/2     Running   0          1m
backend-app-v3-7596dcf967-7dqnq   2/2     Running   0          1m
backend-app-v3-7596dcf967-tbhhw   2/2     Running   0          1m
datasource-app-7bc89cbdfc-pktdp   2/2     Running   0          1m
datasource-app-7bc89cbdfc-vmpr6   2/2     Running   0          1m
frontend-app-75c8986f76-lnhtg     2/2     Running   0          1m
frontend-app-75c8986f76-q5l44     2/2     Running   0          1m
node-exporter-handson-2mcph       1/1     Running   0          21m
node-exporter-handson-57qqq       1/1     Running   0          21m
node-exporter-handson-mbdzl       1/1     Running   0          21m
```

当一切都“正在运行”时，尝试访问应用程序。

通过第 2 步中创建的 `istio-ingressgateway` 进行访问。
首先，检查 `istio-ingressgateway` 端点。

```sh
kubectl get services istio-ingressgateway -n istio-system
```

***命令结果***

```sh
NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP       PORT(S)                                                                      AGE
istio-ingressgateway   LoadBalancer   10.96.176.93   132.226.xxx.xxx   15021:30134/TCP,80:30850/TCP,443:30319/TCP,31400:31833/TCP,15443:30606/TCP   3d3h
```

在上面的例子中，endpoint 是 `132.226.xxx.xxx`，它是 istio-ingressgateway 的 `EXTERNAL-IP`。

在这种情况下，请访问以下 URL。
`http://132.226.xxx.xxx`

出现如下画面就OK了！

![](3-002.png)

如果您尝试多次访问它，您会看到金牌得主 (v3)、银牌得主 (v2) 和铜牌得主 (v1) 是随机显示的。

回到你的主目录。

```sh
cd ~
```
### 3-3 使用 Grafana Loki 进行日志监控

在这里，我们来监控3-2中部署的应用程序的日志。

首先，访问 Grafana。

```sh
kubectl get services grafana -n istio-system
```

***命令结果***

```sh
NAME      TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
grafana   NodePort   10.96.219.44   <none>        3000:31624/TCP   4d3h
```

NodePort 用于访问 Grafana。
NodePort 是 `PORT(S)` 中 `:` 后面的端口号。
在上述情况下，请访问以下 URL。
http://[WorkerNode公网IP]:31624

访问后，单击探索。

![](3-003.png)

从屏幕顶部的下拉菜单中选择 ![](3-004.png)。

![](3-005.png)

单击![](3-006.png)。

![](3-007.png) 显示要记录的标签。
这次我们以查看特定 Pod 的日志为例。

选择目标 Pod 名称。

```sh
kubectl get pods
```


***命令结果***

```sh
NAME                              READY   STATUS    RESTARTS   AGE
backend-app-v1-5c674f559f-fg2dq   2/2     Running   0          1m
backend-app-v1-5c674f559f-npjk4   2/2     Running   0          1m
backend-app-v2-84f5859c9f-gr6dd   2/2     Running   0          1m
backend-app-v2-84f5859c9f-pmnfl   2/2     Running   0          1m
backend-app-v3-7596dcf967-7dqnq   2/2     Running   0          1m
backend-app-v3-7596dcf967-tbhhw   2/2     Running   0          1m
datasource-app-7bc89cbdfc-pktdp   2/2     Running   0          1m
datasource-app-7bc89cbdfc-vmpr6   2/2     Running   0          1m
frontend-app-75c8986f76-lnhtg     2/2     Running   0          1m
frontend-app-75c8986f76-q5l44     2/2     Running   0          1m
node-exporter-handson-2mcph       1/1     Running   0          21m
node-exporter-handson-57qqq       1/1     Running   0          21m
node-exporter-handson-mbdzl       1/1     Running   0          21m
```
例如，目标 `backend-app-v2-84f5859c9f-gr6dd`。 （适应你的环境）

从 ![](3-008.png) 中选择 `pod` 以显示 pod 名称。
选择感兴趣的 Pod 名称，然后单击“显示日志”。

![](3-009.png)

显示目标 Pod 输出的日志。

![](3-010.png)

您还可以过滤和搜索 Loki 上的日志。

例如，在当前状态下，Istio 在 Pod 中注入的 Envoy 的日志也是输出的，所以我们只限于应用程序的日志。

在![](3-006.png)列的文本框中添加字符串`,container="backend-app"`，点击左上角的![](3-013.png)。
查询类似于 ![](3-030.png)。

现在我们可以将其缩小到名为 `backend-app-v2-84f5859c9f-gr6dd` 的 pod 中的名为 `backend-app` 的容器。

![](3-012.png)

使用 Grafana Loki 进行日志监控现已完成。

### 3-4 使用 Jaeger 进行跟踪

接下来，让我们尝试使用 Jaeger 进行跟踪。

首先，让我们访问应用程序并将跟踪信息发送给 Jaeger。

```sh
kubectl get services istio-ingressgateway -n istio-system
```

***命令结果***

```sh
NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP       PORT(S)                                                                      AGE
istio-ingressgateway   LoadBalancer   10.96.176.93   132.226.xxx.xxx   15021:30134/TCP,80:30850/TCP,443:30319/TCP,31400:31833/TCP,15443:30606/TCP   3d3h
```
在上面的例子中，endpoint 是 `132.226.xxx.xxx`，它是 istio-ingressgateway 的 `EXTERNAL-IP`。

在这种情况下，请访问以下 URL。
`http://132.226.xxx.xxx`

然后访问 Jaeger UI。

```sh
kubectl get services tracing -n istio-system
```

***命令结果***

```sh
NAME      TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                        AGE
tracing   NodePort   10.96.207.90   <none>        80:30483/TCP,16685:31417/TCP   4d4h
```
NodePort 用于 Jaeger 访问。
NodePort 是 `PORT(S)` 中 `:` 后面的端口号。
在上述情况下，请访问以下 URL。
http://[WorkerNode公网IP]:30483

访问后，单击 Service 类别中的下拉菜单，单击 `istio-ingress-gateway.istio.system`，然后单击 `Find Trace`。

![](3-014.png)

现在您可以看到通过 `istio-ingress-gateway` 路由的流量。

![](3-015.png)

这样就可以获取到四个服务的跟踪信息，`istio-ingress-gateway`、`frontend-app.default`、`backend-app.default`和`datasource-app.default`。

点击这个。

![](3-016.png)

通过这种方式，您可以看到一系列流量及其各自的延迟。

由于这是一个简单的应用程序，整个过程可以在每周几十到几百毫秒的时间内完成，但如果真的出现性能问题，你可以通过查看跟踪信息来了解哪个部分是瓶颈。你可以检查。

这样就完成了使用 Jaeger 的跟踪。

### 3-5 使用 Kiali 可视化 Service Mesh

接下来，让我们使用 Kiali 可视化 Service Mesh。

首先，打开 Kiali 的 UI。

```sh
kubectl get services kiali -n istio-system
```

***命令结果***

```sh
NAME    TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                          AGE
kiali   NodePort   10.96.251.81   <none>        20001:30768/TCP,9090:32228/TCP   4d4h
```
Kiali 访问使用 NodePort。
NodePort 是 `PORT(S)` 中 `:` 后面的端口号。
在上述情况下，请访问以下 URL。
http://[WorkerNode公网IP]:30768

创建一个“DestinationRule”，这是 Istio 的流量管理配置资源之一，用于在 Kiali 中进行可视化。
这是定义应用于服务资源的流量的策略的资源。

这一次，创建一个如下所示的 DestinationRule。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: backend
spec:
  host: backend-app
  trafficPolicy:
    loadBalancer:
      simple: RANDOM
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  - name: v3
    labels:
      version: v3
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: frontend
spec:
  host: frontend-app
  subsets:
  - name: v1
    labels:
      version: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: datasource
spec:
  host: datasource-app
  subsets:
  - name: v1
    labels:
      version: v1
```

例如，查看后端应用程序的目标规则（`backend`），

```yaml
  host: backend-app
  trafficPolicy:
    loadBalancer:
      simple: RANDOM
```
它为`host`定义了一个后端应用服务资源。

这一次，有 3 个 Deployment（3 个版本）与 `backend-app` 相关联。
`trafficPolicy:` 可以为多个 Deployment 定义分发策略。
这一次，由于是 `RANDOM`，流量将随机分配到与 `backend-app` 关联的 Deployments（本例中为三个）。

首先，让我们应用这个 DestinationRule。

返回您的主目录。

```sh
cd ~
```

```sh
cd code-at-customer-handson/k8s/base
```

```sh
kubectl apply -f destination_rule.yaml
```

***命令结果***

```sh
destinationrule.networking.istio.io/backend created
destinationrule.networking.istio.io/frontend created
destinationrule.networking.istio.io/datasource created
```
在这种状态下，让我们检查 Kiali 的 UI。

首先是“概述”。

![](3-017.png)

在这里，您可以看到 `default` 命名空间中有 4 个应用程序。
这四个应用程序是我们正在部署的前端应用程序、后端应用程序、数据源应用程序和 Node Exporter。

接下来，检查 `istio Config`。

如果显示`No Namespace Selected`，从右上角的![](3-020.png)中勾选`default`。

![](3-018.png)

`Name` 中的 `DR` 标签指向 `DestinationRule`。
如果点击`backend`，可以看到左侧`Destination Rule Overview`中有3个版本。

![](3-019.png)

接下来，检查“服务”。

如果显示`No Namespace Selected`，从右上角的![](3-020.png)中勾选`default`。

![](3-021.png)

您可以检查 Kubernetes Service 资源。
在 `Details` 中，您可以检查与 Service 资源关联的 `DestinationRule`。

**关于`node-exporter-handson`**
`node-exporter-handson`的`Details`栏中有一个![](3-032.png)标记，但不影响本次动手操作，请忽略。
{: .notice--info}

接下来，检查“工作负载”。

如果显示`No Namespace Selected`，从右上角的![](3-020.png)中勾选`default`。

![](3-022.png)

在这里，您将看到已部署的部署资源。

**关于`node-exporter-handson`**
`node-exporter-handson`的`Details`栏中有一个标记![](3-032.png)![](3-033.png)，但不影响本手操作-开。，请无视。
{: .notice--info}

接下来，检查“应用程序”。

如果显示`No Namespace Selected`，从右上角的![](3-020.png)中勾选`default`。

在这里，您将看到已部署的应用程序。
这里的应用程序几乎是服务资源的代名词。

![](3-023.png)

**关于`node-exporter-handson`**
`node-exporter-handson`的`Details`栏中有一个![](3-032.png)标记，但不影响本次动手操作，请忽略。
{: .notice--info}

单击“后端应用程序”，您将看到以下屏幕。

![](3-024.png)

现在从浏览器访问应用程序后再次检查。
稍等片刻，访问的Traffic会显示如下。

![](3-025.png)

此外，您可以通过使用图中红框部分的选项卡进行切换来查看各种信息，因此请检查它。

最后，确认`Graph`。

![](3-026.png)

在这里，您可以将交通信息等以图表的形式可视化。

例如，从右上角的![](3-027.png) 中选择`Versioned app graph`。

![](3-028.png)

在此状态下多次访问应用程序。
目前后端服务的负载是由`DestinationRule`随机分配的，所以可以看到金牌、银牌、铜牌的名单是随机显示的。

**关于后端应用程序的负载平衡**
甚至在应用 DestinationRule 之前，后端应用程序在 v1/v2/v3 之间进行了某种程度的负载平衡。
这是因为Service资源首先具有负载均衡功能。
通过应用 DestinationRule，您可以使用 Istio 功能执行显式负载平衡。
这次我们应用了“RANDOM”策略，但还有其他策略，例如“Weighted”和“Least requests”。
详情请查看页面[这里](https://istio.io/latest/docs/concepts/traffic-management/#load-balancing-options)。
{: .notice--info}

在显示每个金牌得主、银牌得主和铜牌得主的名单后，再次检查“版本化应用图表”。

![](3-029.png)

通过这种方式，您可以可视化每个版本的流量路由方式。

正如您在上面看到的，Kiali 允许您可视化您的 Service Mesh 环境中的各种资源和流量状况。

最后，回到你的主目录。

```sh
cd ~
```
4. 让我们使用 Istio 做一个金丝雀版本
---------------------------------

最后，我们将使用为步骤 3 构建的环境来执行金丝雀发布。

### 4-1 金丝雀发布

金丝雀发布是与“蓝/绿部署”和“A/B测试”并列的高级部署策略之一，是指在确认没有问题的同时逐步向整体扩展的部署方式。
这允许您将应用程序的新版本与生产版本一起部署，并查看用户的反应和执行情况。

通过使用 Istio，您可以轻松实现金丝雀版本。
这一次，我们将在以下假设下执行金丝雀发布。

* 目标：后端应用程序
* 现有版本：v1
* 新版本：v2 和 v3
* 路由策略：将 80% 的流量路由到 v1、15% 到 v2、5% 到 v3

要使用 Istio 实现上述配置，请创建一个名为“VirtualService”的资源。
这使用在 `DestinationRule` 中定义的信息来设置更详细的路由策略。
例如，根据 HTTP Headers 和路径等匹配规则，可以重写请求的路由目的地，操作 HTTP Headers。
这一次，我们将为后端应用程序版本分配权重。

`DestinationRule` 和 `VirtualService` 的关系如下。

![](4-001.png)

这次，我准备了以下 `VirtualService`。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: canary-release
spec:
  hosts:
    - backend-app
  http:
  - route:
    - destination:
        host: backend-app
        subset: v1
      weight: 80
    - destination:
        host: backend-app
        subset: v2
      weight: 15
    - destination:
        host: backend-app
        subset: v3
      weight: 5
```

请注意以下事项：

```yaml
  hosts:
    - backend-app
  http:
  - route:
    - destination:
        host: backend-app
        subset: v1
      weight: 80
    - destination:
        host: backend-app
        subset: v2
      weight: 15
    - destination:
        host: backend-app
        subset: v3
      weight: 5
```
这里的 `host` 是目标后端应用程序的服务资源。
每个“子集”都使用“DestinationRule”中定义的子集。
`weight` 设置每个的权重。

应用此清单。

```sh
cd code-at-customer-handson/k8s/scenario
```

```sh
kubectl apply -f canaly-release.yaml
```

***命令结果***

```sh
virtualservice.networking.istio.io/canary-release created
```
让我们访问应用程序。

大多数时候，会显示铜牌获得者 (v1)，有时会显示 v2（银牌获得者），很少会显示 v3（金牌获得者）。

多次访问后，让我们用 Kiali 将其可视化。

访问 Kiali UI 并从“应用程序”菜单中单击“后端应用程序”。

![](4-002.png)

图表部分显示了流量路由比率。
一般可以确认是按照设置的权重进行路由。

![](4-003.png)

通过这种方式，Istio 允许您通过简单地创建适当的资源来实施高级部署策略，例如金丝雀版本。

{% 捕获通知 %}**其他场景**
除了金丝雀版本，code-at-customer-handson/k8s/scenario 目录还包含以下场景。
必要时请检查。

* all-v3.yaml
  将所有流量路由到后端应用程序 v3（金牌得主）的策略。
  应用此功能后，应用程序将仅显示金牌得主。

* v1-v2-half.yaml
  将 50% 的流量路由到后端应用程序 v1 并将其余 50% 的流量路由到后端应用程序 v2 的策略。
  应用此功能后，应用程序将显示一半银牌得主和一半铜牌得主。 {%endcapture%}
<div class="notice--info">
  {{ notice | markdownify }}
</div>
这一切都是为了动手。

5. 使用 Grafana 仪表板检查 OCI 监控指标 [可选]
---------------------------------

这是一个可选步骤。
如果您有时间并且有兴趣，请尝试一下。

借助 Grafana，您可以使用插件在 Grafana 仪表板中查看 Oracle Cloud Infrastructure Monitoring 提供的指标。
在这里，我们将检查程序。

**关于 Oracle 云基础设施监控**
有关详细信息，请查看页面 [此处](https://docs.oracle.com/ja-jp/iaas/Content/Monitoring/Concepts/monitoringoverview.htm)。
{: .notice--info}

### 5-1 配置动态组和策略

在这里，我们将设置策略，以便可以从部署在 OKE 上的 Grafana 获取 Oracle Cloud Infrastructure Monitoring 提供的指标。

打开 OCI 控制台的汉堡菜单，从“身份和安全”中选择“动态组”。

**关于动态组**
有关动态组的详细信息，请参阅页面 [此处](https://docs.oracle.com/ja-jp/iaas/Content/Identity/Tasks/managingdynamicgroups.htm)。
{: .notice--info}

![](5-001.png)

单击创建动态组。

![](5-002.png)

输入信息如下。

**致所有参加集体实践会议的人**
动态组名不允许重复，所以如果您使用同一环境多人集体动手等，请在动态组名中添加您的姓名首字母或您喜欢的多位数字以避免重复。请设置动态组名如下。
{: .notice--info}

键|值
-|-
名称 | grafana_dynamic_group
说明 | grafana_dynamic_group
匹配规则 - 规则 1 | `instance.compartment.id = '<您的隔间 OCID>'`

![](5-003.png)

图片为图片，请根据自己的环境更换车厢OCID。

单击创建。

**隔间 OCID**
有关如何检查隔间 OCID 的信息，请参见此处 E3%83%B3%E3%83%91%E3%83%BC%E3%83%88%E3%83%A1%E3%83%B3%E3% 83%88ocid%E3%81%AE%E7% A2%BA%E8%AA%8D)，请检查“2-1-2”程序。
{: .notice--info}

然后从屏幕左侧的菜单中单击“策略”。

![](5-004.png)

单击创建策略。

![](5-005.png)

输入以下信息。
另外，选中“显示手动编辑器”。

键|值
-|-
名称 | grafana_policy
说明 | grafana_policy
隔间 | 您的隔间名称
策略 | `允许动态组 grafana_dynamic_group 读取隔离专区 ID <您的隔离专区 OCID> 中的指标`

{% capture notice  %}**给参与集体动手的大家**
参加集体动手的朋友，请使用自己创建的动态组名。
它看起来像这样：
```
allow dynamic-group <您创建的动态组名称> to read metrics in compartment id <您的隔离专区 OCI>
```

{% endcapture %}
<div class="notice--warning">
  {{ notice | markdownify }}
</div>

![](5-006.png)
图片为图片，请根据自己的环境更换车厢OCID。

单击创建。

这样就完成了动态组和策略的配置。

### 5-2 将OCI监控插件安装到Grafana

在这里，我们将 OCI Monitoring 插件安装到 Grafana。

这一次，Grafana 是作为 Istio 插件安装的，所以 Manifest 位于下方。

```
cd ~/istio-1.11.0/samples/addons/
```

使用 vi 打开 Grafana 清单文件。

```sh
vi grafana.yaml
```

将以下环境变量添加到第 160 行附近的 `env` 字段。

```yaml
    - name: GF_INSTALL_PLUGINS
      value: "oci-metrics-datasource"
```

保存并退出后，应用清单。

```sh
kubectl apply -f grafana.yaml
```

再次运行以下命令以使 Grafana 可从 NodePort 访问。

```sh
kubectl patch service grafana -n istio-system -p '{"spec": {"type": "NodePort"}}'
```

***命令结果***
```sh
service/grafana patched
```

另外，Grafana 申请后会重启，所以要等到启动完成。

```
kubectl get pod -n istio-system
```

***命令结果***
```sh
NAME                                    READY   STATUS    RESTARTS   AGE
grafana-5f75c485c4-5rxdq                1/1     Running   0          37s
istio-egressgateway-9dc6cbc49-pk5q2     1/1     Running   0          55m
istio-ingressgateway-7975cdb749-8kxr9   1/1     Running   0          55m
istiod-77b4d7b55d-cc7b7                 1/1     Running   0          55m
jaeger-5f65fdbf9b-pbjfb                 1/1     Running   0          54m
kiali-787bc487b7-znbl4                  1/1     Running   0          54m
loki-0                                  1/1     Running   0          51m
loki-promtail-8z4x7                     1/1     Running   0          51m
loki-promtail-hpm46                     1/1     Running   0          51m
loki-promtail-kkc9k                     1/1     Running   0          51m
prometheus-9f4947649-znlrr              2/2     Running   0          54m
```
这样就完成了将 OCI 监控插件安装到 Grafana 中。

### 5-3 检查 Grafana 仪表板

Grafana 重新启动后，从浏览器访问 Grafana 仪表板。
访问端口号已更改，请再次检查。

```sh
kubectl get services grafana -n istio-system
```

***命令结果***

```sh
NAME      TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
grafana   NodePort   10.96.219.44   <none>        3000:30453/TCP   4d3h
```
NodePort 用于访问 Grafana。
NodePort 是 `PORT(S)` 中 `:` 后面的端口号。
在上述情况下，请访问以下 URL。
http://[WorkerNode公网IP]:30453

访问后点击![](5-007.png)的![](5-014.png)。

点击![](5-008.png)，选择底部的“Oracle Cloud Infrastructure Metrics”，点击![](5-015.png)。

输入以下信息。

键|值
-|-
租赁 OCID | 您的租赁 OCID
默认区域 | ap-osaka-1
环境 | OCI 实例

![](5-009.png)

**关于租赁 OCID **
有关如何检查您的租赁 OCID 的信息，请参阅 [此处](https://oracle-japan.github.io/ocitutorials/cloud-native/oke-for-intermediates/#3%E3%83%AF%E3% 83%BC %E3%82%AF%E3%82%B7%E3%83%A7%E3%83%83%E3%83%97%E3%81%A7%E5%88%A9%E7%94% A8%E3 %81%99%E3%82%8B%E3%82%A2%E3%82%AB%E3%82%A6%E3%83%B3%E3%83%88%E6%83%85% E5%A0 请检查 %B1%E3%81%AE%E5%8F%8E%E9%9B%86 中的“3. Tenancy OCID”。
{: .notice--info}

单击保存并测试。

单击 ![](5-010.png) 并从顶部选项卡中选择 Oracle Cloud Infrastructure Metrics。

![](5-011.png)

输入以下必填项目。

键|值
-|-
地区 |
隔间 | 你的隔间名称
命名空间 | oci_computeagent
指标 | 选择例如`CpuUtilization`

**关于政策反思**
根据环境和情况，可能需要一些时间来反映 [之前的过程] 中设置的策略（#5-1-动态组和策略设置）。
如果 `Namespace` 及以上无法选择，请稍等片刻重试。
{: .notice--警告}

![](5-012.png)
图像是图像，因此请根据您自己的环境阅读每个项目。

您将看到如下图和表格。

![](5-013.png)

使用 OCI Monitoring Grafana 插件，您可以将 OCI Compute（在本例中为 OKE Worker Node）指标集成到您的 Grafana 仪表板中。
<!-- 6. 使用 OCI APM 进行跟踪 [可选]
---------------------------------ß
<!--
这是一个可选步骤。
如果您有时间并且有兴趣，请尝试一下。

OCI APM 可以像 Jaeger 一样跟踪包括微服务在内的分布式应用程序。
在此过程中，我们将完成使用 OCI APM 进行分布式跟踪的步骤。

**OCI APM 和 Oracle 云可观察性和管理平台**
OCI 拥有 [Oracle Cloud Observability and Management Platform](https://www.oracle.com/jp/manageability/) 作为一组服务，可提供应用程序可见性和基于机器学习的可操作见解。.
这些核心服务之一是 OCI APM，它是一种支持分布式跟踪和综合监控的服务。
有关详细信息，请查看页面 [此处](https://docs.oracle.com/ja-jp/iaas/application-performance-monitoring/index.html)。
{: .notice--info}

### 6-1 创建策略

首先，创建使用 OCI APM 的策略。

**关于此程序**
对于在试用环境或具有管理员权限的环境中进行动手操作的人来说，这一步 6-1 不是必需的，因此请跳过它并从步骤 6-2 开始。
{: .notice--info}

打开 OCI 控制台汉堡菜单并选择身份和安全下的策略。

![](6-001.png)
单击创建策略。

![](5-005.png)

输入以下信息。
另外，选中“显示手动编辑器”。

键|值
-|-
名称 | apm_policy
说明 | apm_policy
隔间 | 您的隔间名称
策略 | `允许组 APM-Admins 管理隔离专区 ID <您的隔离专区 OCID> 中的 apm 域`

![](6-002.png)

图片为图片，请根据自己的环境更换车厢OCID。

单击创建。

策略配置现已完成。

### 6-2 创建 APM 域

在这里，我们将创建一个 APM 域。

打开 OCI 控制台汉堡菜单，然后从监控和管理中选择应用程序性能监控类别中的管理。

![](6-003.png)

单击创建 APM 域。

![](6-004.png)

输入以下信息。

键|值
-|-
名称 | oke-handson-apm
说明 | oke-handson-apm

**致所有参加集体实践会议的人**
不允许有重复的APM域名，所以如果你使用同一个环境多人集体动手等，请在APM域名后面加上你的姓名首字母或者你选择的多位数字，避免重复。您的 APM 域名。
{: .notice--info}

单击创建。

![](6-005.png)

该域将具有“正在创建”的状态，等到它变为“活动”。

![](6-006.png)

一旦域是“活动的”，单击域名。

复制“APM域信息”中“Data Upload Endpoint”的值和“Data Key”中的“Private”key的值，记录在编辑器等中。
该值将是从应用程序端向 APM 上传跟踪信息时使用的端点和密钥，稍后将使用。

![](6-007.png)
![](6-008.png)

APM 域创建现已完成。

### 6-3 更改示例应用程序的清单设置

在这里，我们将更改清单设置。

转到带有清单的目录。  

```sh
cd ~
```

```sh
cd code-at-customer-handson/k8s/app/for-oci-apm
```

在 vim 中打开前端应用程序的清单。

```sh
vim olympic_frontend.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-app
  labels:
    app: frontend-app
    version: v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend-app
      version: v1
  template:
    metadata:
      labels:
        app: frontend-app
        version: v1
    spec:
      containers:
      - name: frontend-app
        image: nrt.ocir.io/orasejapan/codeatcustomer/frontend-app-apm
        ports:
        - containerPort: 8082
        env:
        - name: tracing.data-upload-endpoint
          value: https://xxxxxxxxxxxxxxxx.apm-agt.us-ashburn-1.oci.oraclecloud.com
        - name: tracing.private-data-key
          value: XXXXXXXXXXXXXXXXXXXXXXXX
~~~
```
将第25行到第29行`env`字段中`tracing.data-upload-endpoint`和`tracing.private-data-key`的`value`设置为[6-2创建APM域]（#6-2 - 使用您记录的 APM 域和私有数据密钥创建一个 apm 域。

如下。

```yaml
~~~
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend-app
      version: v1
  template:
    metadata:
      labels:
        app: frontend-app
        version: v1
    spec:
      containers:
      - name: frontend-app
        image: nrt.ocir.io/orasejapan/codeatcustomer/frontend-app-apm
        ports:
        - containerPort: 8082
        env:
        - name: tracing.data-upload-endpoint
          value: <ご自身のAPMドメインのエンドポイント>
        - name: tracing.private-data-key
          value: <ご自身のAPMドメインのプライベート・データキー>
```
在这种状态下保存。

对您的后端数据源应用程序执行相同的操作。

```sh
vim olympic_backend.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app-v1
  labels:
    app: backend-app
    version: v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend-app
      version: v1
  template:
    metadata:
      labels:
        app: backend-app
        version: v1
    spec:
      containers:
      - name: backend-app
        image: nrt.ocir.io/orasejapan/codeatcustomer/backend-app-v1-apm
        ports:
        - containerPort: 8081
        env:
        - name: tracing.data-upload-endpoint
          value: https://xxxxxxxxxxxxxxxx.apm-agt.us-ashburn-1.oci.oraclecloud.com
        - name: tracing.private-data-key
          value: XXXXXXXXXXXXXXXXXXXXXXXX
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app-v2
  labels:
    app: backend-app
    version: v2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend-app
      version: v2
  template:
    metadata:
      labels:
        app: backend-app
        version: v2
    spec:
      containers:
      - name: backend-app
        image: nrt.ocir.io/orasejapan/codeatcustomer/backend-app-v2-apm
        ports:
        - containerPort: 8081
        env:
        - name: tracing.data-upload-endpoint
          value: https://xxxxxxxxxxxxxxxx.apm-agt.us-ashburn-1.oci.oraclecloud.com
        - name: tracing.private-data-key
          value: XXXXXXXXXXXXXXXXXXXXXXXX
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app-v3
  labels:
    app: backend-app
    version: v3
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend-app
      version: v3
  template:
    metadata:
      labels:
        app: backend-app
        version: v3
    spec:
      containers:
      - name: backend-app
        image: nrt.ocir.io/orasejapan/codeatcustomer/backend-app-v3-apm
        ports:
        - containerPort: 8081
        env:
        - name: tracing.data-upload-endpoint
          value: https://xxxxxxxxxxxxxxxx.apm-agt.us-ashburn-1.oci.oraclecloud.com
        - name: tracing.private-data-key
          value: XXXXXXXXXXXXXXXXXXXXXXXX
```
`tracing.data-upload-endpoint`, `tracing.private-data-key` 在第 25-29、55-59、85-89 行的 `env` 字段中将值替换为 APM 域和记录的私有数据密钥在[6-2 创建 APM 域]（#6-2-创建 apm 域）中。

如下。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app-v1
  labels:
    app: backend-app
    version: v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend-app
      version: v1
  template:
    metadata:
      labels:
        app: backend-app
        version: v1
    spec:
      containers:
      - name: backend-app
        image: nrt.ocir.io/orasejapan/codeatcustomer/backend-app-v1-apm
        ports:
        - containerPort: 8081
        env:
        - name: tracing.data-upload-endpoint
          value: <您的 APM 域的端点>
        - name: tracing.private-data-key
          value: <您的 APM 域的私有数据密钥>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app-v2
  labels:
    app: backend-app
    version: v2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend-app
      version: v2
  template:
    metadata:
      labels:
        app: backend-app
        version: v2
    spec:
      containers:
      - name: backend-app
        image: nrt.ocir.io/orasejapan/codeatcustomer/backend-app-v2-apm
        ports:
        - containerPort: 8081
        env:
        - name: tracing.data-upload-endpoint
          value: <您的 APM 域的端点>
        - name: tracing.private-data-key
          value: <您的 APM 域的私有数据密钥>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app-v3
  labels:
    app: backend-app
    version: v3
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend-app
      version: v3
  template:
    metadata:
      labels:
        app: backend-app
        version: v3
    spec:
      containers:
      - name: backend-app
        image: nrt.ocir.io/orasejapan/codeatcustomer/backend-app-v3-apm
        ports:
        - containerPort: 8081
        env:
        - name: tracing.data-upload-endpoint
          value: <您的 APM 域的端点>
        - name: tracing.private-data-key
          value: <您的 APM 域的私有数据密钥>
```

最后，对数据源应用程序也这样做。

```sh
vim olympic_datasource.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: datasource-app
  labels:
    app: datasource-app
    version: v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: datasource-app
      version: v1
  template:
    metadata:
      labels:
        app: datasource-app
        version: v1
    spec:
      containers:
      - name: datasource-app
        image: nrt.ocir.io/orasejapan/codeatcustomer/datasource-app-apm
        ports:
        - containerPort: 8080
        env:
        - name: tracing.data-upload-endpoint
          value: https://xxxxxxxxxxxxxxxx.apm-agt.us-ashburn-1.oci.oraclecloud.com
        - name: tracing.private-data-key
          value: XXXXXXXXXXXXXXXXXXXXXXXX
```

将第25行到第29行`env`字段中`tracing.data-upload-endpoint`和`tracing.private-data-key`的`value`设置为[6-2创建APM域]（#6-2 - 使用您记录的 APM 域和私有数据密钥创建一个 apm 域。

如下。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: datasource-app
  labels:
    app: datasource-app
    version: v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: datasource-app
      version: v1
  template:
    metadata:
      labels:
        app: datasource-app
        version: v1
    spec:
      containers:
      - name: datasource-app
        image: nrt.ocir.io/orasejapan/codeatcustomer/datasource-app-apm
        ports:
        - containerPort: 8080
        env:
        - name: tracing.data-upload-endpoint
          value: <ご自身のAPMドメインのエンドポイント>
        - name: tracing.private-data-key
          value: <ご自身のAPMドメインのプライベート・データキー>
```
这样就完成了示例应用程序Manifest设置的修改。

此处使用的容器应用程序在应用程序端具有跟踪设置，以便使用 OCI APM。
这次OCI APM使用的应用是code-at-customer-handson目录下有`_apm`的项目。

{% capture notice %}**将 OCI APM 与 Helidon 应用程序一起使用**
这一次，我们将使用 Helidon 进行应用，但提供了【Helidon 是专用于 OCI APM 的代理】-helidon.html）。
基本上，您可以通过将以下依赖项添加到 `pom.xml` 来使用它。 （无需应用程序方面的更改）
另外，根据需要将配置值添加到`src/main/resources/META-INF/microprofile-config.properties`。

  ```xml
        <dependency>
            <groupId>com.oracle.apm.agent.java</groupId>
            <artifactId>apm-java-agent-helidon</artifactId>
            <version>RELEASE</version>
        </dependency>
        <dependency>
            <groupId>com.oracle.apm.agent.java</groupId>
            <artifactId>apm-java-agent-tracer</artifactId>
            <version>RELEASE</version>
        </dependency>
    </dependencies>

    <repositories>
        <repository>
            <id>oci</id>
            <name>OCI Object Store</name>
            <url>https://objectstorage.us-ashburn-1.oraclecloud.com/n/idhph4hmky92/b/prod-agent-binaries/o</url>
        </repository>
    </repositories>
  ```
  
这次，`microprofile-config.properties` 设置如下。 （对于前端应用程序）

  ```yaml
  # OCI APM関連
  tracing.enabled=true
  tracing.service=oke-helidon-demo-frontend-service
  tracing.name="frontend-helidon-service"
  ```
  {% endcapture %}
<div class="notice--info">
  {{ notice | markdownify }}
</div>

**在现有 Zipkin 平台上使用 OCI APM**
OCI APM 也与 Zipkin 兼容，因此现有的基于 Zipkin 的 APM 平台可以与 OCI APM 一起使用。
请查看 [此处](https://docs.oracle.com/en-us/iaas/application-performance-monitoring/doc/configure-open-source-tracing-systems.html) 了解详情。
{: .notice--info}

### 6-4 更改 Istio 跟踪设置

在这里，我们将配置设置以将跟踪从当前设置的 Istio 中的 Jarger 切换到 OCI APM。

首先，删除当前部署的应用程序。

```sh
cd ~
```

```sh
cd code-at-customer-handson/k8s/app/plain
```

```sh
kubectl delete -f . 
```

***命令结果***

```sh
deployment.apps/backend-app-v1 deleted
deployment.apps/backend-app-v2 deleted
deployment.apps/backend-app-v3 deleted
service/backend-app deleted
deployment.apps/datasource-app deleted
service/datasource-app deleted
deployment.apps/frontend-app deleted
service/frontend-app deleted
ingress.networking.k8s.io/gateway deleted
```
现在再次安装 Istio。
[2-1 Istio (addon: Prometheus, Grafana, Jaeger, Kiali) 安装] (#2-1-istioaddon-prometheus-grafana-jaeger-kiali 安装) 中安装的栈没有问题。

这一次，我们将使用 MeshConfig 来禁用 Istio 跟踪。

**关于全局网格选项**
Istio 有一组称为 MeshConfig 的设置，它们会影响整个 Service Mesh。
详情请查看[这里](https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/)。
{: .notice--info}

```sh
istioctl install --set profile=demo --set meshConfig.enableTracing=false --skip-confirmation
```

***命令结果***

```sh
✔ Istio core installed                                                                                                                           
✔ Istiod installed                                                                                                                               
✔ Egress gateways installed                                                                                                                      
✔ Ingress gateways installed                                                                                                                     
✔ Installation complete                                                                                                                          
Thank you for installing Istio 1.11.  Please take a few minutes to tell us about your install/upgrade experience!  https://forms.gle/kWULBRjUv7hHci7T6
```
这样就完成了更改 Istio 的跟踪设置。

### 6-5 OCI APM 中的跟踪

最后，我们将使用 OCI APM 执行跟踪。

再次部署示例应用程序。

```sh
cd ~
```

```sh
cd code-at-customer-handson/k8s/app/for-oci-apm
```

```sh
kubectl apply -f . 
```

***命令结果***

```sh
deployment.apps/backend-app-v1 created
deployment.apps/backend-app-v2 created
deployment.apps/backend-app-v3 created
service/backend-app created
deployment.apps/datasource-app created
service/datasource-app created
deployment.apps/frontend-app created
service/frontend-app created
ingress.networking.k8s.io/gateway created
```

访问您的应用程序。  

```sh
kubectl get services istio-ingressgateway -n istio-system
```

***命令结果***

```sh
NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP       PORT(S)                                                                      AGE
istio-ingressgateway   LoadBalancer   10.96.176.93   132.226.xxx.xxx   15021:30134/TCP,80:30850/TCP,443:30319/TCP,31400:31833/TCP,15443:30606/TCP   3d3h
```

在上面的例子中，endpoint 是 `132.226.xxx.xxx`，它是 istio-ingressgateway 的 `EXTERNAL-IP`。

在这种情况下，请访问以下 URL。
`http://132.226.xxx.xxx`

几次访问后检查来自 OCI APM 的跟踪信息。

打开 OCI Console 汉堡菜单，然后从 Monitoring and Administration 中选择 Application Performance Monitoring 类别中的 Trace Explorer。

![](6-009.png)

从屏幕顶部的“APM 域”中，选择在[6-2 创建 APM 域]（#6-2-创建 apm 域）中创建的 APM 域。

![](6-010.png)

在右侧选择“Last 15 minutes”作为搜索条件，然后单击“Go”按钮。

![](6-011.png)

会显示多条trace信息，点击“Spans”为25的信息。

![](6-012.png)

您将看到类似于以下内容的跟踪信息：
可以确认，比起之前与Jaeger确认的信息，可以获得更详细的信息。

![](6-013.png)
![](6-014.png)

使用 OCI APM 进行跟踪现已完成。

### 6-6 使用 OCI APM 监控应用服务器指标

现在让我们看一下可以使用 OCI APM 监控的应用服务器指标。

从屏幕左上角的下拉菜单中单击“仪表板”。

![](6-015.png)

单击仪表板中的应用程序服务器。

![](6-016.png)

由于左上角有下拉“Select an application server”，选择任意一个应用服务器（其实是Helidon的Pod）。

![](6-017.png)

显示应用程序服务器（在本例中为 helidon）的指标信息。

![](6-018.png)

根据此处获取的指标，通过与OCI Monitoring或OCI Notifications联动，可以在超过某个阈值时发出告警通知。

**关于 OCI 监控和 OCI 通知**
OCI 有 OCI Monitoring 监控资源，与 OCI Notifications 联动时，可以将警报通知发送到电子邮件、Slack 等。
有关更多详细信息，请查看动手操作 [此处](/ocitutorials/intermediates/monitoring-resources/)。
{: .notice--info}

通过这种方式，OCI APM 可用于获取和查看详细的跟踪并监控应用程序服务器指标。 -->

