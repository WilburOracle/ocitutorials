---
title: "在 Oracle Container Engine for Kubernetes (OKE) 上部署示例微服务应用程序并使用 OCI 的可观察性服务"
excerpt: "本内容让您体验使用 OKE 部署和观察示例微服务应用程序。 利用 OCI 的可观察性服务监控、日志记录、应用程序性能监控和通知。"
order: "031"
tags:
---

在本实践中，我们将在 Oracle Container Engine for Kubernetes (OKE) 之上部署一个微服务应用程序。 并使用 OCI 的 Observability 服务来学习监控、日志记录和跟踪实践。

作为 OCI 的 Observability 服务，我们使用：

***监控***

- [Oracle 云基础设施监控](https://www.oracle.com/jp/devops/monitoring/)
：一项完全托管的服务，允许您使用指标和警报主动和被动地监控您的云资源。

***记录***

- [Oracle 云基础设施日志记录](https://www.oracle.com/jp/devops/logging/)
：高度可扩展、完全托管的日志记录服务，适用于审计日志、服务日志和自定义日志。

*** 追踪 ***

- [Oracle 云基础设施应用程序性能监控](https://www.oracle.com/jp/manageability/application-performance-monitoring/)
：一种完全托管的服务，具有一套全面的功能来监控您的应用程序和诊断性能问题。

**关于 Oracle 云可观察性和管理平台**
本实践中使用的服务是构成 [Oracle 云可观察性和管理平台 (O&M)](https://www.oracle.com/jp/manageability/) 的组件的一部分。
除了这个动手实践的服务，运维还包括【日志分析】(https://www.oracle.com/jp/manageability/logging-analytics/)、【数据库管理】(https://www.oracle.com/jp/manageability/logging-analytics/)。 com/jp/manageability/database-management/) 作为云服务提供 Oracle Enterprise Manager 的主要功能等。
{: .notice--信息}

实际操作流程如下。

---
1. OKE集群搭建及OCIR设置
    1. 从 OCI 仪表板构建 OKE 集群
    2.使用Cloud Shell操作集群
    3.设置OCIR

2.应用性能监控
    一、示例应用概述
    2.示例应用与APM联动设置
    3.创建APM域
    4. 示例应用程序（浏览器端）和容器镜像创建的 APM 设置
    5. 示例应用程序的 APM 设置（服务器端）
    6. OCI APM 中的跟踪
    7. 使用 OCI APM 监控应用程序服务器指标
    8. 使用 OCI APM 进行真实用户监控 (RUM)
    9. OCI APM 中的综合监控

3.日志记录
    1.自定义日志设置
    2.检查工作节点上的应用程序日志
    3.查看Kubernetes API服务器审计日志

4.监控与通知
    1.通知设置
    2.监控设置
    3. 实践监控和通知

5、本次使用的示例应用补充说明

---

实际操作概述如下所示。在构建和设置整个环境时执行红色描述的操作。

![](0-0-000.png)

1. OKE集群搭建及OCIR设置
----------------------------------

构建 Kubernetes 集群并设置 OCIR 来存储容器镜像。

![](1-1-000.png)

### 1-1 从 OCI 仪表板构建 OKE 集群

展开左上角的汉堡菜单，然后从“开发者服务”中选择“Kubernetes Cluster (OKE)”。

![](1-1-001.png)

从左侧菜单中列表范围下的隔间选择下拉菜单中选择您的隔间。

![](1-1-012.png)

单击创建集群按钮。

![](1-1-002.png)

确保选择了“快速创建”并单击“启动工作流”按钮。

![](1-1-003.png)

确保在设置中设置了以下内容。

键|值
-|-
Kubernetes API 端点 | 公共端点
Kubernetes 工作节点 | 私人工作人员
形状 | VM Standard.E3.Flex
选择 OCPU 数量 | 1
内存量 (GB)|16

![](1-1-004.png)

单击屏幕左下方的“下一步”按钮。

![](1-1-005.png)

单击屏幕左下方的“创建集群”按钮。

![](1-1-006.png)

单击屏幕左下方的“关闭”按钮。

![](1-1-007.png)

确认它从黄色“Creating”变为绿色“Active”。如果为“Active”，则集群创建完成。

![](1-1-008.png)

### 1-2 使用Cloud Shell 操作集群

使用 Cloud Shell 连接到创建的 Kubernetes 集群。

单击访问群集按钮。

![](1-1-009.png)

单击“启动 Cloud Shell”按钮，然后单击“复制”链接文本，然后单击“关闭”按钮。

![](1-1-010.png)

启动 Cloud Shell 后，粘贴“复制”的内容并按回车键。

![](1-1-011.png)

执行以下命令确认3个节点的“STATUS”为“Ready”。

```sh
kubectl get nodes
```
***命令结果***
```sh
NAME          STATUS   ROLES   AGE     VERSION
10.0.10.139   Ready    node    2m7s    v1.21.5
10.0.10.228   Ready    node    2m22s   v1.21.5
10.0.10.24    Ready    node    2m27s   v1.21.5
```

### 1-3 设置OCIR

在后续步骤中，您将构建示例应用程序并创建容器映像。
设置容器映像注册表以存储容器映像。
OCI 使用 Oracle Cloud Infrastructure Registry (OCIR)。

**关于奥克尔**
提供完全托管的 Docker v2 标准兼容容器注册表的服务。通过部署在与 OKE 相同的区域来实现低延迟。有关详细信息，请查看页面[此处](https://www.oracle.com/jp/cloud-native/container-registry/)。
{: .notice--信息}

点击左上角的汉堡菜单，选择“开发者服务”-“容器注册”。

![](1-3-001.png)

{% capture notice %}**关于用于动手操作的隔间**
要在试用环境中动手操作，请使用根隔间。
在 OCIR 控制台屏幕上默认选择根隔离区，但如果您有分配给您的隔离区，请使用该隔离区。
可以从 OCIR 控制台屏幕的左侧选择隔间。
![0-013.jpg](1-1-013.jpg)
{% endcapture %}
<div class="notice--warning">
  {{ notice | markdownify }}
</div>

单击创建存储库按钮。

![](1-3-002.png)

在“Repository Name”中输入“frontend-app-apm”，在“Access”中选择“Public”，点击“Create Repository”按钮。

![](1-3-003.png)

**关于存储库名称**
OCIR 存储库名称在您的租户中是唯一的。
对于集体动手等多人共享同一环境的，请在名字首字母上加上`frontend-app-apm01`和`frontend-app-apm-tn`，以免重名。。
{: .notice--警告}

获取将容器镜像推送到 OCIR 时所需的“用户名”和“密码”。

“用户名”将为“<对象存储命名空间>/<用户名>”。

检查<用户名>。对于您的用户名，单击右上角的个人资料图标并选择您的个人资料名称。

![](1-3-004.png)

复制“用户详细信息屏幕”的红框部分并将其粘贴到文本编辑器中。

![](1-3-005.png)

接下来，检查 <Object Storage Namespace>。

单击右上角的配置文件图标并选择租赁。

![](1-3-006.png)

复制“Tenancy Details”中“Object Storage Namespace”红框部分，粘贴到文本编辑器中。

![](1-3-007.png)

接下来，设置将是“密码”的身份验证令牌。

单击右上角的个人资料图标，然后选择您的个人资料名称。

![](1-3-008.png)

从左侧菜单中选择“身份验证令牌”。

![](1-3-009.png)

单击“创建令牌”按钮。

![](1-3-010.png)

在 Description 中输入 oke-handson-apm，然后单击 Generate Token 按钮。

![](1-3-011.png)

单击复制，然后单击关闭按钮。您将在后面的步骤中需要复制的身份验证令牌，因此将其粘贴到文本编辑器中。

![](1-3-012.png)

这样就完成了身份验证令牌的创建。

下面，将其应用于文本编辑器中粘贴的内容并使用它。

键|值
-|-
用户名|‘${对象存储命名空间}/‘${用户名}’
密码| `身份验证令牌`

OCIR 设置现已完成。

2.应用性能监控
----------------------------------

在 Kubernetes 集群上部署示例微服务应用程序并设置 APM 以练习跟踪、应用程序服务器指标监控、真实用户监控和综合监控。

![](2-1-000.png)

### 2-1. 示例应用程序概述

首先，移至您的主目录并克隆以下 Git 存储库。

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
├── k8s ==> Kubernetes 的主要集群
├── olympic_backend_amp ==> 后端应用
├── olympic_datasource_amp ==> 数据源应用
├── olympic_frontend_amp ==> 前端应用
.
```

该示例应用程序主要包括以下内容：

- [Helidon](https://oracle-japan-oss-docs.github.io/helidon/docs/v2/#/about/01_overview)
  - Oracle 开源提供的 Java 微服务框架
- [Oracle JavaScript 扩展工具包 (Oracle JET)](https://www.oracle.com/jp/application-development/technologies/jet/oracle-jet.html)
  - Oracle 开发的开源 Javascript 框架
  - 添加高级功能和服务，帮助开发人员更快地构建更好的应用程序，基于流行的开源框架作为行业标准

让我们快速浏览一下应用程序的组成。
完成这一步后，整体形象应该是这样的：

![](2-1-001.png)

下图显示了 Oracle Cloud Infrastructure 的配置。

![](2-1-002.png)

此示例应用程序包含三个组件：

- **前端应用程序（图中的`Olympics`）**
  由 Helidon 和 Oracle JET 组成的应用程序。
  Oracle JET 内容放置在 Helidon 的静态内容根目录中（在本例中位于“resources/web”下）。
  此应用程序调用其中一项后端服务 (v1/v2/v3)。
  该应用程序还包括用于应用程序性能监控的 APM 浏览器代理和 APM 服务器代理。

- **后端应用（图中绿框）**
  由 Helidon 组成的应用程序。
  此应用程序有三个版本，每个版本都返回金牌得主 (v3)、银牌得主 (v2) 和铜牌得主 (v1) 的列表。
  版本信息存储为环境变量。
  本应用调用版本对应的API端点到数据源应用获取数据。
  此应用程序还包括用于应用程序性能监控的 APM 服务器代理。

- **数据源应用（图中`Medal Info`）**
  本应用由Helidon和[H2数据库](https://www.h2database.com/html/main.html)组成，后者是一个运行在内存中的数据库。
  在这个应用程序中，存储了获奖者和获得奖牌的颜色，并根据从后端应用程序调用的端点返回奖牌获得者和奖牌的颜色。
  此应用程序还包括用于应用程序性能监控的 APM 服务器代理。

**关于赫利顿**
Helidon 可以使用 `Maven` 创建项目模板。
有关命令，请查看[此处](https://helidon.io/docs/v2/#/mp/guides/02_quickstart)。
默认情况下，它还包含一个 Dockerfile。
后面用到的Dockerfile也基本都是用上面的模板文件。
Helidon 还有一个方便的 CLI 工具，称为 Helidon CLI。
对于 Helidon CLI，请查看[此处](https://oracle-japan.github.io/ocitutorials/cloud-native/helidon-mp-for-beginners/)。
{: .notice--信息}

### 2-2 示例应用程序和APM联动设置

配置克隆的示例应用程序以使用 APM。

**关于这个程序**
这2-2步对于在试用环境或管理员权限环境中动手的人来说是不需要的，所以请跳过它，从2-3步开始。
{: .notice--信息}

首先，创建一个使用 OCI APM 的策略。

打开 OCI 控制台汉堡包菜单并选择身份和安全下的策略。

![](2-2-001.png)

单击创建策略。

![](2-2-002.png)

输入以下信息。
另外，选中“显示手动编辑器”。

键|值
-|-
名称 | apm_policy
说明 | apm_policy
隔间 | 您的隔间名称
政策 | `允许组 APM-Admins 管理隔间 ID <您的隔间 OCID> 中的 apm 域`

![](2-2-003.png)

图片是图片，请根据自己的环境更换隔间OCID。

单击创建。

策略配置现已完成。

### 2-3 创建APM域

在这里，我们将创建一个 APM 域。

打开 OCI 控制台汉堡包菜单，然后从“监视和管理”中的“应用程序性能监视”类别中选择“管理”。

![](2-3-001.png)

单击创建 APM 域。

![](2-3-002.png)

输入以下信息。

键|值
-|-
名称 | oke-handson-apm
描述 | oke-handson-apm

**致所有参加集体实践会议的人**
不允许重复的APM域名，因此如果您使用同一环境多人集体动手等，请在APM域名中添加您的姓名首字母或您选择的多位数以避免重复设置。您的 APM 域名。
{: .notice--警告}

单击创建。

![](2-3-003.png)

该域的状态为“正在创建”，等待它变为“活动”。

![](2-3-004.png)

域处于“活动”状态后，单击域名。

复制下面的“APM域名信息”，用编辑器记录下来。

物品|使用
-|-
Data Upload Endpoint | 上传trace和metrics信息的端点
“数据密钥”的“私钥”|用于上传跟踪和指标信息的私钥。主要由APM服务器代理使用（服务器端的应用程序端）
“数据密钥”的“公钥”| 用于上传跟踪和指标信息的私钥。主要用于APM浏览器代理（浏览器端应用程序端）

该值将作为应用端向APM上传跟踪信息时使用的endpoint和key，后面会用到。

![](2-3-005.png)
![](2-3-006.png)

APM 域创建现已完成。

### 2-4 示例应用程序（浏览器端）和容器映像创建的 APM 设置

在示例应用程序的前端应用程序中设置 APM 端点和公钥。

通过此设置，您将能够从 APM 端的前端应用程序中获取跟踪信息。
然后构建以创建容器镜像。

```sh
vim code-at-customer-handson/olympic_frontend_apm/src/main/resources/web/index.html
```

***命令结果***

```
~~~
    <script>
      window.apmrum = (window.apmrum || {}); 
      window.apmrum.serviceName='oke-helidon-demo-frontend-UI';
      window.apmrum.webApplication='OracleJetApp';
      window.apmrum.ociDataUploadEndpoint='https://xxxxxxxxxxxxxxx.apm-agt.us-ashburn-1.oci.oraclecloud.com';　#变更 1
      window.apmrum.OracleAPMPublicDataKey='<your-public-data-key>';　#变更2
      window.apmrum.traceSupportingEndpoints =  [
        { headers: [ 'APM' ], hostPattern: '.*' },
      ]; 
    </script>
    <script async crossorigin="anonymous" src="https://xxxxxxxxxxxxxxx.apm-agt.us-ashburn-1.oci.oraclecloud.com/static/jslib/apmrum.min.js"></script> #变更3
~~~
```

变更位置|变更|备注
-|-
变更1 | [2-3 APM domain creation] (#2-3-apm domain creation)中记录的“Data upload endpoint” |
变化2|【2-3创建APM域】（#2-3-创建apm域）中记录的数据密钥的“公钥”|** 注意，这是公钥，不是私钥。请。 **
变化3| 将[2-3 APM domain creation](#2-3-apm domain creation)中记录的“数据上传端点”从static之前的`https to .com`设置为做。

更新后，用“:wq”保存并退出编辑器。

移动目录后，构建以创建容器镜像。

```sh
cd code-at-customer-handson/olympic_frontend_apm
```

`your-object-storage-namespace` 指定先前获得的对象存储命名空间。

**对于不在 Ashburn(us-ashburn-1) 地区的参与者**
如果区域不是Ashburn（us-ashburn-1），请根据您的环境更改“iad.ocir.io”部分。
可以在[此处](https://docs.oracle.com/en-us/iaas/Content/Registry/Concepts/registryprerequisites.htm) 找到每个区域的 OCIR 端点。
从现在开始，我们将继续“iad.ocir.io”。
{: .notice--warning}

**所有参加集体动手课程的人**
如果多人使用相同的环境，例如一组动手操作，请更改在[步骤 1-3]（#1-3-ocir 设置）中创建的存储库名称。
将存储库名称与您自己设置的名称相匹配。
{: .notice--warning}

几分钟后显示Successfully则表示构建成功。

```sh
docker image build -t iad.ocir.io/<your-object-storage-namespace>/frontend-app-apm .
```

***命令结果***

```sh
~~~
Successfully built b3bd22ffd681
Successfully tagged iad.ocir.io/<your-object-storage-namespace>/frontend-app-apm:latest
```

登录 OCIR。 对于“iad.ocir.io”端点，请匹配您的环境，就像构建时一样。

对于“用户名”和“密码”，请输入您事先确认的以下内容。

输入项|输入内容|获取来源
-|-
用户名 | `<Object Storage Namespace>/<User Name>`|在 [Step 1-3] (#1-3-ocir setup) 中创建的内容
Password|`Authentication token`|【Step 1-3】中创建的内容（#1-3-ocir setup）
```sh
docker login iad.ocir.io
```

***命令结果***

```sh
Username: <对象存储命名空间>/<用户名>
Password: 身份验证令牌
WARNING! Your password will be stored unencrypted in /home/xxxxx/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

推送创建的容器镜像。
`your-object-storage-namespace` 指定先前获得的对象存储命名空间。

**对于不在 Ashburn(us-ashburn-1) 地区的参与者**
如果区域不是Ashburn（us-ashburn-1），请根据您的环境更改“iad.ocir.io”部分。
可以在[此处](https://docs.oracle.com/en-us/iaas/Content/Registry/Concepts/registryprerequisites.htm) 找到每个区域的 OCIR 端点。
从现在开始，我们将继续“iad.ocir.io”。
{: .notice--warning}

**所有参加集体动手课程的人**
如果多人使用相同的环境，例如一组动手操作，请更改在[步骤 1-3]（#1-3-ocir 设置）中创建的存储库名称。
将存储库名称与您自己设置的名称相匹配。
{: .notice--warning}

```sh
docker image push iad.ocir.io/<your-object-storage-namespace>/frontend-app-apm
```

***命令结果***

```sh
The push refers to repository [iad.ocir.io/<your-object-storage-namespace>/frontend-app-apm]
129b7b03d44d: Pushed 
ee383522dea8: Pushed 
aa321ebc98e2: Pushed 
492be60e6c97: Pushed 
20f064be7fc0: Pushed 
7da834c1ebd3: Pushed 
7d0ebbe3f5d2: Pushed 
latest: digest: sha256:5e52a9d52d52b18a58ec71972db95980b43dcfe9fc78c7a83502b76c50d971d5 size: 1789
```
接下来，编辑 Mainifest 以使用推送的容器映像。

转到带有 Manifest 的目录。
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
  replicas: 1
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
        image: iad.ocir.io/orasejapan/frontend-app-apm #变更
        ports:
        - containerPort: 8082
        env:
        - name: tracing.data-upload-endpoint
          valueFrom:
            secretKeyRef:
              name: apm-secret
              key: endpoint
        - name: tracing.private-data-key
          valueFrom:
            secretKeyRef:
              name: apm-secret
              key: private-key
~~~
```

更改以下项目。

之前 | 变更
-|-
iad.ocir.io/orasejapan/frontend-app-apm（第 22 行）| iad.ocir.io/<your-object-storage-namespace>/frontend-app-apm

**对于不在 Ashburn(us-ashburn-1) 地区的参与者**
如果区域不是Ashburn（us-ashburn-1），请根据您的环境更改“iad.ocir.io”部分。
可以在[此处](https://docs.oracle.com/en-us/iaas/Content/Registry/Concepts/registryprerequisites.htm) 找到每个区域的 OCIR 端点。
从现在开始，我们将继续“iad.ocir.io”。
{: .notice--warning}
**所有参加集体动手课程的人**
如果多人使用相同的环境，例如一组动手操作，请更改在[步骤 1-3]（#1-3-ocir 设置）中创建的存储库名称。
将存储库名称与您自己设置的名称相匹配。
{: .notice--warning}

它将如下所示。

```yaml
~~~
spec:
  replicas: 1
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
        image: iad.ocir.io/＜your-object-storage-namespace＞/frontend-app-apm
        ports:
        - containerPort: 8082
        env:
        - name: tracing.data-upload-endpoint
          valueFrom:
            secretKeyRef:
              name: apm-secret
              key: endpoint
        - name: tracing.private-data-key
          valueFrom:
            secretKeyRef:
              name: apm-secret
              key: private-key
```

编辑完成后用“:wq”保存内容。

这完成了示例应用程序的 APM 设置（浏览器端）和容器映像创建。

### 2-5 示例应用程序的 APM 设置（服务器端）

接下来，将端点和私有数据密钥设置为机密，以便示例应用程序的 APM 配置（服务器端）可以将跟踪信息和指标上传到 APM。
从 Cloud Shell 运行以下命令。
将`Data Key`中的`APM Endpoint`和`private'key分别替换为以下值。

**关于密钥**
请参阅 [此处](https://kubernetes.io/docs/concepts/configuration/secret/) 获取 Secret 资源。
{: .notice--info}

项目|设置|备注
-|-
APM端点|【2-3创建APM域】中记录的“数据上传端点”（#2-3-创建apm域）|
“Data Key”的“Private” key | [2-3 Creating APM Domain] (#2-3-Creating apm Domain)中记录的data key的“Private” key |**不是公钥，请注意这是一个私钥。 **

```sh
kubectl create secret generic apm-secret \
--from-literal=endpoint=<APM 端点>\
--from-literal=private-key=<数据密钥中的私钥>
```

***命令结果***

```sh
secret/apm-secret created
```

每个应用程序都有一个引用此秘密的设置（`apm-secret`），因此您可以根据设置的端点和数据密钥将应用程序跟踪信息和指标上传到 APM。
详情请参考【5.本次使用示例应用补充说明】（#5 本次使用示例应用补充说明）。

这样就完成了示例应用程序的 APM 设置（服务器端）。

{% capture notice %}**将 OCI APM 与 Helidon 应用程序结合使用**
这次，我们将使用 Helidon 作为应用程序，但提供了 [Helidon 是一个专用于 OCI APM 的代理] -helidon.html)。
基本上，您可以通过将以下依赖项添加到 `pom.xml` 来使用它。 （无需更改应用程序端）
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

这次，“microprofile-config.properties”设置如下。 （对于前端应用程序）

  ```yaml
  #OCI APM相关
  tracing.enabled=true
  tracing.service=oke-helidon-demo-frontend-service
  tracing.name="frontend-helidon-service"
  ```
  {% endcapture %}
<div class="notice--info">
  {{ notice | markdownify }}
</div>

**在现有 Zipkin 平台上使用 OCI APM**
OCI APM 还与 Zipkin 兼容，因此现有的基于 Zipkin 的 APM 平台可以与 OCI APM 一起使用。
请查看[此处](https://docs.oracle.com/en-us/iaas/application-performance-monitoring/doc/configure-open-source-tracing-systems.html)了解详细信息。
{: .notice--info}

### 2-6 OCI APM 中的跟踪

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
```

访问您的应用程序。

```sh
kubectl get service frontend-app
```

***命令结果***

```sh
NAME           TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)        AGE
frontend-app   LoadBalancer   10.96.220.188   193.122.***.***   80:31664/TCP   41s
```

在上述情况下，前端应用服务的 `193.122.***.***` 即 `EXTERNAL-IP` 将是端点。

在这种情况下，访问以下 URL。
`http://193.122.***.***`

![](2-6-008.png)

访问几次后查看 OCI APM 的跟踪信息。

打开 OCI 控制台汉堡包菜单，然后从“监视和管理”中的“应用程序性能监视”类别中选择“跟踪资源管理器”。

![](2-6-001.png)

从屏幕顶部的“APM Domain”中，选择在[6-2 Create APM Domain]中创建的APM域（#6-2-Create apm Domain）。

![](2-6-002.png)

在右侧选择“最近 15 分钟”作为搜索条件，然后单击“开始”按钮。

![](2-6-003.png)

会显示多条trace信息，点击显示“Completed”且`Spans`为26的信息。

![](2-6-004.png)

您可以获得详细的跟踪信息，例如：

![](2-6-005.png)
![](2-6-006.png)

点击红框中的“oke-helidon-demo-frontend-UI: Ajax /medalist”可以获取详细的客户端信息。

![](2-6-007.png)

要完成，请单击“关闭”按钮。

这样就完成了使用 OCI APM 的跟踪。

### 2-7 使用 OCI APM 监控应用程序服务器指标

现在让我们看一下可以使用 OCI APM 监视的应用程序服务器指标。

从屏幕左上角的下拉菜单中单击“仪表板”。

![](2-7-001.png)

单击仪表板中的应用程序服务器。

![](2-7-002.png)

由于左上角有一个下拉“Select an application server”，选择任意一个应用服务器（实际上是Helidon的Pod）。

![](2-7-003.png)

显示应用程序服务器（在本例中为 helidon）的指标信息。

![](2-7-004.png)

根据此处获取的指标，通过与OCI Monitoring或OCI Notifications联动，可以在超过某个阈值时发出告警通知。

**关于OCI监控和OCI通知**
OCI有监控资源的OCI Monitoring，与OCI Notifications联动后，可以将告警通知发送到email、Slack等。
这是在 [4.Monitoring & Notifications](#4monitoring--notifications) 中完成的。
{: .notice--信息}

这样，OCI APM 可用于获取和审查详细的跟踪和监控应用程序服务器指标。

### 2-8 使用 OCI APM 进行真实用户监控 (RUM)

在这里，我想看看使用 OCI APM 的 APM 浏览器代理的真实用户监控 (RUM)。

真实用户监控 (RUM) 根据实际用户 PC 或智能手机的访问来测量和分析网页的性能。

**用于前端性能监控**
前端性能监控有两种类型：真实用户监控（RUM）和综合监控。
这两种类型的性能监控是互补的，通常一起使用以进行有效监控。
OCI APM 中提供了这两种类型的性能监控。
{: .notice--信息}

从屏幕左上角的下拉菜单中单击“仪表板”。

![](2-7-001.png)

单击仪表板中的真实用户监控。

![](2-8-001.png)

由于左上角有一个下拉“Select a Web application”，所以选择`OracleJetApp`。

![](2-8-002.png)

**关于网络应用**
在这个实践环境中，显示了两种类型的 Web 应用程序：`OracleJetApp` 和 `All Web Applications`。没有。
{: .notice--信息}

如果您手头有其他浏览器或智能手机，请在从该浏览器或设备访问示例应用程序后，尝试将右上角的搜索条件重置为“最近 15 分钟”。
![](2-8-004.png)

显示如下页面，可以确认显示了访问源的地理位置和Apdex、浏览器类型、操作系统信息等。
![](2-8-003.png)

**关于Apdex**
真实用户监控项中的“Apdex”是衡量用户对网络应用和服务响应时间满意度的行业标准指标。
满意为1分，可以忍受为0.5分，沮丧为0分，取平均值，最高为1分，最低为0分。
请查看[此处](https://www.apdex.org/index.php/documents/)了解详情。
该索引也用于 SLA（服务级别协议）。
{: .notice--信息}

通过这种方式，OCI APM 允许使用 APM 浏览器代理进行真实用户监控 (RUM)。

### 2-9 OCI APM中的综合监控

在这里，我想看看使用 OCI APM 的综合监控。

综合监控是一种利用地理分布的代理主动访问、监控和测量目标网站的技术。

从左上角的下拉菜单中单击“综合监控”。

![](2-9-001.png)

单击创建监视器。现在创建一个监控代理来执行综合监控。

![](2-9-007.png)

输入以下项目，然后单击“下一步”。

![](2-9-002.png)

输入项|输入内容|获取来源
-|-
名称 | oke-handson-apm
类型|浏览器
[2-6 Tracing with OCI APM](#2-6-oci-apm tracing) 中确认的示例应用程序的基本 URL|IP 地址

输入以下项目，然后单击“下一步”。

![](2-9-003.png)

输入项|输入内容|获取来源
-|-
有利位置 | 日本东部（东京）/美国东部（阿什本）
间隔|运行一次

**关于有利点**
这里设置的“有利位置”是指将要进行监控测试的地理位置。
{: .notice--信息}

**关于间距**
如果您希望监控测试定期自动运行，您可以指定以分钟为单位的时间间隔。
{: .notice--信息}

点击下一步。

![](2-9-004.png)

只需单击“创建”。

![](2-9-005.png)

将出现以下屏幕。

![](2-9-006.png)

现在让我们运行监控测试。

单击“其他操作”中的“运行一次”。

![](2-9-008.png)

执行完成后，您可以在屏幕左侧的“资源”中的“历史记录”中查看执行结果。

![](2-9-009.png)

从“Vantage Point”“Japan East (Tokyo)”右侧的烤肉串菜单中点击“View HAR”。

![](2-9-011.png)

监控测试的执行结果显示如下。

![](2-9-010.png)

因此，OCI APM 允许综合监控。

3.日志记录
----------------------------------

设置日志记录服务以检查工作节点应用程序日志和 API 服务器审计日志。

![](3-1-000.png)

Oracle 云基础设施 (OCI) 日志记录服务是一个完全托管的云原生分布式日志记录平台，可简化整个堆栈中日志的摄取、管理和分析。在一个视图中管理基础架构、应用程序、审计和数据库日志。

查看和搜索您刚刚构建的 OKE 集群中工作节点的计算实例上运行的应用程序的日志。

### 3-1 配置自定义日志

设置使用 OCI 日志记录服务所需的策略。

#### 创建一个动态组

您将需要租户的 OICD，因此请获取它。

单击右上角的配置文件图标并选择租赁。

![](1-3-006.png)

单击“OICD”的“复制”文本并将其粘贴到文本编辑器中。

![](3-1-015.png)

展开左上角的汉堡菜单，然后从“身份和安全”中选择“动态组”。

![](3-1-012.png)

单击创建动态组按钮。

![](3-1-013.png)

设置以下内容：

输入项|输入内容
-|-
名称|记录动态组
描述|记录动态组

为规则设置以下内容。 <your-OCID> 设置预先获取的OCID。

```sh
instance.compartment.id = '<your-OCID>'
```

![](3-1-014.png)

#### 策略设置

展开左上角的汉堡菜单，然后从“身份和安全”中选择“策略”。

![](3-1-001.png)

单击创建策略按钮。

![](3-1-002.png)

设置以下内容：

输入项|输入内容
-|-
名称|记录
说明|记录

将 Show Manual Editor 按钮滑动到右侧。

设置以下策略。

```嘘
允许动态组日志动态组在租赁中使用日志内容
```

![](3-1-003.png)

单击“创建”按钮。

![](3-1-004.png)

这样就完成了策略设置。

####自定义日志设置

接下来，设置您的自定义日志设置。
展开左上角的汉堡菜单，然后从监控和管理中选择日志。

![](3-1-005.png)

单击创建自定义日志按钮。

![](3-1-006.png)

输入 worker-node 作为 Custom log name，然后单击 Create new group。

![](3-1-007.png)

输入“handson_log”作为名称。

![](3-1-011.png)

单击“创建”按钮。

![](3-1-004.png)

单击创建自定义日志按钮。

![](3-1-008.png)

在创建代理配置中，设置以下内容：

输入项|输入内容
-|-
配置名称 | 工作节点
描述|工作节点
群类型|动态群
组|记录动态组
输入类型|日志路径
输入名称|oke_cluster
文件路径|/var/log/containers/*

![](3-1-009.png)

单击创建自定义日志按钮。

![](3-1-008.png)

确保在列表中看到“worker-node”。
*如果没有显示，请更新您的浏览器，例如转换到另一个页面。

![](3-1-010.png)

### 3-2 检查工作节点上的应用程序日志

选择配置好的“worker-node”，查看日志。

单击工作节点。

![](3-2-001.png)

worker节点上的Pod（容器）输出的日志显示如下。
设置后获取日志可能需要一些时间。

![](3-2-002.png)

### 3-3 查看Kubernetes API服务器的审计日志

了解集群中发生的活动背后的上下文通常很有用。例如，确定谁做了什么以及何时执行合规性检查、识别安全异常并解决错误。

通过使用 OCI 审计服务，您可以获得以下审计事件。

- 每次在集群上执行 OKE 中的创建或删除等操作时，都会发出审计事件。
- 每当使用 Kubernetes API 服务器中的 kubectl 等工具对集群进行管理更改（例如创建服务）时，都会发出审计事件。

检查在 OKE 中执行的操作的日志。

展开左上角的汉堡菜单，然后从“身份和安全”中选择“审计”。

![](3-3-001.png)

在“关键字”中输入“ClustersAPI”，然后单击“搜索”按钮。

![](3-3-002.png)

显示如下。

![](3-3-003.png)

接下来查看Kubernetes API服务器的操作日志。

在“关键字”中输入“OKE API Server Admin Access”，然后单击“搜索”按钮。

![](3-3-004.png)

显示如下。

![](3-3-005.png)

这样就完成了对 Kubernetes API 服务器审计日志的检查。

4.监控与通知
----------------------------------

通过结合 OCI Notifications 和 Monitoring，当应用程序的指标超过阈值时将发出警报，并构建一个机制来发送电子邮件通知。

![](4-1-000.png)

### 4-1 通知设置

点击左上角的汉堡菜单，选择“开发者服务”-“通知”。

![](4-1-001.png)

单击创建主题按钮。

![](4-1-002.png)

**关于题目名称**
主题的名称在您的租赁中将是唯一的。
对于集体动手等多人共享同一环境的，请给出名字的首字母，例如`oci-devops-handson-01`和`handson-tn`，以免重名。
{: .notice--警告}

输入 oci-notifications 作为名称。

![](4-1-003.png)

单击“创建”按钮。

![](4-1-004.png)

确保它是“活跃的”。

![](4-1-005.png)

主题的创建现已完成。

接下来，创建订阅。

从左侧菜单中选择“订阅”。

![](4-1-006.png)

单击创建订阅按钮。

![](4-1-007.png)

在“电子邮件”中输入您的电子邮件地址。

![](4-1-008.png)

单击“创建”按钮。

![](4-1-009.png)

包含以下内容的电子邮件将发送到您设置的电子邮件地址。单击确认订阅以激活您的订阅。

![](4-1-010.png)

![](4-1-011.png)

确保它处于活动状态。
如果浏览器未激活，请刷新它。

![](4-1-012.png)

这样就完成了订阅的创建。

### 4-2 监控设置

在后续步骤中，我们将通过加载示例应用程序来增加 JVM 堆大小。
这里在OCI Monitoring中设置阈值，当超过阈值时会发出警报，并通知OCI Notifications中设置的邮箱地址。

点击左上角的汉堡菜单，选择“监控与管理”-“告警定义”。

![](4-2-001.png)

单击创建警报按钮。

![](4-2-002.png)

在“报警定义”中设置如下。

输入项|输入内容
-|-
警报名称 | 堆大小
指标命名空间|oracle_apm_monitoring
指标名称|HeapUsed
统计|最大值
维度名称|OkeClusterld
维度值 | 选择显示的 ClusterID
值|200000000
触发延迟分钟 | 1
主题|oci-通知

![](4-2-003.png)

![](4-2-006.png)

![](4-2-004.png)

单击保存警报按钮。

![](4-2-005.png)

这样就完成了“报警定义”的设置。

### 4-3 练习监控和通知

对示例应用程序施加了过多的访问负载。然后，配置设置，以便在发生警报后通过电子邮件通知您。

首先，构建一个服务器来加载。使用名为 JMeter 的负载测试应用程序设置环境。

#### 构建 JMeter 服务器

单击左上角的汉堡菜单并选择“计算”-“实例”。

![](4-3-001.png)

单击创建实例按钮。

![](4-3-002.png)

输入“jmeter”作为名称。

![](4-3-003.png)

然后单击图像和形状下的编辑。

![](4-3-004.png)

单击“形状”中的“更改形状”按钮。

![](4-3-030.png)

设定以下内容。

输入项|输入内容
-|-
外形系列 | AMD
形状名称|VM.Standard.E4.Flex
OCPU数量|2
内存量 (GB)|32

![](4-3-005.png)

单击选择形状按钮。

![](4-3-006.png)

单击网络下的编辑。

![](4-3-031.png)

在网络下，选择创建新的虚拟云网络。

![](4-3-007.png)

单击添加 SSH 密钥中的保存私钥按钮以下载私钥。

![](4-3-008.png)

单击“创建”按钮。

![](4-3-009.png)

确认登录所需的“公网IP地址”和“用户名”。
*复制并粘贴到文本编辑器中。

![](4-3-017.png)

#### 设置JMeter环境

登录到您创建的虚拟机以设置 JMeter 环境。

单击 Cloud Shell 图标以启动 Cloud Shell。

![](4-3-010.png)

![](4-3-011.png)

首先，将下载的私钥上传到 Cloud Shell。

单击 Cloud Shell 菜单。

![](4-3-012.png)

选择“上传”。

![](4-3-013.png)

单击从计算机中选择并选择您下载的私钥。

![](4-3-014.png)

单击“上传”按钮。

![](4-3-015.png)

单击隐藏。

![](4-3-016.png)

转到您的主目录。

```sh
cd ~
```

更改私钥的权限。

```sh
chmod 400 ssh-key-xxxx-xx-xx.key
```

登录到您的虚拟机。 使用您事先确认的用户名和公网IP地址。

```sh
ssh -i ssh-key-xxxx-xx-xx.key opc@***.***.***.***
```

输入是。

```sh
FIPS mode initialized
The authenticity of host '132.226.***.*** (132.226.***.***)' can't be established.
ECDSA key fingerprint is SHA256:oACNnKKWu3R9WUi3xpYVnunWcIoEF8NL5LztfUqlZ74.
ECDSA key fingerprint is SHA1:z2sVFWORAMBlpeuUgHx5Ou4X1Cg.
Are you sure you want to continue connecting (yes/no)? yes
```

切换到根用户。

```sh
sudo -i
```

安装 java-openjdk。

```sh
yum install -y java-1.8.0-openjdk
```

***命令结果***

```sh
~~~
Complete!
```

下载 JMeter。

```sh
wget https://ftp.jaist.ac.jp/pub/apache/jmeter/binaries/apache-jmeter-5.4.3.tgz
```

***命令结果***

```sh
--2022-02-07 08:33:34--  https://ftp.jaist.ac.jp/pub/apache/jmeter/binaries/apache-jmeter-5.4.3.tgz
Resolving ftp.jaist.ac.jp (ftp.jaist.ac.jp)... 150.65.7.130, 2001:df0:2ed:feed::feed
Connecting to ftp.jaist.ac.jp (ftp.jaist.ac.jp)|150.65.7.130|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 70796171 (68M) [application/x-gzip]
Saving to: ‘apache-jmeter-5.4.3.tgz’

100%[=======================================================================================>] 70,796,171  5.71MB/s   in 12s    

2022-02-07 08:33:47 (5.49 MB/s) - ‘apache-jmeter-5.4.3.tgz’ saved [70796171/70796171]
```

提取存档。

```sh
tar -zxvf apache-jmeter-5.4.3.tgz
```

创建一个工作目录。

```sh
mkdir test_work
```
转到“test_work”目录。

```sh
cd test_work
```

为 Jmeter 创建配置文件。

在[步骤 2-6] 中确认第 36 行的 `***.***.***.***` 示例应用程序结束（使用#2-6-oci-apm 跟踪）转换为点。

```sh
vim testplan.jmx
```

```sh
<?xml version="1.0" encoding="UTF-8"?>
<jmeterTestPlan version="1.2" properties="5.0" jmeter="5.4.3">
  <hashTree>
    <TestPlan guiclass="TestPlanGui" testclass="TestPlan" testname="Test Plan" enabled="true">
      <stringProp name="TestPlan.comments"></stringProp>
      <boolProp name="TestPlan.functional_mode">false</boolProp>
      <boolProp name="TestPlan.tearDown_on_shutdown">true</boolProp>
      <boolProp name="TestPlan.serialize_threadgroups">false</boolProp>
      <elementProp name="TestPlan.user_defined_variables" elementType="Arguments" guiclass="ArgumentsPanel" testclass="Arguments" testname="User Defined Variables" enabled="true">
        <collectionProp name="Arguments.arguments"/>
      </elementProp>
      <stringProp name="TestPlan.user_define_classpath"></stringProp>
    </TestPlan>
    <hashTree>
      <ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup" testname="Thread Group" enabled="true">
        <stringProp name="ThreadGroup.on_sample_error">continue</stringProp>
        <elementProp name="ThreadGroup.main_controller" elementType="LoopController" guiclass="LoopControlPanel" testclass="LoopController" testname="Loop Controller" enabled="true">
          <boolProp name="LoopController.continue_forever">false</boolProp>
          <intProp name="LoopController.loops">-1</intProp>
        </elementProp>
        <stringProp name="ThreadGroup.num_threads">80000</stringProp>
        <stringProp name="ThreadGroup.ramp_time">60</stringProp>
        <boolProp name="ThreadGroup.scheduler">false</boolProp>
        <stringProp name="ThreadGroup.duration"></stringProp>
        <stringProp name="ThreadGroup.delay"></stringProp>
        <boolProp name="ThreadGroup.same_user_on_next_iteration">true</boolProp>
      </ThreadGroup>
      <hashTree>
        <HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="HTTP Request" enabled="true">
          <elementProp name="HTTPsampler.Arguments" elementType="Arguments" guiclass="HTTPArgumentsPanel" testclass="Arguments" testname="User Defined Variables" enabled="true">
            <collectionProp name="Arguments.arguments"/>
          </elementProp>
          <stringProp name="HTTPSampler.domain">***.***.***.***</stringProp>
          <stringProp name="HTTPSampler.port"></stringProp>
          <stringProp name="HTTPSampler.protocol">http</stringProp>
          <stringProp name="HTTPSampler.contentEncoding"></stringProp>
          <stringProp name="HTTPSampler.path">/medalist</stringProp>
          <stringProp name="HTTPSampler.method">GET</stringProp>
          <boolProp name="HTTPSampler.follow_redirects">true</boolProp>
          <boolProp name="HTTPSampler.auto_redirects">false</boolProp>
          <boolProp name="HTTPSampler.use_keepalive">true</boolProp>
          <boolProp name="HTTPSampler.DO_MULTIPART_POST">false</boolProp>
          <stringProp name="HTTPSampler.embedded_url_re"></stringProp>
          <stringProp name="HTTPSampler.connect_timeout"></stringProp>
          <stringProp name="HTTPSampler.response_timeout"></stringProp>
        </HTTPSamplerProxy>
        <hashTree/>
      </hashTree>
    </hashTree>
  </hashTree>
</jmeterTestPlan>
```

施加负载。 如果要停止，可以用“Ctrl+C”停止。

```sh
JVM_ARGS="-Xms12G -Xmx12G"  ../apache-jmeter-5.4.3/bin/jmeter -n -t ./testplan.jmx -l ./testplan.jtl -e -o html_repo_testplan
```

如果中途因错误而停止，请使用以下命令删除“testplan.jtl”文件并重新加载。

```sh
rm -rf testplan.jtl
```

```sh
JVM_ARGS="-Xms12G -Xmx12G"  ../apache-jmeter-5.4.3/bin/jmeter -n -t ./testplan.jmx -l ./testplan.jtl -e -o html_repo_testplan
```

{% capture notice %}**关于启动Jmeter时的报错**
根据 Compute 中可用内存的状态，可能会出现以下错误。
```sh
JVM_ARGS="-Xms12G -Xmx12G"  ../apache-jmeter-5.4.3/bin/jmeter -n -t ./testplan.jmx -l ./testplan.jtl -e -o html_repo_testplan
OpenJDK 64-Bit Server VM warning: INFO: os::commit_memory(0x00000004f0800000, 12884901888, 0) failed; error='Cannot allocate memory' (errno=12)
#
# There is insufficient memory for the Java Runtime Environment to continue.
# Native memory allocation (mmap) failed to map 12884901888 bytes for committing reserved memory.
# An error report file with more information is saved as:
# /home/tniita_obs/test_work/hs_err_pid5725.log
```

如果出现上述错误，请将堆大小设置为 8G，如下所示。 

```sh
JVM_ARGS="-Xms8G -Xmx8G"  ../apache-jmeter-5.4.3/bin/jmeter -n -t ./testplan.jmx -l ./testplan.jtl -e -o html_repo_testplan
```
{% endcapture %}
<div class="notice--warning">
  {{ notice | markdownify }}
</div>

＃＃＃＃ 检查状态

检查负载状态。

点击左上角的汉堡菜单，选择“监控与管理”-“告警定义”。

![](4-3-018.png)

单击“堆大小”。

![](4-3-019.png)

红色虚线是设置的阈值。当超过此阈值时，将发出警报并通过电子邮件通知您。

![](4-3-020.png)

![](4-3-032.png)

要停止警报和通知，请取消选中“警报已启用”。

![](4-3-021.png)

也可以从 APM 检查状态。

单击左上角的汉堡菜单，然后选择“监控和管理”-“仪表板”。

![](4-3-022.png)

单击应用程序服务器。

![](4-3-023.png)

从 APM 域下拉菜单中选择 oke-handson-apm。

![](4-3-024.png)

检查目标 Pod 名称“frontend-app-xxxxxxxxxx-xxxxx”。

```sh
kubectl get pods
```

***命令结果***

```sh
NAME                              READY   STATUS    RESTARTS   AGE
・
・
・
frontend-app-56f7cfcb74-gpqh8     1/1     Running   0          23h
```

从下拉菜单中选择您确认的目标 Pod。

![](4-3-025.png)

默认情况下，您可以看到“最近 60 分钟”的状态。通过施加负载，“堆使用”的数量增加。在“Heap usage”中，可以按时间顺序查看状态。

![](4-3-026.png)

您可以从右上角的下拉菜单中查看过去的时间。如果选择“自定义”，则可以随时设置。

![](4-3-027.png)

要设置，请指定时间并单击“确定”按钮。

![](4-3-028.png)

您将收到以下电子邮件作为通知。

![](4-3-029.png)

动手到此结束。谢谢你的辛劳工作！

5、本次使用的示例应用补充说明
----------------------------------

下面对本示例应用程序中的 APM 设置进行补充说明。 〉〉

在这个示例应用程序中，以下两点被实现为 APM 设置。

- 将 APM 浏览器代理端点和公共数据密钥设置为“index.html”（然后构建/推送容器图像）
- 将 APM 服务器代理端点和私有数据密钥设置为秘密资源

这里的补充说明主要针对第二点。

我们来看看这次使用的Manifest。

首先，查看前端应用的Manifest。
这里只摘录了 Deployment 资源。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-app
  labels:
    app: frontend-app
    version: v1
spec:
  replicas: 1
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
        image: iad.ocir.io/orasejapan/frontend-app-apm
        ports:
        - containerPort: 8082
        env:
        - name: tracing.data-upload-endpoint
          valueFrom:
            secretKeyRef:
              name: apm-secret
              key: endpoint
        - name: tracing.private-data-key
          valueFrom:
            secretKeyRef:
              name: apm-secret
              key: private-key
```

让我们关注第 25-35 行。

```yaml
~~~
        env:
        - name: tracing.data-upload-endpoint
          valueFrom:
            secretKeyRef:
              name: apm-secret
              key: endpoint
        - name: tracing.private-data-key
          valueFrom:
            secretKeyRef:
              name: apm-secret
              key: private-key
```

APM 端点和私有数据密钥是从具有环境变量名称“tracing.data-upload-endpoint”和“tracing.private-data-key”的 Secret 资源加载的。
此处指定的 Secret 资源是在 [2-5 APM settings for the sample application (server side)]（#2-5 - apm settings for sample application server side）中创建的。

在应用程序端 (Helidon)，APM 服务器代理读取此环境变量并将跟踪信息和指标上传到 APM。

我这次指定为Secret，但也可以在每个容器应用程序（Helidon）的配置文件（`microprofile-config.properties`）中指定。

后端应用和数据源应用的Manifest也设置为从环境变量中获取APM端点和数据私钥。
