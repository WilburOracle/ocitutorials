---
title: "Oracle 云基础设施 (OCI) DevOps 入门 -OKE 版-"
excerpt: "使用 OCI DevOps 在容器应用程序开发中学习 CI/CD。"
layout: single
order: "012"
tags:
date: "2022-04-06"
lastmod: "2022-04-06"
---

OCI DevOps 是在 OCI 上构建 CI/CD 环境的托管服务。在这里，我们将描述使用 Oracle Container Engine for Kubernetes (OKE) 服务构建 Kubernetes 集群、设置工件环境和 OCI DevOps 以及实施和运行 CI/CD 管道的步骤。
通过遵循此过程，您可以在使用 OCI DevOps 的容器应用程序开发中学习 CI/CD。

**关于适用于 Kubernetes 的 Oracle 容器引擎 (OKE)**
Oracle Container Engine for Kubernetes 是在 Oracle 云基础设施 (OCI) 上提供的完全托管、可扩展且高度可用的托管 Kubernetes 服务。
详情请查看页面[这里](https://www.oracle.com/jp/cloud-native/container-engine-kubernetes/)。
{: .notice--info}

先决条件
--------
-环境
  - [OCI DevOps 准备](/ocitutorials/cloud-native/devops-for-commons/) 完成

整体结构
--------

目标是构建下图所示的环境。搭建环境后，更改示例源代码，以“git push”命令的执行为触发器执行CI/CD流水线，确认从部署示例容器应用到OKE集群的流程是自动执行的。去做。

![](1-012.png)

工作配置有“准备”和“OCI DevOps环境搭建”两种。

在“准备”中，我们将使用开头介绍的 OKE 构建一个 Kubernetes 集群。然后，设置使用 OCI DevOps 服务所需的认证令牌，获取示例应用程序，并设置使用 OCI DevOps 的 OKE 集群的动态组策略。

在“OCI DevOps环境搭建”中，注册要部署的OKE集群，设置和管理代码仓库和工件注册表，构建构建管道和部署管道为OCI DevOps管道，管道设置触发功能为自动化，最后，更改源代码并执行“git push”命令来检查构建的管道的运行情况和部署的应用程序的运行情况。

相关的功能和服务在这里整理。

**代码库**
代码存储库是 OCI DevOps 的功能之一，它允许您对源代码进行版本控制。您可以像 GitHub 和 GitLab 一样创建存储库，在管理源代码版本的同时进行高效开发。
{: .notice--info}

**工件注册表**
Artifact Registry 是 OCI 用于存储、共享和管理软件开发包的服务。与 OCI DevOps 集成使用。
请查看页面 [此处](https://docs.oracle.com/en-us/iaas/artifacts/using/overview.htm) 了解详细信息。
{: .notice--info}

**容器注册表**
容器注册表是用于存储和共享容器镜像的专用注册表。 OCI 有一个专门用于容器镜像的注册表服务，称为 Oracle 云基础设施注册表 (OCIR)。与 OCI DevOps 集成使用。
有关详细信息，请查看页面 [此处](https://docs.oracle.com/ja-jp/iaas/Content/Registry/Concepts/registryoverview.htm)。
{: .notice--info}

准备流程
---------------------------------
* 1.OKE设置
* 2. 认证令牌设置
* 3. 获取示例应用程序
* 4.策略设置

1.OKE设置
---------------------------------

![](1-125.png)

### 1-1 从 OCI 仪表板构建 OKE 集群

构建一个 3 个节点和 1 个集群的 OKE 集群。展开左上角的汉堡菜单，从“开发者服务”中选择“Kubernetes Cluster (OKE)”。

![](1-001.png)

从下拉菜单中选择“xxxxxx (root)”。
如果被选中，请继续。

![](1-142.png)

单击创建集群按钮。

![](1-002.png)

确保选择了快速创建并单击启动工作流按钮。

![](1-003.png)

确保它具有以下内容：

* 名称：cluster1
* Kubernetes API 端点：公共端点
* Kubernetes Worker 节点：私有 Worker
* 形状：VM Standard.E3.Flex
* 选择 OCPU 数量：1
* 内存（GB）：16

![](1-004.png)

**关于 Kubernetes 版本**
上面屏幕截图中显示的 Kubernetes 版本和控制台中显示的实际 Kubernetes 版本可能会有所不同。
对于本次动手操作，Kubernetes 版本无关紧要，因此请继续使用控制台上选择的默认版本。
{: .notice--info}

单击屏幕上的“下一步”按钮。

![](1-005.png)

单击屏幕上的“创建集群”按钮。

![](1-006.png)

单击屏幕上的“关闭”按钮。

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

``` 嘘
kubectl get node
```
***命令结果***
```sh
NAME          STATUS   ROLES   AGE     VERSION
10.0.10.141   Ready    node    6m33s   v1.21.5
10.0.10.212   Ready    node    6m8s    v1.21.5
10.0.10.231   Ready    node    6m23s   v1.21.5
```

这样就完成了OKE集群的搭建。

2. 身份验证令牌设置
---------------------------------

单击右上角的个人资料图标，然后选择您的个人资料名称。

![](1-023.png)

从左侧菜单中选择“身份验证令牌”。

![](1-024.png)

单击“创建令牌”按钮。

![](1-025.png)

在描述中输入“oci-devops-handson”，然后单击生成令牌按钮。

![](1-026.png)

单击复制，然后单击关闭按钮。您将在稍后的步骤中需要复制的身份验证令牌，因此将其粘贴到文本编辑器中。

![](1-027.png)

这样就完成了身份验证令牌的创建。

3. 样本申请获取
---------------------------------

在此处下载示例应用程序。

单击上方菜单中的“Cloud Shell”图标以启动 Cloud Shell。

![](1-028.png)

开机画面

![](1-029.png)

启动后，执行以下命令。

```sh
wget https://objectstorage.ap-tokyo-1.oraclecloud.com/n/orasejapan/b/oci-devops-handson/o/oke%2Foci-devops-oke.zip
```
***命令结果***
```sh
--2021-12-06 07:41:06--  https://objectstorage.uk-london-1.oraclecloud.com/p/NHrjAcamTrUsDXrJybmjKYxDdEH5qus9HMDlnh9lGRIp0GOELTK-wScn3aAehiMX/n/orasejapan/b/devday2021/o/oci-devops-oke.zip
Resolving objectstorage.uk-london-1.oraclecloud.com (objectstorage.uk-london-1.oraclecloud.com)... 134.70.60.1, 134.70.64.1, 134.70.56.1
Connecting to objectstorage.uk-london-1.oraclecloud.com (objectstorage.uk-london-1.oraclecloud.com)|134.70.60.1|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 1112595 (1.1M) [application/x-zip-compressed]
Saving to: ‘oke%2Foci-devops-oke.zip’

100%[=======================================================================================================>] 1,112,595   3.29MB/s   in 0.3s   

2021-12-06 07:41:06 (3.29 MB/s) - ‘oke%2Foci-devops-oke.zip’ saved [1112595/1112595]
```

解压缩下载的 zip 文件。

```sh
unzip oke%2Foci-devops-oke.zip
```

确保有一个名为“oci-devops-oke”的目录。

4.策略设置
---------------------------------

在 [事前准备](/ocitutorials/cloud-native/devops-for-commons/) 中设置额外的必要策略。

其他必需的政策是：

政策|说明
-|-
允许动态组 OCI_DevOps_Dynamic_Group_OKE 管理隔离专区 ID 隔离专区 OCID|策略中的集群系列，以允许 OCI DevOps 管理 OKE

在本次实践中，我们将使用脚本来设置策略。
该脚本包含在您之前解压缩的相关材料中。

启动 Cloud Shell 并运行以下命令。

```sh
chmod +x oci-devops-oke/prepare/prepare.sh
```

运行脚本。

```sh
./oci-devops-oke/prepare/prepare.sh
```

***命令结果***
```sh
ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
{
  "data": {
    "compartment-id": "ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "defined-tags": {
      "Oracle-Tags": {
        "CreatedBy": "oracleidentitycloudservice/xxxxxxxxxxx@xxxxx",
        "CreatedOn": "2021-11-18T07:41:50.746Z"
      }
    },
    "description": "OCI_DevOps_Policy",
    "freeform-tags": {},
    "id": "ocid1.policy.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "inactive-status": null,
    "lifecycle-state": "ACTIVE",
    "name": "OCI_DevOps_Policy",
    "statements": [
      "Allow dynamic-group OCI_DevOps_Dynamic_Group to manage cluster-family in compartment id ocid1.tenancy.oc1..aaaaaaaatoseshh5pf6ujhbofmersp62iui4wx2iymfvpeso7dzg2mxqfafq"
    ],
    "time-created": "2021-11-18T07:41:50.880000+00:00",
    "version-date": null
  },
  "etag": "31c9339700c6132a1b6205df041ad52fcf66be51"
}
```

策略配置现已完成。


准备工作现已完成。

OCI DevOps 环境搭建
---------------------------------
* 1.环境
* 2. 代码仓库
* 3. 神器
* 4. 部署管道
* 5. 构建管道
* 6. 触发
* 7.流水线执行
* 8. 确认部署

1.环境
---------------------------------

![](1-128.png)

从这里，操作 [Preparation](/ocitutorials/cloud-native/devops-for-commons/) 中内置的 DevOps 实例。

从 OCI 控制台左上角的汉堡菜单中，选择 **Developer Services** > **DevOps** > **Projects**。

![](1-201.png)

选择“oci-devops-handson”。

![](1-202.png)

注册 OKE 集群以将应用程序从 OCI DevOps 部署到 OKE 集群。

选择创建环境。

![](1-043.png)

为“环境类型”选择“Oracle Kubernetes Engine”，为“名称”选择“oke-cluster”。

![](1-044.png)

单击下一步按钮。

![](1-045.png)

在“集群”中选择“集群1”。

![](1-046.png)

单击创建环境按钮。

![](1-047.png)

单击面包屑中的 oci-devops-handson。

![](1-048.png)

环境创建现已完成。

2.代码仓库
---------------------------------

![](1-129.png)

### 2-1. 创建代码仓库

OCI DevOps Code Repository 在 OCI DevOps 上创建您自己的私有代码存储库。

单击创建存储库按钮。

![](1-049.png)

在“Repository Name”中输入“oci-devops-handson”，点击“Create Repository”按钮。

![](1-050.png)

![](1-051.png)

这样就完成了代码仓库的创建。

### 2-2.推送克隆的示例代码

#### 2-2-1. 获取克隆目的地信息

将下载的示例代码推送到“oci-devops-handson”存储库。

单击“克隆”按钮以获取推送目标。

![](1-052.png)

单击通过 HTTPS 只读克隆下的复制，然后单击关闭按钮。将复制的内容粘贴到文本编辑器中。

![](1-053.png)

#### 2-2-2. 获取“oci-devops-handson”仓库的用户名和密码

使用“oci-devops-handson”存储库需要用户名和密码。

用户名是`<tenancy name>/<username>`。

检查 <用户名>。对于您的用户名，单击右上角的个人资料图标并选择您的个人资料名称。

![](1-054.png)

复制“用户详细信息屏幕”的红框部分并将其粘贴到文本编辑器中。

![](1-055.png)

然后检查 <租户名称>。

单击右上角的配置文件图标，然后选择租赁。

![](1-056.png)

复制“Tenancy Details”中的“Name”红框并将其粘贴到文本编辑器中。
此外，复制后续步骤中所需的“对象存储命名空间”的红框部分，并将其粘贴到文本编辑器中。

![](1-057.png)

下面，将其应用于文本编辑器中粘贴的内容并使用它。

用户名：`<租户名称>/<用户名>`

对于密码，请使用预先创建的“身份验证令牌”。


#### 2-2-3. 将示例代码推送到“oci-devops-handson”仓库

使用 Cloud Shell，拉取“oci-devops-handson”存储库。对于存储库的 URL，请指定您之前粘贴到文本编辑器中的 URL。
请根据您的环境替换“xxxxxxxxxx”。

```sh
git clone https://devops.scmservice.xx-xxxxxx-1.oci.oraclecloud.com/namespaces/xxxxxxxxxx/projects/oci-devops-handson/repositories/oci-devops-handson
```
对于用户名，输入您之前确认的内容，对于密码，输入预先创建的身份验证令牌。 *输入密码时不会显示密码。
```sh
Username for 'https://devops.scmservice.xx-xxxxxx-1.oci.oraclecloud.com': xxxxxxxxx/oracleidentitycloudservice/xxxxxx.xxxxxxxx@oracle.com
Password for 'https://xxxxxxxxxx/oracleidentitycloudservice/xxxxxx.xxxxxxxx@oracle.com@devops.scmservice.xx-xxxxxx-1.oci.oraclecloud.com':
```
```sh
remote: Counting objects: 2, done
remote: Finding sources: 100% (2/2)
remote: Getting sizes: 100% (1/1)
remote: Total 2 (delta 0), reused 2 (delta 0)
Unpacking objects: 100% (2/2), done.
```

确认下面有一个“oci-devops-handson”目录。

```sh
ls
```
```sh
oci-devops-handson  oci-devops-oke  oke%2Foci-devops-oke.zip
```

将下载的示例代码复制到“oci-devops-handson”目录。

```sh
cp -R oci-devops-oke/* ./oci-devops-handson
```

提交然后推送。

```sh
cd ./oci-devops-handson
```
```sh
git add -A .
```
为“<email>”输入任何电子邮件地址，为“<user_name>”输入任何用户名。
```sh
git config --global user.email "<email>"
```
```sh
git config --global user.name "<user_name>"
```
提交。
```sh
git commit -m "first commit"
```
**命令结果**
```sh
[main e964068] first commit
 6 files changed, 111 insertions(+)
 create mode 100644 Dockerfile
 create mode 100644 README.md
 create mode 100644 build_spec.yaml
 create mode 100644 content.html
 create mode 100644 deploy.yaml
 create mode 100755 prepare/prepare.sh
```
mainブランチを指定します。
```sh
git branch -M main
```
リポジトリにプッシュします。
```sh
git push -u origin main
```
ユーザ名は、先ほど確認した内容、パスワードは事前準備で作成した認証トークンを入力します。※パスワードは入力時に表示されません。

**命令结果**
```sh
Username for 'https://devops.scmservice.xx-xxxxxx-1.oci.oraclecloud.com': xxxxxxxxx/oracleidentitycloudservice/xxxxxx.xxxxxxxx@oracle.com
Password for 'https://xxxxxxxxxx/oracleidentitycloudservice/xxxxxx.xxxxxxxx@oracle.com@devops.scmservice.xx-xxxxxx-1.oci.oraclecloud.com':
```
```sh
Counting objects: 10, done.
Delta compression using up to 2 threads.
Compressing objects: 100% (8/8), done.
Writing objects: 100% (9/9), 1.93 KiB | 0 bytes/s, done.
Total 9 (delta 0), reused 0 (delta 0)
To https://devops.scmservice.xx-xxxxxx-1.oci.oraclecloud.com/namespaces/xxxxxxxxxx/projects/oci-devops-handson/repositories/oci-devops-handson
   b52f2cd..d16bcff  main -> main
Branch main set up to track remote branch main from origin.
```

我也会从 OCI 控制台检查它。

![](1-135.png)

![](1-058.png)

这样就完成了代码仓库的创建。

3.神器
---------------------------------

![](1-130.png)

### 3-1. 设置 OCIR

设置存储由构建管道构建的容器镜像的容器镜像注册表。
OCI 使用 Oracle 容器映像注册表 (OCIR)。

**关于 OCIR**
提供完全托管的符合 Docker v2 标准的容器注册表的服务。低延迟是通过部署在与 OKE 相同的区域来实现的。详情请查看页面[这里](https://www.oracle.com/jp/cloud-native/container-registry/)。
{: .notice--info}

点击左上角的汉堡菜单，选择“开发者服务”-“容器注册表”。

![](1-059.png)

单击创建存储库按钮。

![](1-060.png)

在“Repository Name”中输入“devops-handson”，在“Access”中选择“Public”，点击“Create Repository”按钮。

![](1-061.png)

**关于存储库名称**
OCIR 存储库名称在您的租约中是唯一的。
多人共享同一环境，如集体动手，请在名称前加上“devops-handson01”、“devops-handson-tn”等名称的首字母，避免名称重复。
{: .notice--警告}

OCIR 设置现已完成。

### 3-2. 创建工件注册表

在工件注册表中注册从 OCI DevOps 部署到 OKE 集群时要使用的清单。

使用此注册清单，您可以从 OCI DevOps 自动部署到 OKE 集群。

创建工件注册表。
点击左上角的汉堡菜单，选择“开发者服务”-“工件注册表”。

![](1-062.png)

单击创建存储库按钮。

![](1-063.png)

在“名称”中输入“artifact-repository”并取消选中“Immutable Artifact”。

![](1-064.png)

单击“创建”按钮。

![](1-065.png)

接下来，上传清单，这将是您的工件。

返回 Cloud Shell，在克隆的示例代码中更改“deploy.yaml”中的容器镜像注册表路径。

将“<your-object-storage-namespace>”替换为您之前获得的`<object storage namespace>`并保存。

在存储库名称中，如果您指定了一个唯一名称，例如“devops-handson-tn”（示例），请相应地进行更改。

*如果区域不是Ashburn（us-ashburn-1），请根据您的环境更改“iad.ocir.io”部分。

可以在 [此处](https://docs.oracle.com/en-us/iaas/Content/Registry/Concepts/registryprerequisites.htm) 找到每个区域的 OCIR 端点。
从现在开始，我们将继续使用“iad.ocir.io”。

```sh
cd ~
```
```sh
vim ./oci-devops-oke/deploy.yaml
```
```sh
apiVersion: apps/v1 
kind: Deployment 
metadata:
  name: devops-handson
spec:
  selector: 
    matchLabels:
      app: devops-handson
  replicas: 3 
  template: 
    metadata:
      labels:
        app: devops-handson
    spec:
      containers:
      - name: devops-handson
        image: iad.ocir.io/<your-object-storage-namespace>/devops-handson:${BUILDRUN_HASH}
        ports:
        - containerPort: 80 
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  selector:
    app: devops-handson
```

单击上传工件按钮。

![](1-066.png)

在“Artifact Path”中输入“deploy.yaml”，在“Version”中输入“1”，“上传方式”选择“Cloud Shell”，点击“Launch Cloud Shell”按钮，点击“Copy”点击。
将复制的命令粘贴到已启动的 Cloud Shell 上。

![](1-067.png)

将“./<file-name>”替换为“./oci-devops-oke/deploy.yaml”，然后按 Enter。
```sh
oci artifacts generic artifact upload-by-path \
>   --repository-id ocid1.artifactrepository.oc1.xx-xxxxxx-1.0.amaaaaaassl65iqaluitbpvjd5inibwke4axtb7l4so6jgvsywlh5m2ohgca \
>   --artifact-path deploy.yaml \
>   --artifact-version 1 \
>   --content-body ./oci-devops-oke/deploy.yaml #file-nameから変更します。
{
  "data": {
    "artifact-path": "deploy.yaml",
    "compartment-id": "ocid1.compartment.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "defined-tags": {},
    "display-name": "deploy.yaml:1",
    "freeform-tags": {},
    "id": "ocid1.genericartifact.oc1.xx-xxxxxx-1.0.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "lifecycle-state": "AVAILABLE",
    "repository-id": "ocid1.artifactrepository.oc1.xx-xxxxxx-1.0.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "sha256": "faa5ffec716cf718b5a1a3a5b4ced0e12c2c59151d3ff6fcab0cf0d324e3ca07",
    "size-in-bytes": 574,
    "time-created": "2021-11-22T05:23:24.150000+00:00",
    "version": "1"
  }
}
```

单击“关闭”按钮。

![](1-068.png)

确认已上传。如果您没有看到它，请刷新您的浏览器。

![](1-069.png)

这样就完成了 Artifact Registry 的创建。

### 3-3. 添加工件

进行设置，以便您可以使用在 OCI DevOps 中设置的 OCIR 和 Artifact Registry。

首先，从 OCIR 设置。
从左上角的汉堡菜单中选择“开发者服务”-“项目”。

![](1-032.png)

选择“oci-devops-handson”项目。

![](1-070.png)

单击添加工件按钮。

![](1-071.png)

为“名称”输入“ocir”，并在清单中为“输入容器注册表中映像的完全限定路径”输入重写的路径。
对于下面的“<your-object-storage-namespace>”，输入您预先获取的`<object storage namespace>`。

在存储库名称中，如果您指定了一个唯一名称，例如“devops-handson-tn”（示例），请相应地进行更改。

```sh
iad.ocir.io/<your-object-storage-namespace>/devops-handson:${BUILDRUN_HASH}
```

![](1-072.png)

单击“添加”按钮。

![](1-073.png)

接下来，设置工件注册表。

单击添加工件按钮。

![](1-136.png)

“Name”输入“artifact-repository”，“Type”选择“Kubernetes Manifest”，点击“Select”按钮。

![](1-074.png)

检查“工件存储库”。

![](1-075.png)

单击选择按钮。

![](1-076.png)

单击另一个“选择”按钮。

![](1-077.png)

检查“deploy.yaml:1”。

![](1-078.png)

单击选择按钮。

![](1-076.png)

单击“添加”按钮。

![](1-073.png)

确认您已注册。

![](1-079.png)

这样就完成了工件的添加。

4. 部署管道
---------------------------------

![](1-131.png)

结合您刚刚注册的工件注册表，创建一个用于将您的应用程序自动部署到 OKE 集群的管道。

单击左侧菜单中的“部署管道”。

![](1-080.png)

单击创建管道按钮。

![](1-081.png)

为“管道名称”输入“部署管道”。

![](1-082.png)

单击创建管道按钮。

![](1-083.png)

单击添加阶段。

![](1-084.png)

选择将清单应用到 Kubernetes 集群。

![](1-085.png)

单击“下一步”按钮。

![](1-086.png)

进行以下设置并单击“选择工件”按钮。

*阶段名称：部署到OK
* 环境：oke-cluster
* Kubernetes 命名空间覆盖选项：默认

![](1-087.png)

检查“工件存储库”。

![](1-088.png)

单击保存更改按钮。

![](1-089.png)

返回“添加舞台”屏幕并单击“添加”按钮。

![](1-073.png)

确认您已成功注册。

![](1-090.png)

单击面包屑中的 oci-devops-handson。

![](1-091.png)

部署管道的创建现已完成。

5.构建管道
---------------------------------

![](1-132.png)

在OCI DevOps中使用的虚拟机上，从代码仓库下载源码，构建容器镜像，将容器镜像构建存储在OCIR中，创建链接部署管道的构建管道。。
首先创建一个构建容器映像的“托管构建”阶段。

单击创建构建管道按钮。

![](1-092.png)

为名称输入构建管道。

![](1-093.png)

单击“创建”按钮。

![](1-016.png)

单击构建管道。

![](1-094.png)

单击添加阶段。

![](1-084.png)

选择“托管构建”。

![](1-095.png)

单击下一步按钮。

![](1-005.png)

进行以下设置并单击“选择”按钮。
“build_spec.yaml”是一个文件，它定义了要在构建管道处理的虚拟机中执行的命令任务。
在此定义文件中，定义您要在构建期间执行的任务，例如应用程序测试和容器映像构建。

在这里，注册定义的“build_spec.yaml”文件。

* 阶段名称：container-image-build
* 构建规范文件路径可选：build_spec.yaml

![](1-096.png)

在 Select Primary Code Repository 屏幕上，配置以下设置。

* 连接类型：OCI 代码库
*“oci-devops-handson”
* 创建源名称：main

![](1-097.png)

单击“保存”按钮。

![](1-098.png)

返回“添加舞台”屏幕后，单击“添加”按钮。

![](1-073.png)

接下来，创建一个“Delivery Artifact”阶段，将容器图像存储在 OCIR 中。
单击加号部分并选择添加阶段。

![](1-099.png)

选择交付工件。

![](1-100.png)

单击下一步按钮。

![](1-005.png)

为 Stage Name 输入“container-image-ship”，然后单击 Select Artifact 按钮。

![](1-101.png)

检查“ocir”。

![](1-102.png)

单击“添加”按钮。

![](1-103.png)

为构建配置/结果工件名称输入“handson_image”。

![](1-104.png)

单击“添加”按钮。

![](1-073.png)

最后，创建一个与部署管道一起使用的触发器部署阶段。
单击加号部分并选择添加阶段。

![](1-105.png)

选择触发器部署。

![](1-106.png)

单击下一步按钮。

![](1-005.png)

为 Stage Name 输入“connect-deployment-pipeline”，然后单击 Select Deployment Pipeline 按钮。

![](1-107.png)

检查“部署管道”。

![](1-108.png)

单击“保存”按钮。

![](1-098.png)

返回“添加舞台”屏幕后，单击“添加”按钮。

![](1-073.png)

确认您已成功注册。

![](1-109.png)

单击面包屑中的 oci-devops-handson。

![](1-110.png)

这样就完成了构建管道的创建。

6.触发
---------------------------------

![](1-133.png)

在触发器中更改源代码并触发对代码仓库的“git push”命令，自动启动目前已创建的“构建管道”和“部署管道”，允许部署容器应用在 OKE 集群上。

单击创建触发器按钮。

![](1-111.png)

进行以下设置并单击“选择”按钮。

* 名称：推触发器
* 源连接：OCI 代码库

![](1-112.png)

检查“oci-devops-handson”。

![](1-113.png)

单击“保存”按钮。

![](1-098.png)

单击“添加操作”按钮。

![](1-114.png)

单击选择按钮。

![](1-115.png)

检查“构建管道”。

![](1-116.png)

单击“保存”按钮。

![](1-098.png)

勾选“事件选项”中的“推送”。

![](1-117.png)

单击“保存”按钮。

![](1-098.png)

返回“创建触发器”屏幕，然后单击“创建”按钮。

![](1-016.png)

确认您已成功注册。

![](1-118.png)

触发器创建现已完成。

7.流水线执行
---------------------------------

![](1-134.png)

实际修改源码，以“git push”为触发，自动部署到OKE集群。

切换到目标目录。

```sh
cd ~
```
```sh
cd oci-devops-handson
```
「CI/CD」⇒「DevDay」に修正して、保存します。
```sh
vim content.html
```
```sh
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<title>OCI DevOps Hands-On</title>
</head>
<body>
<h1>Hello OCI DevOps DevDay!!</h1>
</body>
</html>
```
```sh
git add -A .
```
```sh
git commit -m "change code"
```
***命令结果***
```sh
[main 92df932] change code
 1 file changed, 1 insertion(+), 1 deletion(-)
```
```sh
git branch -M main
```
```sh
git push -u origin main
```
对于用户名，输入您之前确认的内容，对于密码，输入预先创建的身份验证令牌。 *输入密码时不会显示密码。
```sh
Username for 'https://devops.scmservice.xx-xxxxxx-1.oci.oraclecloud.com': xxxxxxxxx/oracleidentitycloudservice/xxxxxx.xxxxxxxx@oracle.com
Password for 'https://xxxxxxxxxx/oracleidentitycloudservice/xxxxxx.xxxxxxxx@oracle.com@devops.scmservice.xx-xxxxxx-1.oci.oraclecloud.com': 
Counting objects: 7, done.
Delta compression using up to 2 threads.
Compressing objects: 100% (4/4), done.
Writing objects: 100% (4/4), 349 bytes | 0 bytes/s, done.
Total 4 (delta 3), reused 0 (delta 0)
remote: Resolving deltas: 100% (3/3)
To https://devops.scmservice.xx-xxxxxx-1.oci.oraclecloud.com/namespaces/xxxxxxxxxx/projects/oci-devops-handson/repositories/oci-devops-handson
   7dca9a7..92df932  main -> main
Branch main set up to track remote branch main from origin.
```

从面包屑中选择“oci-devops-handson”。

![](1-141.png)

在最新构建历史下，选择目标构建管道。

![](1-120.png)

您可以看到构建管道的进度。 如果一切正常，您将看到一个绿色的复选图标。

此外，随着构建管道的开始和结束，将向注册的电子邮件地址发送具有以下标题的通知。

* [DevOps Notification] BuildRun STARTED: push-trigger:20211124083749
* [DevOps Notification] BuildRun SUCCEEDED: push-trigger:20211124083749

![](1-121.png)

确认后，点击面包屑中的 oci-devops-handson。

![](1-137.png)

在最新部署下，选择所需的部署。

![](1-122.png)

如果一切正常，您将看到一个绿色的复选图标。
该应用程序现在已部署到 OKE 集群。

![](1-123.png)

当部署管道开始和结束时，您还将在您注册的电子邮件地址收到以下通知。

* [DevOps Notification] Deployment STARTED: devopsdeployment20211124084745
* [DevOps Notification] Deployment SUCCEEDED: devopsdeployment20211124084745

管道执行现已完成。

8. 确认部署
---------------------------------

使用 Cloud Shell 检查 OKE 集群的部署状态。

```sh
kubectl get pods
```
```sh
NAME                              READY   STATUS    RESTARTS   AGE
devops-handson-565f4b6d96-2g98c   1/1     Running   0          13m
devops-handson-565f4b6d96-89w84   1/1     Running   0          12m
devops-handson-565f4b6d96-bbgq2   1/1     Running   0          12m
```

检查从网络浏览器访问的“EXTERNAL-IP”。

```sh
kubectl get services
```
```sh
NAME         TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)        AGE
frontend     LoadBalancer   10.96.139.8   132.xxx.xxx.xxx   80:32120/TCP   34m
kubernetes   ClusterIP      10.96.0.1     <none>           443/TCP        5d7h
```
启动浏览器并访问确认的外部 IP 地址。
如果显示以下屏幕，则说明完成。

http://<EXTERNAL-IP>/content.html

![](1-140.png)

部署确认现已完成。

我们能够自动化从代码更改到部署的一系列流程。

9.【可选】构建配置文件说明
------------------

在这里，我们将解释动手操作中使用的构建配置文件（`build_spec.yaml`）。

在本次实践中，我们在示例应用程序中预先准备了一个构建配置文件（`build_spec.yaml`）。

在 OCI DevOps 中定义构建步骤时，这个文件是绝对必要的。

在实践中，我在[5. Build Pipeline]（#5 Build Pipeline）的过程中使用了它。

该文件如下所示：

```yaml
version: 0.1
component: build                    
timeoutInSeconds: 10000             
runAs: root                         
shell: bash                        
env:  
  exportedVariables:
    - BUILDRUN_HASH               

steps:
  - type: Command
    name: "Export variables"
    timeoutInSeconds: 40
    command: |
      export BUILDRUN_HASH=`echo ${OCI_BUILD_RUN_ID} | rev | cut -c 1-7`
      echo "BUILDRUN_HASH: " ${BUILDRUN_HASH}
    onFailure:
      - type: Command
        command: |
          echo "Handling Failure"
          echo "Failure successfully handled"
        timeoutInSeconds: 40
        runAs: root
  - type: Command
    name: "Docker Build"
    command: |
      docker build -t handson_image .
    onFailure:
      - type: Command
        command: |
          echo "Failured docker build"
        timeoutInSeconds: 60
        runAs: root
  - type: Command
    name: "Trivy Image Scan"
    timeoutInSeconds: 180
    command: |
      curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.21.0
      trivy image handson_image
    onFailure:
      - type: Command
        command: |
          echo "Trivy Scan Error"
        timeoutInSeconds: 40
        runAs: root

outputArtifacts:
  - name: handson_image
    type: DOCKER_IMAGE
    location: handson_image:latest
```

这一次，在构建步骤中要执行三个任务。

第一步是

```yaml
  - type: Command
    name: "Export variables"
    timeoutInSeconds: 40
    command: |
      export BUILDRUN_HASH=`echo ${OCI_BUILD_RUN_ID} | rev | cut -c 1-7`
      echo "BUILDRUN_HASH: " ${BUILDRUN_HASH}
    onFailure:
      - type: Command
        command: |
          echo "Handling Failure"
          echo "Failure successfully handled"
        timeoutInSeconds: 40
        runAs: root
```

节中定义

在这一步中，我们生成一个哈希值，用于稍后构建的容器镜像的标签，并将其导出为环境变量“BUILDRUN_HASH”。

下一步是

```yaml
  - type: Command
    name: "Docker Build"
    command: |
      docker build -t handson_image .
    onFailure:
      - type: Command
        command: |
          echo "Failured docker build"
        timeoutInSeconds: 60
        runAs: root
```

节中定义

此步骤使用 `docker build` 命令构建容器映像。

最后一步是

```yaml
  - type: Command
    name: "Trivy Image Scan"
    timeoutInSeconds: 180
    command: |
      curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.21.0
      trivy image handson_image
    onFailure:
      - type: Command
        command: |
          echo "Trivy Scan Error"
        timeoutInSeconds: 40
        runAs: root
```

节中定义

在这一步中，我们使用容器镜像漏洞扫描产品 trivy 来检查构建的容器镜像中的漏洞。

**关于琐碎**
trivy 是一个用于容器镜像的开源漏洞诊断工具。
有关详细信息，请参阅 [此处](https://github.com/aquasecurity/trivy)。
{: .notice--info}

此外，在第二个构建步骤（构建容器镜像的步骤）中构建的工件（容器镜像）是

```yaml
outputArtifacts:
  - name: fn-hello-image
    type: DOCKER_IMAGE
    location: fn-hello
```

输出为名为 `handson_image` 的容器图像（`type: DOCKER_IMAGE`）。

这个 `handson_image` 工件在 [5. Build Pipeline] (#5 Build Pipeline) 步骤中被指定为 `build configuration/result artifact name` 并上传到工件存储库。 ​​​​

构建配置文件（`build_spec.yaml`）的解释到此结束。

**关于构建配置文件**
有关构建配置文件的更多信息，请参阅 [此处的文档](https://docs.oracle.com/en-us/iaas/Content/devops/using/build_specs.htm)。
{: .notice--info}
