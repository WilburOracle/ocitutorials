---
title: "在 Kubernetes 上部署示例应用程序和 CI/CD 的经验"
excerpt: "本内容让您体验使用 OKE 部署示例应用程序和 CI/CD。 除了 OKE，它是一个丰富的内容，它使用了 OCI DevOps（一种托管的 CI/CD 服务）和 Autonomous Database（一种运行完全自动化的自治数据库）。"
order: "030"
tags:
---
在本次研讨会中，您将体验使用 OCI DevOps 设置 CI/CD 管道并在 Oracle Container Engine for Kubernetes (OKE) 上以 Oracle 自治事务处理作为数据源部署 Java 应用程序的流程。我可以。

本次研讨会包括以下服务：

- [Oracle Container Engine for Kubernetes](https://www.oracle.com/jp/cloud/compute/container-engine-kubernetes.html)（简称：OKE）：
：提供托管 Kuberentes 集群的云服务。
-【Oracle 自治事务处理】（https://www.oracle.com/jp/database/atp-cloud.html）（简称：ATP）：
：具有完全自动化操作的自治数据库服务。
-【甲骨文云基础设施DevOps】（https://www.oracle.com/devops/devops-service/）（简称：OCI DevOps）：
：Oracle Cloud 提供的托管 CI/CD 服务。
- [Oracle Cloud Infrastructure Registry](https://www.oracle.com/jp/cloud/compute/container-registry.html)（缩写：OCIR）：
：提供完全托管的符合 Docker v2 标准的容器注册表的服务。
- [Oracle 云基础设施工件注册表](https://docs.oracle.com/en-us/iaas/artifacts/using/overview.htm)：
：可以存储完全托管的非容器映像工件的存储库服务。

先决条件
--------

在开始工作坊之前，请准备以下内容：

- [必须有Oracle云账号](https://cloud.oracle.com/ja_JP/tryit)

- 完成[OKE动手准备](/ocitutorials/cloud-native/oke-for-commons/)

Oracle云基础设施的基本操作请参考【教程：访问OCI控制台并了解基础】(/ocitutorials/beginners/getting-started/)。

检查目标
------

首先，让我们通过检查当过程执行到最后将创建什么样的环境来大致了解目标。
在该过程结束时，您的环境将配置如下所示。

![0-000.jpg](0-000.jpg)

组件|描述
-|-
OKE | 运行应用程序容器的集群本身。供应 OKE 会在 Oracle Cloud 中的各种 IaaS 上自动对其进行配置。
OCI DevOps| 将应用程序 (CI/CD) 部署到 OKE 集群的服务。
自治事务处理|这次要部署的示例应用程序使用的数据库。
OCIR/工件注册表|存储构建工件（例如容器映像和清单）的存储库。

在这个整体图景中，OKE 已经通过 [OKE 动手准备](/ocitutorals/cloud-native/oke-for-commons/) 构建而成。

0. 提前准备
------

在这里，准备将在后续步骤中使用的令牌和资源。
有六个项目需要准备。

项目|描述
-|-
动手材料 | 包含本动手实践中使用的示例应用程序和脚本的项目。将其拉到 Cloud Shell 上。
用户名|OCI 资源操作所需的用户名。这一次，我们将使用它来访问 OCI DevOps 的 Git Repository。
身份验证令牌 | OCI 资源操作所需的令牌。这一次，我们将使用它来访问 OCI DevOps 的 Git Repository。
对象存储命名空间 | 访问 OCIR 和访问用于 OCI DevOps 的 Git 存储库所需的信息。
分区 OCID|配置 ATP 时使用此信息。
OCIR 存储库|这是 OCIR 上的存储库，用于存储此示例应用程序的容器映像。这一次，我们将创建一个公共存储库作为准备。

对于OCIR存储库，在[确认目标]（#确认目标）所示的图中，创建红色虚线框（！[2-032.jpg]（2-032.jpg））我会继续。

![0-013.jpg](0-013.jpg)

### 0-1. 动手材料的获取
首先，从 GitHub 获取本次实践中使用的材料。

[启动 Cloud Shell](/ocitutorials/cloud-native/oke-for-commons/#2cli%E5%AE%9F%E8%A1%8C%E7%92%B0%E5%A2%83cloud-shell%E3 % 81%AE%E6%BA%96%E5%82%99) 并进行 git 克隆。

```sh
git clone https://github.com/oracle-japan/oke-atp-helidon-handson.git
```

材料的获取现已完成。

回到你的主目录。

```sh
cd ~
```

### 0-2. 用户名确认
在此处检查您的用户名。

点击OCI控制台画面右上方的人形图标，在编辑器等中记录展开的配置文件中显示的用户名。

![0-014.jpg](0-014.jpg)

用户名确认现已完成。

### 0-3. 创建身份验证令牌

在这里，您可以获得 OCI DevOps 存储库操作所需的身份验证令牌。

单击 OCI 控制台屏幕右上角的人形图标，然后从展开的配置文件中单击用户名。

![0-001.jpg](0-001.jpg)

向下滚动到资源、身份验证令牌，然后单击生成令牌按钮。

![0-002.jpg](0-002.jpg)

点击！[0-003.jpg](0-003.jpg)。

输入以下项目。

键|值|
-|-
说明|奥克汉森

![0-004.jpg](0-004.jpg)

点击！[0-005.jpg](0-005.jpg)。

![0-006.jpg](0-006.jpg)

复制显示的令牌并将其记录在编辑器等中。

**对于学生**
生成的令牌只会出现一次。
单击“复制”，令牌将被复制并保存在何处。完成后单击关闭按钮。 （注意：如果忘记了，请删除创建的令牌并重新生成。）
{: .notice--警告}

### 0-4. 确认租户名称和对象存储命名空间

在这里，您将找到访问 OCI 代码存储库并将容器映像推送到 OCIR 所需的租户名称和对象存储命名空间。

单击 OCI 控制台屏幕右上角的人员图标，然后单击您的租户名称。

![0-007.jpg](0-007.jpg)

复制两个红框中的值，保存在编辑器中。
上面的红框是租户名称（`name`），下面的红框是对象存储命名空间（`object storage namespace`）。

![0-008.jpg](0-008.jpg)

已完成租户名称和对象存储命名空间的确认。

### 0-5. 车厢OCID确认

在这里，确认供应 ATP 时要使用的隔离专区 OCID。

在 CI 控制台的汉堡菜单中，单击 Identity and Security 菜单下的 Compartments。

![0-015.jpg](0-015.jpg)

您的隔间已显示，因此请单击它。

![0-016.jpg](0-016.jpg)

**关于用于动手操作的隔间**
要在试用环境中动手操作，请使用根隔间。 （隔间的末端以 `(root)` 给出）
如果您在其他环境中有分配给您的隔间，请检查该隔间。
{: .notice--warning}

复制“车厢信息”中红框部分的值，保存到编辑器等中。

![0-017.jpg](0-017.jpg)

隔间 OCID 确认现已完成。

### 0-6. 创建 OCIR 存储库

在这里，在 OCIR 中创建一个存储库来推送构建的容器镜像。

在 OCI 控制台的汉堡菜单中，单击 Developer Services 下的 Container Registry。

![0-009.jpg](0-009.jpg)

{% 捕获通知 %}**关于用于动手操作的隔间**
要在试用环境中动手操作，请使用根隔间。
默认情况下，在 OCIR 控制台屏幕上选择了根隔间，但如果您分配了一个隔间，请使用该隔间。
可以从 OCIR 控制台屏幕的左侧选择隔间。
![0-018.jpg](0-018.jpg)
{% endcapture %}
<div class="notice--warning">
  {{ notice | markdownify }}
</div>

![0-010.jpg](0-010.jpg)点击。

输入以下项目。

键|值|
-|-
存储库名称|handson
选择访问|`公共`

**关于存储库名称**
OCIR 存储库名称在您的租约中是唯一的。
多人共享同一环境，如集体动手，请在名称前加上“handson01”、“handson-tn”等姓名的首字母，避免名称重复。
{: .notice--警告}

![0-011.jpg](0-011.jpg)

点击！[0-012.jpg](0-012.jpg)。

准备工作现已完成。

1. 政策制定
--------

在这里，我们将创建一个使用 OCI DevOps 的策略。

**政策**
Oracle Cloud Infrastructure 具有策略的概念。
策略允许您控制用户和动态组可以对哪些资源和服务执行哪些操作。
有关政策详情，请查看页面 [此处](https://docs.oracle.com/ja-jp/iaas/Content/Identity/Concepts/policygetstarted.htm#Getting_Started_with_Policies)。
{: .notice--info}

这一次，我使用 shell 脚本简化了策略创建（包括动态组），但设置了以下动态组和策略。

动态组|规则|说明|
-|-
OCI_DevOps_Dynamic_Group|instance.compartment.id = 'compartment OCID',resource.compartment.id = 'compartment OCID'|包含隔离专区中所有资源和实例的动态组

**关于隔间**
Oracle 云基础设施具有隔间的概念。
分区是对云资源（实例、虚拟云网络、块卷等）进行分类和组织的逻辑分区，可以在此基础上进行访问控制。它还充当 OCI 控制台上显示的资源的过滤器。
有关隔间的详细信息，请查看页面 [此处](https://docs.oracle.com/ja-jp/iaas/Content/Identity/Tasks/managingcompartments.htm)。
{: .notice--info}

**关于动态组**
Oracle Cloud Infrastrcture 具有动态组的概念。
通过使用它，可以在 OCI 上而不是用户上操作资源和实例。
有关动态组的详细信息，请参阅页面 [此处](https://docs.oracle.com/ja-jp/iaas/Content/Identity/Tasks/managingdynamicgroups.htm)。
{: .notice--info}

**关于本次实践中的动态组**
这一次，为了方便上手操作，我们设置了包括所有资源和实例在隔离专区中作为一个动态组。
本质上，您将通过指定每个服务的类型来创建一个动态组。
{: .notice--warning}

政策|说明
-|-
允许动态组 OCI_DevOps_Dynamic_Group 管理隔离专区 id 'compartment OCID'|中的 devops-family 允许 OCI DevOps 使用其自己的功能的策略
允许动态组 OCI_DevOps_Dynamic_Group 管理隔离专区 id 'compartment OCID'|中的所有工件|允许 OCI DevOps 管理 OCIR 和工件注册表的策略
允许动态组 OCI_DevOps_Dynamic_Group 在隔离专区 id 'compartment OCID'|中使用 ons-topics|允许 OCI DevOps 使用 OCI 通知服务的策略（将在后面的步骤中创建）
允许动态组 OCI_DevOps_Dynamic_Group 管理隔离专区 id 'compartment OCID'|OCI DevOps 管理 OKE 中的集群系列
允许动态组 OCI_DevOps_Dynamic_Group 管理隔离专区 id 'compartment OCID' 中的自治数据库|允许 Kubernetes 的 OCI 服务操作员 (OSOK) 管理自治事务处理的策略

**关于 DevOps 政策**
在 DevOps 中，除了此处设置的策略之外，还可以设置其他几个策略，具体取决于要使用的功能和部署目标。
也可以通过设置策略来限制操作范围。
详情请查看页面[这里](https://docs.oracle.com/ja-jp/iaas/Content/devops/using/devops_iampolicies.htm)。
{: .notice--info}

现在运行用于设置上述动态组和策略的 shell 脚本。

**政策**
此处使用的脚本是为试用环境创建的，并假定您具有租户管理员权限。
如果您在内部环境中学习本教程，请**手动**为动态组创建和分配给您的隔离专区设置策略。
请注意，创建动态组需要权限，因此如果您看到“授权失败”消息，请联系您的租户管理员。
{: .notice--警告}

shell脚本在【0-1.获取动手材料】（#0-1-获取动手材料）中获得的材料中。

```sh
cd oke-atp-helidon-handson
```

```sh
cd prepare
```

```sh
chmod +x prepare.sh
```

```sh
./prepare.sh
```

如果输出如下，则没有问题。

```sh
ocid1.tenancy.oc1..aaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx55asqdzge45nq
{
  "data": {
    "compartment-id": "ocid1.tenancy.oc1..aaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx55asqdzge45nq",
    "defined-tags": {
      "Oracle-Tags": {
        "CreatedBy": "oracleidentitycloudservice/xxxxxx.xxxxxx@gmail.com",
        "CreatedOn": "2022-01-31T01:35:54.465Z"
      }
    },
    "description": "OCI_DevOps_Dynamic_Group",
    "freeform-tags": {},
    "id": "ocid1.dynamicgroup.oc1..aaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx55asqdzge45nq",
    "inactive-status": null,
    "lifecycle-state": "ACTIVE",
    "matching-rule": "any {resource.compartment.id = 'ocid1.tenancy.oc1..aaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx55asqdzge45nq',instance.compartment.id = 'ocid1.tenancy.oc1..aaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx55asqdzge45nq'}",
    "name": "OCI_DevOps_Dynamic_Group",
    "time-created": "2022-01-31T01:35:54.528000+00:00"
  },
  "etag": "66c9058cf8f1145ce9047130c4a266d816e9dfbf"
}
{
  "data": {
    "compartment-id": "ocid1.tenancy.oc1..aaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx55asqdzge45nq",
    "defined-tags": {
      "Oracle-Tags": {
        "CreatedBy": "oracleidentitycloudservice/xxxx.xxxx@gmail.com",
        "CreatedOn": "2022-01-31T01:35:57.108Z"
      }
    },
    "description": "OCI_DevOps_Policy",
    "freeform-tags": {},
    "id": "ocid1.policy.oc1..aaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx55asqdzge45nq",
    "inactive-status": null,
    "lifecycle-state": "ACTIVE",
    "name": "OCI_DevOps_Policy",
    "statements": [
      "Allow dynamic-group OCI_DevOps_Dynamic_Group to manage devops-family in compartment id ocid1.tenancy.oc1..aaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx55asqdzge45nq",
      "Allow dynamic-group OCI_DevOps_Dynamic_Group to manage all-artifacts in compartment id ocid1.tenancy.oc1..aaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx55asqdzge45nq",
      "Allow dynamic-group OCI_DevOps_Dynamic_Group to use ons-topics in compartment id ocid1.tenancy.oc1..aaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx55asqdzge45nq",
      "Allow dynamic-group OCI_DevOps_Dynamic_Group to manage autonomous-database in compartment id ocid1.tenancy.oc1..aaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx55asqdzge45nq",
      "Allow dynamic-group OCI_DevOps_Dynamic_Group to manage cluster-family in compartment id ocid1.tenancy.oc1..aaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx55asqdzge45nq"
    ],
    "time-created": "2022-01-31T01:35:57.220000+00:00",
    "version-date": null
  },
  "etag": "e0fb30d026d2a4f091058c2f686d51996ea59f8c"
}
```

策略创建完成。

回到你的主目录。

```sh
cd ~
```

2. 设置 OCI DevOps
--------

在这里，我们将创建一个 OCI DevOps 实例并准备示例应用程序。

在[确认目标](#Confirm the goal)的图中，我们将创建红色虚线框(![2-032.jpg](2-032.jpg))。

![2-031.jpg](2-031.jpg)

### 2-1. 创建 OCI 通知

首先，在创建 OCI DevOps 实例之前创建 OCI 通知。
创建 OCI DevOps 时，必须创建 OCI 通知。

**关于 OCI 通知**
OCI Notifications 是一种用于安全、可靠、低延迟和持久消息传递的服务。
在本次动手中，我们将发送到电子邮件地址，但您也可以将通知发送到 Slack/SMS/PagerDuty 等。还
详情请查看页面[这里](https://docs.oracle.com/ja-jp/iaas/Content/Notification/Concepts/notificationoverview.htm)。
{: .notice--info}

在 OCI 控制台的汉堡菜单中，单击 Developer Services 下的 Notifications。

![2-001.jpg](2-001.jpg)

单击![2-002.jpg](2-002.jpg)。

输入以下项目并单击![2-004.jpg](2-004.jpg)。

键|值|
-|-
姓名|oke-handson

**关于 OCI 通知名称**
OCI 通知名称在您的租约中是唯一的。
多人共享同一个环境，比如集体动手，请在名字前加上‘oke-handson01’、‘oke-handson-tn’等名字的首字母，避免名字重复。
{: .notice--警告}

![2-003.jpg](2-003.jpg)

单击您创建的 OCI 通知链接（在本例中为“oke-handson”）。

![2-005.jpg](2-005.jpg)

单击 ![2-006.jpg](2-006.jpg)。

输入以下项目并单击![2-004.jpg](2-004.jpg)。

键|值|
-|-
电子邮件地址|您的电子邮件地址

![2-007.jpg](2-007.jpg)

创建状态为“待定”的订阅。

![2-008.jpg](2-008.jpg)

以下电子邮件已发送到您之前输入的电子邮件地址，请检查。

![2-009.jpg](2-009.jpg)

单击电子邮件中的 ![2-010.jpg](2-010.jpg)。

将出现如下图所示的屏幕。

![2-011.jpg](2-011.jpg)

如果您返回 OCI 通知屏幕，您可以看到订阅状态为“活动”。
（如果不是“活动”，请刷新页面。）

![2-012.jpg](2-012.jpg)

这样就完成了 OCI 通知的创建。

### 2-2. 创建 OCI DevOps 实例

在这里，我们将创建一个 OCI DevOps 实例并为我们的示例应用程序创建一个存储库。

在 OCI 控制台的汉堡菜单中，单击 Developer Services 下的 DevOps 类别下的 Projects。

![2-013.jpg](2-013.jpg)

单击![2-014.jpg](2-014.jpg)。

输入以下项目。

键|值|
-|-
项目名称|oke-handson

**关于 OCI DevOps 实例名称**
OCI DevOps 实例名称在您的租户中是唯一的。
多人共享同一个环境，比如集体动手，请在名字前加上‘oke-handson01’、‘oke-handson-tn’等名字的首字母，避免名字重复。
{: .notice--警告}

![2-016.jpg](2-016.jpg)

单击![2-015.jpg](2-015.jpg)。

选择您之前创建的名为“oke-handson”的主题。

![2-017.jpg](2-017.jpg)

![2-019.jpg](2-019.jpg)

单击![2-018.jpg](2-018.jpg)。

配置完成后，您将看到如下所示的框，单击！[2-020.jpg](2-020.jpg)。

![2-033.jpg](2-033.jpg)

点击下方。

![2-021.jpg](2-021.jpg)

将出现如下图所示的屏幕。

![2-034.jpg](2-034.jpg)

按原样点击！[2-022.jpg](2-022.jpg)。

如果状态如下，则没有问题。

![2-023.jpg](2-023.jpg)

实例创建现已完成。

### 2-3. 准备示例应用程序

接下来，创建一个代码存储库。

从左侧菜单中选择代码存储库。

![2-024.jpg](2-024.jpg)

单击![2-025.jpg](2-025.jpg)。

输入以下项目。

键|值|
-|-
存储库名称|oke-handson

单击![2-027.jpg](2-027.jpg)。

![2-026.jpg](2-026.jpg)

创建存储库后，单击![2-028.jpg](2-028.jpg)。

在显示的对话框中单击下面的红框（`使用 HTTPS 克隆`）并复制 URL。
在编辑器等中记录复制的 URL。

![2-029.jpg](2-029.jpg)

单击![2-030.jpg](2-030.jpg)。

[启动 Cloud Shell](/ocitutorials/cloud-native/oke-for-commons/#2cli%E5%AE%9F%E8%A1%8C%E7%92%B0%E5%A2%83cloud-shell%E3 % 81%AE%E6%BA%96%E5%82%99)。

运行以下命令以在克隆之前保存 Git 凭据（用户名/密码）信息。

```sh
git config --global credential.helper store
```

Git 克隆您之前复制的 URL。 

```sh
git clone <コピーしたURL>
```
克隆时将要求您输入用户名和密码。
每个如下。

键|值|描述
-|-
用户名|<租户名>/<用户名>|`租户名`为[0-4.)，`用户名`为[0-2.用户名确认](#0-2 - 用户名确认）
密码|在[0-3.创建身份验证令牌]中创建的那个（#0-3-创建身份验证令牌）

如果克隆成功，将创建一个名为“oke-handson”的目录。

将【动手材料】（#0-1-获取动手材料）复制到“oke-handson”。 

```sh
cp -pr oke-atp-helidon-handson/* oke-handson/
```

从代码存储库转到克隆的目录。

```sh
cd oke-handson/
```

根据您的环境仅在一处修改用于部署到 OKE 的 Manifest。

```sh
vim k8s/deploy/oke-atp-helidon.yaml
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: oke-atp-helidon
  namespace: default
spec:
  type: LoadBalancer
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app: oke-atp-helidon
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: oke-atp-helidon
spec:
  selector:
    matchLabels:
      app: oke-atp-helidon
  replicas: 2
  template:
    metadata:
      labels:
        app: oke-atp-helidon
        version: v1
    spec:
      # The credential files in the secret are base64 encoded twice and hence they need to be decoded for the programs to use them.
      # This decode-creds initContainer takes care of decoding the files and writing them to a shared volume from which db-app container
      # can read them and use it for connecting to ATP.
      containers:
      - name: oke-atp-helidon
        image: iad.ocir.io/orasejapan/handson:${BUILDRUN_HASH}
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
        env:
        - name: javax.sql.DataSource.test.dataSource.user
          valueFrom:
            secretKeyRef:
              name: customized-db-cred
              key: user_name
        - name: javax.sql.DataSource.test.dataSource.password
          valueFrom:
            secretKeyRef:
              name: customized-db-cred
              key: password
        volumeMounts:
        - name: handson
          mountPath: /db-demo/creds              
      volumes:
      - name: handson
        secret:
          secretName: okeatp
```

将第 35 行的以下部分更改为

```yaml
image: iad.ocir.io/orasejapan/handson:${BUILDRUN_HASH}
```
**除试用环境外，参加集体实践会议的每个人**
我想除了试用环境之外，参与集体动手的大家都在[0-6.OCIR仓库创建]（#0-6-ocir仓库创建）中把仓库名从“handson”改了。。 在这种情况下，将 `handson:${BUILDRUN_HASH}` 中的 `handson` 更改为创建的存储库名称。
{: .notice--warning}

```yaml
image: <您正在使用的区域的区域代码>.ocir.io/<对象存储命名空间>/handson:${BUILDRUN_HASH}
```

`<您使用的地区的地区代码>`会根据您使用的地区而变化，因此请参考下表进行设置。

地区|地区代码
-|-
ap-tokyo-1|nrt
ap-osaka-1|kix
ap-melbourne-1|mel
us-ashburn-1|iad
us-phoenix-1|phx
ap-mumbai-1|bom
ap-seoul-1|icn
ap-sydney-1|syd
ca-toronto-1|yyz
ca-montreal-1|yul
eu-frankfurt-1|fra
eu-zurich-1|zrh
sa-saopaulo-1|gru
sa-vinhedo-1| vcp
uk-london-1|lhr
sa-santiago-1|scl
ap-hyderabad-1|hyd
eu-amsterdam-1|ams
me-jeddah-1|jed
ap-chuncheon-1|yny
me-dubai-1|dxb
uk-cardiff-1|cwl
us-sanjose-1|sjc

对于<Object Storage Namespace>，使用[0-4-Confirm Object Storage Namespace]（#0-4-Confirm Object Storage Namespace）中确认的值。 

完成上述操作后，提交/推送您的内容。

```sh
git add .
```

进行以下设置，以便“git push”时不会出现警告。

```sh
git config --global push.default simple
```

提交。

```sh
git commit -m "commit"
```

{% capture notice %}**提交时显示的消息**
提交时您可能会看到以下消息：

```
*** Please tell me who you are.

Run

  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"

to set your account's default identity.
Omit --global to set the identity only in this repository.
```

在这种情况下，请在执行以下命令后再次提交。

```
git config --global user.email <你的邮箱>  
git config --global user.name <名称(任意)>
```

{% endcapture %}
<div class="notice--warning">
  {{ notice | markdownify }}
</div>

推送到服务器。

```sh
git push
```

示例应用程序的准备工作现已完成。

回到你的主目录。  

```sh
cd ~
```

3. ATP 供应
--------

此步骤从 OCI 控制台提供 ATP 并准备好从 OKE 连接。

在[确认目标](#Confirm the goal)的图中，我们将创建红色虚线框(![2-032.jpg](2-032.jpg))。

![3-001.jpg](3-001.jpg)

在本次实践中，我们将使用 OCI Service Operator for Kubernetes (OSOK) 来配置 ATP。
OSOK 是一个开放平台，允许您使用 Kubernetes API 和 [Kubernetes Operator 模式]（https://kubernetes.io/en/docs/concepts/extend-kubernetes/operator/）创建、管理和连接 Oracle 云基础设施资源). 它是一个源 Kubernetes 插件。
当前支持以下服务。 （我们计划在未来增加更多服务）

- Autonomous Database
- MySQL Database
- Streaming

**关于 Kubernetes 的 OCI 服务运营商 (OSOK)**
对于 Kubernetes (OSOK) 的 OCI 服务运营商 [此处](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengaddingosok.htm#contengaddingosok) 和 [GitHub](https:/ /github.com/oracle/oci-service-operator）。
{: .notice--信息}

要使用 OSOK，需要 Operator SDK 和 Operator Lifecycle Manager (OLM)，因此请先安装它们。

**关于Operator SDK和Operator Lifecycle Manager (OLM)**
Operator SDK 将是一个用于高效开发 Kubernetes Operator 的 SDK，而 Operator Lifecycle Manager (OLM) 将是一种管理 Operator 生命周期的机制。
查看 Operator SDK [此处](https://sdk.operatorframework.io/) 和 Operator Lifecycle Manager (OLM) [此处](https://olm.operatorframework.io/)。
{: .notice--信息}

**关于 [3-5.[选项] 更新 microprofile-config.properties]（#3-5-更新选项 microprofile-configproperties）**
对于那些在 [3-2. ATP 供应] (#3-2-atp 供应) 中更改 ATP 数据库名称 (`dbName`) 的人来说，这是一个可选过程。 （主要针对集体动手等多人共享同一环境的大家）
否则请跳过。
{: .notice--警告}

**关于 [3-6.[选项] 使用 Oracle SQL Developer 的示例数据注册]（#3-6 - 使用选项 oracle-sql-developer 的示例数据注册）**
这是[3-3.注册示例数据]（#3-3-注册示例数据）中Oracle SQL Developer 的可选过程。
在[3-3.注册示例数据]（#3-3-注册示例数据）中，如果使用SQL Developer Web（浏览器版）注册示例数据不起作用，请按照以下步骤创建示例。请注册您的数据。
否则，跳过此步骤。
{: .notice--警告}

### 3-1. 安装Operator SDK和Operator Lifecycle Manager (OLM)

首先，安装 Operator SDK。

[启动Cloud Shell](/ocitutorials/cloud-native/oke-for-commons/#3准备cli执行环境cloud-shell)。

```sh
export ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n $(uname -m) ;; esac)
```

```sh
export OS=$(uname | awk '{print tolower($0)}')
```

```sh
export OPERATOR_SDK_DL_URL=https://github.com/operator-framework/operator-sdk/releases/download/v1.12.0
```

```sh
curl -LO ${OPERATOR_SDK_DL_URL}/operator-sdk_${OS}_${ARCH}
```

```sh
ls -l
```
现在确保您已经下载了 `operator-sdk_linux_amd64` 二进制文件。
从这里开始，我们将执行验证二进制文件的步骤。

```sh
gpg --keyserver keyserver.ubuntu.com --recv-keys 052996E2A20B5C7E
```

它会输出如下内容：

```sh
gpg: requesting key A20B5C7E from hkp server keyserver.ubuntu.com
gpg: /home/takuya_nii/.gnupg/trustdb.gpg: trustdb created
gpg: key A20B5C7E: public key "Operator SDK (release) <cncf-operator-sdk@cncf.io>" imported
gpg: Total number processed: 1
gpg:               imported: 1  (RSA: 1)
```

获取验证所需的文件。　

```sh
curl -LO ${OPERATOR_SDK_DL_URL}/checksums.txt
```

```sh
curl -LO ${OPERATOR_SDK_DL_URL}/checksums.txt.asc
```

```sh
ls -l
```

在这里，确认文件 `checksums.txt.asc` 和 `checksums.txt` 已经下载。

```sh
gpg -u "Operator SDK (release) <cncf-operator-sdk@cncf.io>" --verify checksums.txt.asc
```

输出将类似于以下内容：

```sh
gpg: Signature made Thu 09 Sep 2021 04:59:50 PM UTC using RSA key ID BF9886DB
gpg: Good signature from "Operator SDK (release) <cncf-operator-sdk@cncf.io>"
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: xxxx xxxx xxxx xxxx xxxx  xxxx xxxx xxxx xxxx xxxx
     Subkey fingerprint: xxxx xxxx xxxx xxxx xxxx  xxxx xxxx xxxx xxxx xxxx
```

检查验证结果。

```sh
grep operator-sdk_${OS}_${ARCH} checksums.txt | sha256sum -c -
```

如果输出如下所示，则验证正常：

```sh
operator-sdk_linux_amd64: OK
```

最后赋予执行权限。

```sh
chmod +x operator-sdk_${OS}_${ARCH} && mv operator-sdk_${OS}_${ARCH} operator-sdk
```

Operator SDK 安装现已完成。

接下来，安装 Operator Lifecycle Manager (OLM)。

执行以下命令。

```sh
./operator-sdk olm install
```

如果输出如下就没有问题。

```sh
~~~~~
NAME                                            NAMESPACE    KIND                        STATUS
catalogsources.operators.coreos.com                          CustomResourceDefinition    Installed
clusterserviceversions.operators.coreos.com                  CustomResourceDefinition    Installed
installplans.operators.coreos.com                            CustomResourceDefinition    Installed
operatorconditions.operators.coreos.com                      CustomResourceDefinition    Installed
operatorgroups.operators.coreos.com                          CustomResourceDefinition    Installed
operators.operators.coreos.com                               CustomResourceDefinition    Installed
subscriptions.operators.coreos.com                           CustomResourceDefinition    Installed
olm                                                          Namespace                   Installed
operators                                                    Namespace                   Installed
olm-operator-serviceaccount                     olm          ServiceAccount              Installed
system:controller:operator-lifecycle-manager                 ClusterRole                 Installed
olm-operator-binding-olm                                     ClusterRoleBinding          Installed
olm-operator                                    olm          Deployment                  Installed
catalog-operator                                olm          Deployment                  Installed
aggregate-olm-edit                                           ClusterRole                 Installed
aggregate-olm-view                                           ClusterRole                 Installed
global-operators                                operators    OperatorGroup               Installed
olm-operators                                   olm          OperatorGroup               Installed
packageserver                                   olm          ClusterServiceVersion       Installed
operatorhubio-catalog                           olm          CatalogSource               Installed
```

Operator Lifecycle Manager (OLM) 安装现已完成。

### 3-2. ATP 供应

在这里，我们将提供 ATP。

首先，运行以下命令在 OKE 上安装 OSOK operator（用于从 OKE 操作 ATP 的 Kubernetes operator）。

```sh
./operator-sdk run bundle iad.ocir.io/oracle/oci-service-operator-bundle:1.0.0
```

如果输出如下就没有问题。

```sh
INFO[0016] Successfully created registry pod: iad-ocir-io-oracle-oci-service-operator-bundle-1-0-0 
INFO[0017] Created CatalogSource: oci-service-operator-catalog 
INFO[0018] OperatorGroup "operator-sdk-og" created      
INFO[0019] Created Subscription: oci-service-operator-v1-0-0-sub 
INFO[0023] Approved InstallPlan install-bgmnh for the Subscription: oci-service-operator-v1-0-0-sub 
INFO[0023] Waiting for ClusterServiceVersion "default/oci-service-operator.v1.0.0" to reach 'Succeeded' phase 
INFO[0024]   Waiting for ClusterServiceVersion "default/oci-service-operator.v1.0.0" to appear 
INFO[0045]   Found ClusterServiceVersion "default/oci-service-operator.v1.0.0" phase: InstallReady 
INFO[0046]   Found ClusterServiceVersion "default/oci-service-operator.v1.0.0" phase: Installing 
INFO[0070]   Found ClusterServiceVersion "default/oci-service-operator.v1.0.0" phase: Succeeded 
INFO[0070] OLM has successfully installed "oci-service-operator.v1.0.0" 
```

接下来，创建清单以供应 ATP。

首先，创建 ATP 管理员密码作为 Secret 资源。
这次创建密码为“okehandson__Oracle1234”。

**关于密钥**
请参阅 [此处](https://kubernetes.io/docs/concepts/configuration/secret/) 获取 Secret 资源。
{: .notice--info}

```sh
kubectl create secret generic admin-passwd --from-literal=password=okehandson__Oracle1234
```

接下来，为 Wallet 文件创建密码作为 Secret 资源。
这次创建一个与管理员密码相同的密码“okehandson__Oracle1234”。

```sh
kubectl create secret generic wallet-passwd --from-literal=walletPassword=okehandson__Oracle1234
```

{% capture notice %}**如果您错误地创建了秘密**
如果您错误地创建了它，请运行以下命令将其删除。
```
kubectl delete secret <secret名>
```
{% endcapture %}
<div class="notice--warning">
  {{ notice | markdownify }}
</div>

这次，我准备了以下Manifest。
这可以根据您的用例灵活更改。

**关于可配置参数**
请参阅[此处](https://github.com/oracle/oci-service-operator/blob/main/docs/adb.md#autonomous-databases-service)，了解可在 ATP 供应期间设置的参数。
{: .notice--info}

打开Manifest文件，将`<your own compartment OCID>`替换为[0-5. Confirmation of compartment OCID]中确认的compartment OCID (#0-5-Confirmation of compartment ocid)。

**关于舱单隔间**
这是给那些不在试用环境中的人注意的，但是清单要替换的隔间是隔间（``~~ in compartment id ``compartment OCID'' of ``compartment OCID''）。
{: .notice--warning}

{% capture notice %}**关于Manifest文件中的`dbName`**
清单文件中的“dbName”在您的租赁中是唯一的。
对于多人共享同一个环境的，比如集体动手，请给名字首字母，比如`okeatp01`和`okeatptn`，避免重名。
`dbName` 只能是字母数字（必须以字母开头，最多 14 个字符）。不要包含符号等。
{% endcapture %}
<div class="notice--warning">
  {{ notice | markdownify }}
</div>

```sh
vim oke-handson/k8s/atp/atp.yaml 
```

```yaml
apiVersion: oci.oracle.com/v1beta1
kind: AutonomousDatabases
metadata:
  name: oke-atp-handson-db
spec:
  compartmentId: <ご自身のコンパートメントOCID>
  displayName: oke-atp-handson-db
  dbName: okeatp
  dbWorkload: OLTP
  isDedicated: false
  dbVersion: 19c
  dataStorageSizeInTBs: 1
  cpuCoreCount: 1
  adminPassword:
    secret:
      secretName: admin-passwd
  isAutoScalingEnabled: false
  isFreeTier: true
  licenseModel: LICENSE_INCLUDED
  wallet:
    walletName: okeatp
    walletPassword:
      secret:
        secretName: wallet-passwd
```

将清单应用于 OKE。

```sh
kubectl apply -f oke-handson/k8s/atp/atp.yaml 
```

您可以通过执行以下命令来检查状态。
等待一段时间，直到 `status` 变为 `Active`。
`-w` (`--watch`) 是一个监视状态的选项。

```sh
kubectl get autonomousdatabases -w
```

如果输出如下，则配置完成。

```sh
NAME              DBWORKLOAD   STATUS   AGE
oke-atp-handson-db   OLTP               12s
oke-atp-handson-db   OLTP      Active   71s
```

### 3-3.注册示例数据

在这里，我们将使用 SQL Developer Web 在 ATP 中注册示例数据。

单击 Oracle 数据库菜单上自治数据库类别下的自治事务处理。

![3-011.jpg](3-011.jpg)

点击[3-012.jpg](3-012.jpg) 在[3-2.ATP provisioning](#3-2-atp provisioning)中配置。

单击数据库操作按钮。

![3-002.jpg](3-002.jpg)

输入以下项目并单击“登录”。

键|值|描述
-|-
用户名|ATP 数据库用户名。这次是“管理员”
密码|ATP 数据库密码。这次，“okehandson__Oracle1234”|[3-2. ATP provisioning] (#3-2-atp provisioning) 管理员密码由 `kuebctl create secret` 命令创建

![3-006.jpg](3-006.jpg)

单击 SQL。

![3-007.jpg](3-007.jpg)

登录后，在worksheet中输出存储库中`sql/create_schema.sql`中定义的DDL（从GitHub克隆的存储库，从代码存储库克隆的存储库，两者都可以）在worksheet中用以下命令输出，执行脚本（红框内的按钮）复制粘贴后。

```嘘
cat oke-handson/sql/create_schema.sql
```

![3-008.jpg](3-008.jpg)

执行后，重新加载（刷新）一次浏览器，从“Navigator”菜单中选择用上述DDL创建的“HANDSON”。

![3-009.jpg](3-009.jpg)

在 SQL Developer Web Worksheet 中输入 `select * from HANDSON.ITEMS;`，然后单击绿色箭头“Execute Statement”图标。

显示来自 ITEMS 表的结果。

![3-010.jpg](3-010.jpg)

这样就完成了样本数据的注册。

### 3-4. 创建应用程序使用的数据库用户/密码

在这里，创建示例应用程序要使用的数据库用户和密码。

在[3-2. ATP provisioning]（#3-2-atp provisioning）中，使用默认用户“Admin”创建了一个数据库。

在大多数情况下，当您的应用程序使用数据库时，您将创建一个不同于“Admin”的用户。
同样，这一次，让我们为应用程序创建一个数据库用户以使用 ATP。
在本实践中，我们将 ATP 用户和密码设置为作为环境变量读入应用程序。
（此设置在[8. [Option] Supplementary information about the application used this time used]（#8 Option Supplementary information about the application used this time used）中有解释，有兴趣的请查看。）

在这里，我们将创建一个 Secret 资源来创建 ATP 用户和密码作为环境变量。

这次，创建 ATP 用户为“handson”，密码为“Welcome12345”。
这个用户名和密码在我们之前运行的 DDL 中定义。

```sh
kubectl create secret generic customized-db-cred \
--from-literal=user_name=handson \
--from-literal=password=Welcome12345
```

您现在已经为您的应用程序创建了数据库用户名和密码。

### 3-5. [可选] 更新`microprofile-config.properties`

**关于这个程序**
此过程适用于那些在 [3-2. Provisioning ATP] (#3-2-Provisioning ATP) 中更改了 ATP 数据库名称 (`dbName`) 的人。
否则，跳过此步骤。
{: .notice--警告}

在 [3-2. ATP 供应] (#3-2-atp 供应) 中更改的 ATP 数据库名称 (`dbName`) 也必须在示例应用程序端得到支持。
以下是这样做的步骤。

示例应用程序在名为“microprofile-config.properties”的配置文件中定义 ATP 数据库名称。
我会在这里更新。

```sh
vim oke-handson/src/main/resources/META-INF/microprofile-config.properties
```

```yaml
#
# Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Microprofile server properties
server.port=8080
server.host=0.0.0.0

javax.sql.DataSource.test.dataSourceClassName=oracle.jdbc.pool.OracleDataSource
javax.sql.DataSource.test.dataSource.url=jdbc:oracle:thin:@okeatp_high?TNS_ADMIN=/db-demo/creds

server.static.classpath.location=/web
server.static.classpath.welcome=index.html
```

第11行

```yaml
javax.sql.DataSource.test.dataSource.url=jdbc:oracle:thin:@okeatp_high?TNS_ADMIN=/db-demo/creds
```

将“@okeatp_high?TNS_ADMIN=/db-demo/creds”部分更改为“@<您的数据库名称>_high?TNS_ADMIN=/db-demo/creds”。

例如，下图。

```yaml
javax.sql.DataSource.test.dataSource.url=jdbc:oracle:thin:@okeatp01_high?TNS_ADMIN=/db-demo/creds
```

提交到存储库。　

```sh
git add .
```

```sh
git commit -m "更改数据库名称"
```

```sh
git push
```

这样就完成了“microprofile-config.properties”的更新。

### 3-6. [选项] 使用Oracle SQL Developer 注册示例数据

**关于这个程序**
此过程适用于 [3-3. 注册示例数据]（#3-3- 注册示例数据）中的 Oracle SQL Developer。
在[3-3.注册示例数据]（#3-3-注册示例数据）中，如果使用SQL Developer Web（浏览器版）注册示例数据不起作用，请按照以下步骤创建示例。请注册您的数据。
否则，跳过此步骤。
{: .notice--warning}

首先，如果没有安装 SQL Developer，请下载它。
如果您已经安装了 Oracle SQL Developer，那么使用它是没有问题的。

首先，从 [此处](https://www.oracle.com/jp/tools/downloads/sqldev-downloads.html) 下载安装程序。
Windows用户请在下载后直接在解压后的文件下执行`sqldeveloper.exe`。 （可能需要单独安装JDK）
macOS 用户请执行解压输出的可执行文件。

接下来，从 Oracle SQL Developer 下载用于连接 ATP 的钱包文件。

单击 Oracle 数据库菜单上自治数据库类别下的自治事务处理。

![3-011.jpg](3-011.jpg)

点击[3-012.jpg](3-012.jpg) 在[3-2.ATP provisioning](#3-2-atp provisioning)中配置。

![3-013.jpg](3-013.jpg)

单击 ![3-014.jpg](3-014.jpg)。

![3-015.jpg](3-015.jpg)

单击 ![3-016.jpg](3-016.jpg)。

输入以下项目。

键|值|描述
-|-
密码 |okehandson__Oracle1234| 在 [3-2. ATP provisioning] (#3-2-atp provisioning) 中使用 `kuebctl create secret` 命令创建的钱包密码

![3-017.jpg](3-017.jpg)

点击![3-018.jpg](3-018.jpg)下载。

然后打开 Oracle SQL Developer。

![3-019.jpg](3-019.jpg)

点击左上角的![3-020.jpg](3-020.jpg)。

输入以下项目。

键|值|描述
-|-
名称|oke-handson
身份验证类型 | 默认
用户名 | 管理员
Password | okehandson__Oracle1234|[3-2.ATP provisioning]中使用`kuebctl create secret`命令创建的管理员密码（#3-2-atp provisioning）
连接类型 | 云钱包
配置文件 | 指定下载的钱包文件

![3-021.jpg](3-021.jpg)

单击 ![3-022.jpg](3-022.jpg)。

连接完成后，将显示以下屏幕。

![3-023.jpg](3-023.jpg)

在工作表中，使用以下命令输出存储库（从GitHub克隆的存储库，从代码存储库克隆的存储库，都可以）中`sql/create_schema.sql`中定义的DDL，复制并执行脚本（红色）框架按钮）粘贴后。

```嘘
cat oke-handson/sql/create_schema.sql
```

![3-024.jpg](3-024.jpg)

如果输出如下，则没有问题。

![3-025.jpg](3-025.jpg)

使用 Oracle SQL Developer 完成示例数据注册。

4. 构建 CI 流水线
----------

在这里，我们将使用 OCI DevOps 构建 CI 管道并创建触发器以在提交（推送）Git 存储库时启动 CI 管道。

在【确认目标】（#Confirm the goal）所示的图中，我们将创建红色虚线框（！[2-032.jpg]（2-032.jpg））。

![4-039.jpg](4-039.jpg)

### 4-1.检查build_spec.yaml

首先，检查定义构建定义的配置文件。

在 OCI DevOps 中，称为构建规范的构建定义以 yaml 格式文件编写。
该文件可以运行任意进程，例如构建和测试容器和应用程序。

在这次动手中，我提前准备了以下文件。

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
      BUILDRUN_HASH=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1`
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

outputArtifacts:
  - name: handson_image
    type: DOCKER_IMAGE
    location: handson_image:latest
```

ここでは、詳細な解説はしませんが、ポイントだけ抑えておきます。  

```yaml
env:  
  exportedVariables:
    - BUILDRUN_HASH  
```

这部分开头定义了可以在后续 CI 和 CD 流水线中使用的变量。
${BUILDRUN_HASH}这个变量会在后面的步骤中多次出现，所以如果你看到这个变量，请把它当做这里定义的变量。
我们将使用这个变量来标记我们的 Docker 镜像。

这个构建过程（yaml文件中的`step`）分为以下两点。

- 生成 BUILDRUN_HASH
- 构建一个 Docker 镜像

```yaml
outputArtifacts:
  - name: handson_image
    type: DOCKER_IMAGE
    location: handson_image:latest
```

最后一部分将构建的 Docker 镜像导出为 `handson_image` 以用于后续管道。

如您所见，这次我们将使用的构建定义相对简单。

**关于构建定义**
有关构建定义的更多信息，请参见[此处](https://docs.oracle.com/en-us/iaas/Content/devops/using/build_specs.htm)。
{: .notice--info}

### 4-2. 构建CI管道

从这里开始，我们将构建 CI 管道。

首先，定义将构建的容器镜像推送到 OCIR 时将使用的构建工件（在本例中为容器镜像）。

单击 Developer Services 下 DevOps 类别下的 Projects。

![4-001.jpg](4-001.jpg)

单击列表中的 ![4-002.jpg](4-002.jpg)。

单击 DevOps 项目资源下的工件。

![4-003.jpg](4-003.jpg)

单击 ![4-004.jpg](4-004.jpg)。

输入以下项目。

键|值|
-|-
名称|handson-image
类型|容器镜像存储库
输入容器注册表映像的完全限定路径|<您所在区域的区域代码>.ocir.io/<对象存储命名空间>/handson:${BUILDRUN_HASH}
替换此工件使用的参数 | 是的，替换占位符

**除试用环境外，每个人都参加了集体实践活动**
我认为除了试用环境外，参与集体动手的每个人都在[0-6.OCIR repository creation]（#0-6-ocir repository creation）中将存储库名称从“handson”更改为。。在这种情况下，将 `handson:${BUILDRUN_HASH}` 中的 `handson` 更改为创建的存储库名称。
{: .notice--warning}

`<Region code of the region you are using>`会根据您使用的地区而变化，请参考下表进行设置。

地区|地区代码
-|-
ap-tokyo-1|nrt
ap-osaka-1|kix
ap-melbourne-1|mel
us-ashburn-1|iad
us-phoenix-1|phx
ap-mumbai-1|bom
ap-seoul-1|icn
ap-sydney-1|syd
ca-toronto-1|yyz
ca-montreal-1|yul
eu-frankfurt-1|fra
eu-zurich-1|zrh
sa-saopaulo-1|gru
sa-vinhedo-1| vcp
uk-london-1|lhr
sa-santiago-1|scl
ap-hyderabad-1|hyd
eu-amsterdam-1|ams
me-jeddah-1|jed
ap-chuncheon-1|yny
me-dubai-1|dxb
uk-cardiff-1|cwl
us-sanjose-1|sjc

![4-005.jpg](4-005.jpg)

![4-006.jpg](4-006.jpg)点击。

结果，在稍后创建的构建管道中，容器注册表（这次是定义构建过程中导出的构建工件（在本例中为容器映像）的“<您正在使用的区域的区域代码>”。您可以推送到ocir.io/<对象存储命名空间>/handson:${BUILDRUN_HASH}`）。

然后单击 DevOps Project Resources 下的 Build Pipelines。

![4-007.jpg](4-007.jpg)

单击 ![4-008.jpg](4-008.jpg)。

输入以下项目。

键|值|
-|-
名称|handson_build

![4-009.jpg](4-009.jpg)

单击 ![4-010.jpg](4-010.jpg)。

单击列表中的 ![4-011.jpg](4-011.jpg)。

单击显示屏幕中央列表中的 ![4-012.jpg](4-012.jpg)，然后单击 ![4-013.jpg](4-013.jpg)。

选择托管构建并单击 ![4-015.jpg](4-015.jpg)。

![4-014.jpg](4-014.jpg)

输入以下项目。

键|值|描述
-|-
艺名|image_build|
Build specification file path|build_spec.yaml|放置在稍后设置的“主代码库”中的构建定义文件的路径。这次直接放在项目下

![4-016.jpg](4-016.jpg)

点击“主代码库”中的![4-022.jpg](4-022.jpg)。

输入以下项目。

键|值|描述
-|-
源/连接类型 | OCI 代码存储库 | 检查“oke-handson”
选择分支名称|主
创建源名称 | handson

![4-018.jpg](4-018.jpg)

单击 ![4-019.jpg](4-019.jpg)。

它将如下所示。

![4-020.jpg](4-020.jpg)

单击 ![4-021.jpg](4-021.jpg)。

接下来，点击前面创建的“image_build”底部的![4-012.jpg](4-012.jpg)，点击![4-013.jpg](4-013.jpg)增加。

选择 Deliver Artifact 并点击 ![4-015.jpg](4-015.jpg)。

![4-023jpg](4-023.jpg)

输入以下项目。

键|值
-|-
名称|图片推送

![4-024jpg](4-024.jpg)

单击 ![4-025jpg](4-025.jpg)。

选中“handson-image”并单击![4-027jpg](4-027.jpg)。

![4-026jpg](4-026.jpg)

在“Associating Artifacts with Build Results”中输入以下项目。

键|值|描述
-|-
构建配置/结果工件名称 |handson_image|在 `build_spec.yaml` 的 `outputArtifacts` 中定义的名称（参见 [4-1-Checking build_spec.yaml](#4-1-Checking build_specyaml)）。这次`handson_image`

![4-029jpg](4-029.jpg)

单击 ![4-028jpg](4-028.jpg)。

这样就完成了CI流水线的搭建。

### 4-3.创建触发器

在这里，我们设置了一个触发器，以便在 OCI 代码存储库中有更新时启动 CI 管道。

单击 Developer Services 下 DevOps 类别下的 Projects。

![4-001.jpg](4-001.jpg)

单击列表中的 ![4-002.jpg](4-002.jpg)。

单击 DevOps 项目资源下的触发器。

![4-030.jpg](4-030.jpg)

单击 ![4-031.jpg](4-031.jpg)。

输入以下项目。

键|值|描述
-|-
名称|handson-trigger
源连接 | OCI 代码库
单击选择代码存储库|oke-handson|![4-033.jpg](4-033.jpg) 并选中“oke-handson”

![4-032.jpg](4-032.jpg)

单击 ![4-034.jpg](4-034.jpg)。

输入以下项目。

键|值|描述
-|-
选择 Build Pipeline|handson_build|![4-033.jpg](4-033.jpg) 并选中“handson_build”
事件 | 勾选“推送”

![4-035.jpg](4-035.jpg)

单击 ![4-036.jpg](4-036.jpg)。

它将如下所示。

![4-037.jpg](4-037.jpg)

单击 ![4-038.jpg](4-038.jpg)。

触发器创建现已完成。

5.构建CD流水线
------

在这里，我们将构建 CD 管道。

在【确认目标】（#Confirm the goal）所示的图中，我们将创建红色虚线框（！[2-032.jpg]（2-032.jpg））。

![5-033.jpg](5-033.jpg)

### 5-1. 将 Manifest 文件注册到 Artifact Registry

在这里，我们将 Manifest 文件注册到 Artifact Registry，以便在 CD 管道中使用 Manifest。

单击 Developer Services 的 Containers and Artifacts 类别中的 Artifact Registry。

![5-001.jpg](5-001.jpg)

单击 ![5-002.jpg](5-002.jpg)。

输入以下项目并单击 ![5-004.jpg](5-004.jpg)。

键|值
-|-
名称|oke-handson

![5-003.jpg](5-003.jpg)

单击 ![5-005.jpg](5-005.jpg)。

输入以下项目。

键|值
-|-
工件路径|deploy.yaml
版本|v0.1
上传方式|Cloud Shell

![5-006.jpg](5-006.jpg)

![5-034.jpg] 点击(5-034.jpg)中的`copy`按钮复制命令。

从 ![5-007.jpg](5-007.jpg) 启动 Cloud Shell。

移动到在 [2-3- 准备示例应用程序] (#2-3-Preparing the sample application) 中克隆的目录。

```sh
cd oke-handson
```

将您之前复制的命令末尾的 `--content-body ./<file-name>` 替换为 `./k8s/deploy/oke-atp-helidon.yaml`。

例如，命令将是：

```sh
oci artifacts generic artifact upload-by-path  
--repository-id ocid1.artifactrepository.oc1.iad.0.amaaaaaxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  
--artifact-path deploy.yaml  
--artifact-version v0.1  
--content-body ./k8s/deploy/oke-atp-helidon.yaml
```

运行这个。

如果返回以下响应则没有问题。
```json
{
  "data": {
    "artifact-path": "deploy.yaml",
    "compartment-id": "ocid1.tenancy.oc1..aaaaaaaar7rz6wnonqc4256wxjez577mgyql55m55uny4nrhdgyay6cptfta",
    "defined-tags": {
      "Oracle-Tags": {
        "CreatedBy": "oracleidentitycloudservice/xxxxxxxxxxxxx@oracle.com",
        "CreatedOn": "2021-11-16T03:45:12.546Z"
      }
    },
    "display-name": "deploy.yaml:v0.1",
    "freeform-tags": {},
    "id": "ocid1.genericartifact.oc1.iad.0.amaaaaaajv6lhnxxxxxxxxxxxxxxxxxxxkup5tmsxsvkeyhpavntrbrk4mjjq",
    "lifecycle-state": "AVAILABLE",
    "repository-id": "ocid1.artifactrepository.oc1.iad.0.amaaaaaaxxxxxxxxxxxxxxxxxxxxxxxkmuwnpjbnzequa",
    "sha256": "7415c1c9ba36d7b2d8c1af64fc7b17b4d007259b3be91a9b2df323a5e670803d",
    "size-in-bytes": 1593,
    "time-created": "2021-11-16T03:45:12.712000+00:00",
    "version": "v0.1"
  }
}
```

您还可以按如下方式在 Artifact Registry 上查看它。

![5-008.jpg](5-008.jpg)

这样就完成了 Manifest 文件到 Artifact Registry 的注册。

### 5-2. 将 OKE 环境注册到 OCI DevOps

在这里，我们将向 OCI DevOps 注册 OKE 环境，以便将示例应用程序部署到 OKE。

单击 Developer Services 下 DevOps 类别下的 Projects。

![4-001.jpg](4-001.jpg)

单击列表中的 ![4-002.jpg](4-002.jpg)。

单击 DevOps 项目资源下的环境。

![5-009.jpg](5-009.jpg)

单击 ![5-010.jpg](5-010.jpg)。

输入以下项目。

键|值
-|-
环境类型|Oracle Kubernetes Engine
名称|handson-env

![5-011.jpg](5-011.jpg)

单击 ![5-012.jpg](5-012.jpg)。

输入以下项目。

键|值
-|-
地区|您所在的地区
车厢|你的车厢
集群|集群1

![5-013.jpg](5-013.jpg)

单击 ![5-014.jpg](5-014.jpg)。

这样就完成了 OKE 环境向 OCI DevOps 的注册。

### 5-3. 构建 CD 管道

在这里，我们将构建一个 CD 管道，以将示例应用程序部署到 OKE。

首先，设置部署到 OKE 时使用的 Manifest，以便在部署管道中使用。

单击 Developer Services 下 DevOps 类别下的 Projects。

![4-001.jpg](4-001.jpg)

单击列表中的 ![4-002.jpg](4-002.jpg)。

单击 DevOps 项目资源下的工件。

![4-003.jpg](4-003.jpg)

单击 ![4-004.jpg](4-004.jpg)。

输入以下项目。

键|值
-|-
名称|handson_manifest
类型|Kubernetes 清单
工件来源 | 工件注册表存储库
Select artifact registry repository| 选择你在Registering the manifest file in中注册的artifact registry
选择 Artifact | ![5-016.jpg] (5-016.jpg) 点击 [5-1- Register manifest file to artifact registry] (#5-1- Register manifest file to artifact registry Register) 选择工件（部署.yaml:v0.1) 注册于

![5-018.jpg](5-018.jpg)

单击 ![5-017.jpg](5-017.jpg)。

接下来，我们开始构建管道。

单击 Developer Services 下 DevOps 类别下的 Projects。

![4-001.jpg](4-001.jpg)

单击列表中的 ![4-002.jpg](4-002.jpg)。

单击 DevOps 项目资源下的部署管道。

![5-015.jpg](5-015.jpg)

单击 ![5-019.jpg](5-019.jpg)。

输入以下项目。

键|值
-|-
名称|handson_deploy

![5-020.jpg](5-020.jpg)

单击 ![5-021.jpg](5-021.jpg)。

单击显示屏幕中央列表中的 ![4-012.jpg](4-012.jpg)，然后单击 ![4-013.jpg](4-013.jpg)。

选择将清单应用到 Kubernetes 集群。

![5-022.jpg](5-022.jpg)

单击 ![5-023.jpg](5-023.jpg)。

键|值
-|-
阶段名称|handson_deploy
Environment|Environment registered in [5-2-Registration of oke environment to oci-devops](#5-2-Registration of oke environment to oci-devops).这次`handson-env`
选择一个或多个工件|选择 ![5-026.jpg](5-026.jpg) 并选择您刚刚创建的工件 (`handson_manifest`)

![5-024.jpg](5-024.jpg)

单击 ![5-025.jpg](5-025.jpg)。

这样就完成了 CD 流水线的构建。

### 5-4. 将 CD 管道启动步骤添加到 CI 管道

最后，构建您的管道，以便您的 CI 管道可以自动启动您的 CD 管道。

单击 Developer Services 下 DevOps 类别下的 Projects。

![4-001.jpg](4-001.jpg)

单击列表中的 ![4-002.jpg](4-002.jpg)。

然后单击 DevOps Project Resources 下的 Build Pipelines。

![4-007.jpg](4-007.jpg)

单击 ![5-027.jpg](5-027.jpg)。

接下来，![4-012.jpg](4-012.jpg)，然后点击![4-013.jpg](4-013.jpg)。

选择：

键|值
-|-
选项|触发器部署

![5-028.jpg](5-028.jpg)

单击 ![5-029.jpg](5-029.jpg)。

输入以下项目。

键|值|描述
-|-
单击阶段名称 |handson_deploy_call|! 选择 CD 管道 (`handson_deploy`)

![5-030.jpg](5-030.jpg)

单击 ![5-031.jpg](5-031.jpg)。

这样就完成了 CD 流水线的构建。

6.部署应用
----

在这里，我们将运行到目前为止构建的 CI/CD 管道并检查示例应用程序。

![0-000.jpg](0-000.jpg)

这次我将手动完成。 （自动CI/CD在[7. Redeploy application]（#7 Redeploy application）中执行）

单击 Developer Services 下 DevOps 类别下的 Projects。

![4-001.jpg](4-001.jpg)

单击列表中的 ![4-002.jpg](4-002.jpg)。

然后单击 DevOps Project Resources 下的 Build Pipelines。

![4-007.jpg](4-007.jpg)

单击 ![5-027.jpg](5-027.jpg)。

单击屏幕右上角的 ![6-001.jpg](6-001.jpg)。

将出现如下所示的屏幕。

![6-006.jpg](6-006.jpg)

单击 ![6-002.jpg](6-002.jpg)。

将出现这样的屏幕，构建管道将启动。

![6-003.jpg](6-003.jpg)

确认屏幕左上角的“状态”为“成功”。 （这需要一些时间）

接下来，当构建管道完成时，它会自动启动部署管道，因此请检查状态。

单击 Developer Services 下 DevOps 类别下的 Projects。

![4-001.jpg](4-001.jpg)

然后单击 DevOps 项目资源下的部署。

![6-007.jpg](6-007.jpg)

等待状态变为“成功”，如下图所示。 （这需要一些时间）

![6-008.jpg](6-008.jpg)

当构建流水线和部署流水线都变成“成功”状态后，[启动Cloud Shell](/ocitutorials/cloud-native/oke-for-commons/#3准备cli执行环境cloud-shell)，运行如下命令：

```sh
kubectl get service oke-atp-helidon
```

**命令结果**
```
NAME                  TYPE           CLUSTER-IP       EXTERNAL-IP         PORT(S)       AGE
oke-atp-helidon   LoadBalancer      10.96.165.239     ***.***.***.***    80:31667/TCP   79s
```
`EXTERNAL-IP`部分的`***.***.***.***`为公网IP（OCI的公网LoadBalabncer的IP地址）。

启动您的网络浏览器并访问“http://public IP”。

如果显示web应用程序，则成功。

![6-004.jpg](6-004.jpg)

此外，在 CI 和 CD 管道的开始和完成（失败）时间，通知将发送到在 [2-1. Creating OCI Notifications]（#2-1-Creating Oci-notifications）中设置的电子邮件地址. 请检查。

7.重新部署应用
------

在这里，您将体验 CI/CD 以及应用程序的更改。

### 7-1.更改应用头图

[启动Cloud Shell](/ocitutorials/cloud-native/oke-for-commons/#3准备cli执行环境cloud-shell)。

切换到 `oke-handson` 目录。

```sh
cd oke-handson
```

执行以下命令更新镜像文件。

```sh
cp src/main/resources/web/images/forsale_new2.jpg src/main/resources/web/images/forsale.jpg
```

提交到存储库。

```sh
git add .
```

```sh
git commit -m "更改首页图像"
```

```sh
git push
```


### 7-2. 检查应用反射

由于 OCI DevOps 上的 CI/CD 管道已被 git push in [7-1-Change application header image] (#7-1-Change application header image) 触发，从控制台确认。

单击 Developer Services 下 DevOps 类别下的 Projects。

![4-001.jpg](4-001.jpg)

单击列表中的 ![4-002.jpg](4-002.jpg)。

然后单击 DevOps Project Resources 下的 Build History。

![7-001.jpg](7-001.jpg)

之前git push触发的历史会显示在构建历史列表中。

![7-002.jpg](7-002.jpg)

与【6.部署应用】（#6 Deploying the application）一样，当构建流水线和部署流水线都变为“成功”状态时，【6.部署应用】（#6访问你在Deploying中确认的公网IP应用程序）再次。
您可以看到标题图像已更改。

![7-003.jpg](7-003.jpg)

本次动手实践到此结束！ ！谢谢你的辛劳工作！ ！

8.【可选】本次使用的应用补充信息
------

在这里，我们将解释用于部署的清单文件 (oke-atp-helidon.yaml) 的详细信息。

这次，我创建了 ATP 用户名和密码作为 kubernetes Secret 资源，并将它们用作加载应用程序中容器上的环境变量。
在这个实践中，我们使用了一个名为 `oke-atp-helidon.yaml` 的清单。

上面的清单文件如下所示：

```yaml
apiVersion: v1
kind: Service
metadata:
  name: oke-atp-helidon
  namespace: default
spec:
  type: LoadBalancer
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app: oke-atp-helidon
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: oke-atp-helidon
spec:
  selector:
    matchLabels:
      app: oke-atp-helidon
  replicas: 2
  template:
    metadata:
      labels:
        app: oke-atp-helidon
        version: v1
    spec:
      # The credential files in the secret are base64 encoded twice and hence they need to be decoded for the programs to use them.
      # This decode-creds initContainer takes care of decoding the files and writing them to a shared volume from which db-app container
      # can read them and use it for connecting to ATP.
      containers:
      - name: oke-atp-helidon
        image: iad.ocir.io/orasejapan/handson:${BUILDRUN_HASH}
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
        env:
        - name: javax.sql.DataSource.test.dataSource.user
          valueFrom:
            secretKeyRef:
              name: customized-db-cred
              key: user_name
        - name: javax.sql.DataSource.test.dataSource.password
          valueFrom:
            secretKeyRef:
              name: customized-db-cred
              key: password
        volumeMounts:
        - name: handson
          mountPath: /db-demo/creds              
      volumes:
      - name: handson
        secret:
          secretName: okeatp
```

让我们关注第 40-49 行。
以下几行将数据库用户和密码设置为容器中的环境变量，从秘密的 customized-db-cred 中读取它们的值。

```yaml
    - name: javax.sql.DataSource.test.dataSource.user
      valueFrom:
        secretKeyRef:
          name: customized-db-cred
          key: user_name
    - name: javax.sql.DataSource.test.dataSource.password
      valueFrom:
        secretKeyRef:
          name: customized-db-cred
          key: password
```

在这种情况下，用户名从 Secret 资源中读取为名为“javax_sql_DataSource_workshopDataSource_dataSource_user”的环境变量，密码为“javax_sql_DataSource_workshopDataSource_dataSource_password”。

这次，秘密资源“customized-db-cred”是在[3-4.创建应用程序使用的数据库用户/密码]的过程中创建的（#3-4-创建应用程序使用的数据库用户密码）创建。

这样，在kubernetes中，应用使用的机密信息可以作为Secret资源隐藏起来，其值可以作为环境变量读取。
更多信息，请查看[官方文档](https://kubernetes.io/docs/concepts/configuration/secret/)。

接下来说说钱包文件。

让我们再次检查清单文件。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: oke-atp-helidon
  namespace: default
spec:
  type: LoadBalancer
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app: oke-atp-helidon
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: oke-atp-helidon
spec:
  selector:
    matchLabels:
      app: oke-atp-helidon
  replicas: 2
  template:
    metadata:
      labels:
        app: oke-atp-helidon
        version: v1
    spec:
      # The credential files in the secret are base64 encoded twice and hence they need to be decoded for the programs to use them.
      # This decode-creds initContainer takes care of decoding the files and writing them to a shared volume from which db-app container
      # can read them and use it for connecting to ATP.
      containers:
      - name: oke-atp-helidon
        image: iad.ocir.io/orasejapan/handson:${BUILDRUN_HASH}
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
        env:
        - name: javax.sql.DataSource.test.dataSource.user
          valueFrom:
            secretKeyRef:
              name: customized-db-cred
              key: user_name
        - name: javax.sql.DataSource.test.dataSource.password
          valueFrom:
            secretKeyRef:
              name: customized-db-cred
              key: password
        volumeMounts:
        - name: handson
          mountPath: /db-demo/creds              
      volumes:
      - name: handson
        secret:
          secretName: okeatp
```
我在 [3-2. ATP provisioning] (#3-2-atp provisioning) 的清单中定义了字段 `walletName: okeatp`。
换句话说，在OSOK提供ATP的同时创建了一个钱包，其名称为`okeatp`。
此处创建的钱包存储在第 53-56 行名为“handson”的 Pod 卷中。

此外，第 50-52 行将上面配置的“handson”资源挂载到容器上的路径“/db-demo/creds”。

这次，这个挂载的资源用于配置文件 (oke-atp-helidon-handson/src/main/resources/META-INF/microprofile-config.properties)。

```yaml
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Microprofile server properties
server.port=8080
server.host=0.0.0.0

javax.sql.DataSource.test.dataSourceClassName=oracle.jdbc.pool.OracleDataSource
javax.sql.DataSource.test.dataSource.url=jdbc:oracle:thin:@okeatp_high?TNS_ADMIN=/db-demo/creds

server.static.classpath.location=/web
server.static.classpath.welcome=index.html
```

让我们关注第 11 行。

```yaml
javax.sql.DataSource.test.dataSource.url=jdbc:oracle:thin:@okeatp_high?TNS_ADMIN=/db-demo/creds
```

`jdbc:oracle:thin:@okeatp_high?TNS_ADMIN=/db-demo/creds`是读取钱包文件的部分。
这是之前使用清单安装的路径。
现在您可以在您的应用程序中使用 Kubernetes Secret 中设置的钱包文件。

