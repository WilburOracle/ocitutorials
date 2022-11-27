---
title: "创建Oracle Container Engine for Kubernetes(OKE)"
excerpt: "使用 Oracle Cloud Infrastructure (OCI) 管理控制台创建 OKE 集群。 让我们从这里开始。"
layout: single
order: "014"
tags:
---

一组以托管 Kubernetes 服务 Oracle Container Engine for Kubernetes (OKE) 为中心的容器原生服务。

Oracle Container Engine for Kubernetes（以下简称 OKE）是 Oracle 的托管 Kubernetes 服务。此通用过程描述了如何构建 CLI 执行环境（使用资源管理器）来操作 OCI 和 OKE，以及如何使用 OKE 配置 Kubernetes 集群。

先决条件
--------
- 云环境
    * 必须拥有 Oracle 云帐户

动手环境的形象
----------
![](01-01-01.png)

1.配置OKE集群
----------------------------------
现在我们将配置 OKE 集群。通过执行此处的步骤，OKE 控制平面和 Kubernetes 集群将同时构建。

![](02-01-01.png)

首先，展开 OCI 控制台屏幕左上角的汉堡菜单并选择 `Developer Services` ⇒ `Kubernetes Clusters (OKE)`。

![](02-02.png)

在集群列表屏幕上，单击“创建集群”。

![](02-03.png)

在下一个对话框中选择“快速创建”并单击“启动工作流”。

![](02-03-2.png)

在下一个对话框中，输入任意名称并选择一个版本。我们将继续使用此处的默认设置。

对于`Kubernetes API endpoint`，这次选择默认的`public endpoint`。

**关于 Kubernetes API 端点**
管理员可以将集群的 Kubernetes API 端点配置到私有或公共子网中。
通过使用 VCN 路由和防火墙规则，您可以控制对 Kubernetes API 端点的访问，以便只能从本地构建的堡垒服务器或同一 VCN 中访问它们。
{: .notice--info}

对于“Kubernetes worker nodes”，这次选择“Private”。这是，
如果您需要根据工作负载为工作节点提供公共 IP，请选择“公共”。

**关于 Kubernetes 工作节点**
根据它是私有的还是公共的，分配给工作节点的 IP 地址类型将会改变。
Private 将只为工作节点提供私有 IP。
如果您需要为工作节点提供公共 IP，请选择“公共”。
{: .notice--info}

对于`Shape`，这次选择`VM.Standard.E3.Flex`。
这种形状允许您灵活地更改 OCPU 和内存 (RAM)。
这一次，使用 1oCPU/16GB 创建。

**关于形状**
OKE 有多种形态可供选择，例如 VM、裸机、GPU 和 HPC。
您还可以选择基于 Intel/AMD/ARM 的实例作为处理器架构。
为您的工作量选择合适的形状。
{: .notice--info}

节点数指定工作节点的数量。默认指定为“3”，但请将其更改为“1”，这是本动手操作中的最低配置。

**节点数**
节点尽可能均匀地分布在一个区域内的可用性域中（或者，在单个可用性域的情况下，例如东京区域，跨该可用性域内的故障域）。
请根据实际运行时的可用性，指定合适的节点数。
{: .notice--info}

然后移至对话框底部并单击下一步。

![](02-03-1.png)

下一个对话框将确认您的输入并单击“创建集群”。

![](02-04.png)

默认设置会自动配置集群所需的网络资源。进度会显示在对话框中，请等待显示“已创建集群和相关网络资源”消息，然后单击“关闭”按钮。

![](02-05.png)

显示集群详细信息屏幕时，检查“集群状态”中显示的内容。此时它将显示为“Creating”，但一旦配置完成将变为“Active”（大约需要 5-10 分钟才能完成）。

**之后如何进行**
直到集群完成，继续下一章“3.准备CLI执行环境（Cloud Shell）”中的步骤。
{: .notice--info}

2. CLI执行环境的准备（Cloud Shell）
----------------------------------
接下来，准备好执行 CLI 的环境，例如 OKE 集群。

![](01-01-02.png)

在本次实践中，我们将使用名为 Cloud Shell 的服务作为环境来执行一些运行 OKE 集群的 CLI。
Cloud Shell 是一个基于 Web 浏览器的控制台，可从 Oracle Cloud Console 访问。
Cloud Shell 预装了当前版本的 OCI CLI 以及其他一些有用的工具和实用程序，例如：
详情请参考【官方文档说明】（https://docs.cloud.oracle.com/ja-jp/iaas/Content/API/Concepts/cloudshellintro.htm）。

安装工具 |
-|
Git |
Java |
Python (2および3) |
SQL Plus |
kubectl |
helm |
maven |
gradle |
terraform |
ansible |

**关于云壳**
Cloud Shell 并非专门用于开发，而是假设您想临时执行 OCI 命令时使用量较少的服务，因此请为实际操作准备单独的 CLI 执行环境。
{: .notice--warning}

单击 OCI 控制台右上角的终端图标。

![](01-02-01.png)


稍等片刻，Cloud Shell 将启动。

![](01-02-02.png)

此时已安装所需的 CLI，因此您可以运行如下命令。

```
kubectl version --client --short
```

如果您得到类似于以下的结果，则 kubectl 已成功安装。
```
Client Version: vX.XX.X
```

以上是显示 kubectl（管理 Kubernetes 的命令行工具）的版本信息及其结果的命令。

这样就完成了准备工作。


3. 设置 kubectl
--------------------------------------
![](03-01-01.png)

接下来，让我们设置 kubectl 并实际访问集群。

展开 OCI 控制台屏幕左上角的汉堡菜单并选择 `Developer Services`⇒`Kubernetes Clusters (OKE)`。

![](02-02.png)

单击您在上一步中创建的“cluster1”的名称。

![](03-08.png)

**关于从这里开始的程序**
必须配置 OKE 集群才能从此处继续。
在集群详细信息屏幕上，确保“集群状态”为“活动”。如果它仍然是“进行中”，请等待状态改变。
{: .notice--info}

在集群详细信息屏幕上，单击“访问集群”。

![](03-09.png)

您将看到一个标题为“访问我的集群”的对话框。
OKE有两种访问方式：“Cloud Shell访问”和“本地访问”。
由于本次使用 Cloud Shell 作为 CLI 环境，因此使用“Cloud Shell 访问”进行访问。
点击对话框顶部的 Cloud Shell Access。

获取kubetctl配置文件的命令显示在显示的对话框中。

![](03-12-01.png)

首先，启动 ![](03-17.png)Cloud Shell。
如果它已经启动，则不需要此过程。
启动Cloud Shell，点击对话框中显示的“启动Cloud Shell”，或参考【3-1.启动Cloud Shell】（启动#3-1-cloud-shell），请给我。

**Cloud Shell 以外的用户**
如果您已经创建了单独的客户端环境，请登录到创建的环境并从您的主目录（`/home/opc`）执行命令。另外，执行“本地访问”命令。
{: .notice--info}

接下来，命令 ![](03-18.png) 执行获取 OCI CLI 配置文件的命令。
单击右端的“复制”，将其复制，粘贴到 Cloud Shell 中并运行。
（由于下面的示例填充了虚拟值，请从对话框中复制实际命令）

    oci ce cluster create-kubeconfig --cluster-id ocid1.cluster.oc1.iad.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx --file $HOME/.kube/config --region ap-tokyo-1 --token-version 2.0.0 --kube-端点 PUBLIC_ENDPOINT

**关于 kubectl 命令**
默认情况下，kubectl 命令旨在读取路径 `$HOME/.kube/config` 中的文件。
详细请看 kubectl 的【官方文档】(https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/#set-the-kubeconfig-environment-variable)命令。请参考
{: .notice--info}

最后，执行以下命令检查 kubectl 的运行情况。

    kubectl get nodes

如果得到如下执行结果，就可以正常访问集群了。

    NAME        STATUS   ROLES   AGE   VERSION
    10.0.10.2   Ready    node    20s   v1.21.5

这样就完成了使用 OKE 配置 Kubernetes 集群并开始使用它的步骤。
在此之后按照每个操作说明进行操作。

[初学者 - 让我们用 OKE 运行一个应用程序](../oke-for-beginners/)

[中级 - 让我们体验使用 OKE 部署示例应用程序和 CI/CD](../oke-for-intermediates/)

[高级 - 使用 OKE 部署示例微服务应用程序并使用可观察性工具](../oke-for-advances/)

4.【可选】创建CLI执行环境（VM实例）
----------------------------------
第 5 步是可选的，对于动手实施基本上没有必要。
如果您想在 VM 实例而不是 Cloud Shell 中创建用于操作 OKE 的客户端，或者如果您对 Oracle Cloud Infrastructure 上的托管 Terraform 服务“资源管理器”感兴趣，请参考它。

### 4-1. 访问 OCI 控制台
从浏览器访问 OCI 控制台。 [登录](https://cloud.oracle.com/en_US/home) 使用您的云帐户。

![](01-01-1.png)

- 1。点击登录
- 2。输入云账号名（租户名）
- 3。点击下一步
- 四。输入您的云用户名和密码，然后单击登录

### 4-2. 使用资源管理器构建环境
本节中的工作是使用称为 OCI 的资源管理器的服务执行的。尽管可以手动创建 VM 实例、安装 CLI、设置策略等，但这些过程可以通过使用资源管理器实现自动化且省力。

**关于资源管理器**
【资源管理器】(https://docs.oracle.com/cd/E97706_01/Content/ResourceManager/Concepts/resourcemanager.htm)基于文本配置信息组织Oracle Cloud上的多个资源，可以创建的配置管理服务/修改/删除者
资源管理器以 Terraform 格式描述配置信息。
{: .notice--info}

![](01-21.png)

#### 4-2-1. 创建堆栈
要使用资源管理器，您需要使用配置信息创建文本文件并将它们放在一个 zip 存档中。已创建资源管理器存档。
从 [这里]（https://github.com/oracle-japan/oke-handson-prerequisites/releases/tag/v1.4）下载。

![](01-02.png)

下载文件“oke-handson-prerequisites.zip”。

接下来，展开屏幕左上角的汉堡菜单并选择“开发者服务”⇒“资源管理器”。

![](01-05.png)

在资源管理器屏幕上，单击创建堆栈。

![](01-06.png)

堆栈是由资源管理器服务管理的 Terraform 命令的执行环境。通过在此处上传资源管理器存档并创建堆栈，已在云端配置上传的 Terraform 模板的执行环境。

在“创建堆栈”屏幕上，选择“我的配置”，将“.zip 文件”拖放到此处，或将您下载的资源管理器存档拖放到“浏览”区域，并在底部的“TERRAFORM 版本”中将“1.0.x” .
然后点击“下一步”。

![](01-07.png)

![](01-07-01.png)

资源管理器将使用适当的值自动填充每个环境的“TENANCY_OCID”、“COMPARTMENT_OCID”和“Region”变量。确保变量已填充，然后单击下一步。

![](01-08.png)

**关于地区**
Oracle 云基础设施可在包括北美和东京在内的众多数据中心使用。在这里，我们将在创建帐户时设置本地区域继续该过程。
[区域和可用性域](https://docs.oracle.com/cd/E97706_01/Content/General/Concepts/regions.htm)
{: .notice--info}

将显示输入信息的确认屏幕，因此单击“创建”以创建堆栈。

![](01-09.png)

堆栈创建完成后，将显示已创建堆栈的详细屏幕。

![](01-10.png)


#### 4-2-2. 作业执行
现在让我们实际运行堆栈并配置环境。

在堆栈详细信息屏幕上，展开“Terraform Actions”菜单并单击“Apply”。

![](01-11.png)

在“应用”对话框中单击“应用”。

![](01-12.png)

这将启动配置客户端环境和创建 OKE 集群所需的作业。

该作业需要几分钟才能完成，因此请检查您在此期间在日志中看到的内容。资源管理器在云环境中运行 Terraform，输出到 stdout 的结果就是您在日志中看到的内容。

![](01-13.png)

当作业状态变为“成功”时，作业已成功完成。

![](01-14.png)

### 4-3.登录CLI执行环境
作业执行完成后，我们来实际连接CLI执行环境。单击屏幕左下角的“输出”。

![](01-15.png)

在这里，您可以看到与运行作业所创建的资源相关的信息。如果一切顺利，您应该会看到信息 `oke-client` 和 `private_key_pem`。这些分别是 CLI 执行环境 IP 地址和 SSH 私钥。

![](01-16.png)

通过将值复制并粘贴到文本文件中来记下“oke-client”。

可以通过单击“复制”部分将“private_key_pem”值保存到剪贴板。为此，请启动一个新的文本编辑器，将其粘贴并以文件名“privatekey.pem”保存。

![](01-17.png)

接下来，双击桌面上的 Tera Term 快捷方式图标，启动 Tera Term。当“Tera Term: New Connection”对话框出现时，输入您在上述步骤中为`host`记下的IP地址，然后单击`OK`。

![](01-18.png)

如果出现“安全警告”对话框，请单击“继续”而不做任何更改。

![](01-19.png)

出现“SSH Authentication”对话框时，设置如下值，然后点击`OK`。

项目|输入值
-|-
用户名|opc
选中单选框|打开`Use RSA/DSA/EDCSA/ED25519`并选择上述过程中保存的私钥文件（privatekey.pem）。
（以上除外）|（默认）

![](01-20.png)

如果连接到 CLI 执行环境成功，您将看到类似于以下内容的控制台输出。

    最后登录时间：2019 年 8 月 2 日星期五 04:21:15 来自 156.151.8.3
    [opc@oke-client ~]$

此时已安装所需的 CLI，因此您可以运行如下命令。

```
kubectl 版本 --client --short
```

如果您得到类似于以下的结果，则 kubectl 已成功安装。
```
客户端版本：vX.XX.X
```

以上是显示 kubectl（管理 Kubernetes 的命令行工具）的版本信息及其结果的命令。

这样就完成了CLI执行环境的创建。

### 4-4. OCI CLI 设置
设置 OCI CLI 环境以使用 OKE 集群。

#### 4-4-1. 检查您的租户的OCID
OCI CLI 设置需要租户和用户的 OCID（标识符）来配置 CLI 将作为哪个租户的用户帐户运行。首先，获取此租户的 OCID。

单击 OCI 控制台屏幕右上角的人形图标，然后从展开的配置文件中单击 `tenancy:<tenancy name>`。

![](03-01-1.png)

单击租户信息“OCID”右侧的“复制”，将租户 OCID 复制到剪贴板。

该值将在后面的步骤中使用，因此请通过将其粘贴到文本编辑器等中来记下它。

![](03-01-2.png)

#### 4-4-2. 检查用户的OCID
接下来，获取您的租户的 OCID。
单击 OCI 控制台屏幕右上角的人形图标，然后从展开的配置文件中单击“用户名”（oracleidentitycloudservice/<用户名>）。

![](03-02.png)

会显示用户信息，点击“OCID”右侧的“复制”，将用户OCID复制到剪贴板。

![](03-03.png)

该值将在后面的步骤中使用，因此请通过将其粘贴到文本编辑器等中来记下它。

#### 4-4-3. OCI CLI 设置
现在让我们设置 OCI CLI。
[启动 Cloud Shell]（启动 #3-1-cloud-shell），然后
请运行命令

    oci 设置配置

**Cloud Shell 以外的用户**
如果您已经创建了单独的客户端环境，请登录到创建的环境并从您的主目录（`/home/opc`）执行命令。
{: .notice--info}

设置的交互将开始，因此请输入下表所示的问题。

问题|答案操作
-|-
为您的配置输入一个位置 [/home/opc/.oci/config]|什么都不做`[Return]`
输入用户OCID|输入上一步找到的用户OCID
输入租户 OCID|输入上一步中的租户 OCID
按索引或名称输入区域（例如 1：ap-chiyoda-1、2：ap-chuncheon-1、3：ap-hyderabad-1、4：ap-melbourne-1、5：ap-mumbai-1、6 : ap-osaka-1, 7: ap-seoul-1, 8: ap-sydney-1, 9: ap-tokyo-1, 10: ca-montreal-1, 11: ca-toronto-1, 12: eu -amsterdam-1, 13: eu-frankfurt-1, ...)|输入创建CLI执行环境时指定的区域（数字OK）
是否要生成新的 RSA 密钥对？（如果拒绝，系统会要求您提供现有密钥的路径。）[Y/n]|`Y + [Return]`
输入要创建的密钥的目录[/home/opc/.oci]|无输入`[Return]`
输入密钥的名称 [oci\_api\_key]|无输入`[Return]`
为您的私钥输入密码（空无密码）|无输入`[Return]`

从 CLI 操作 Oracle Cloud 环境时，每次执行命令时都会执行身份验证。此身份验证的密钥必须提前在您在 Oracle Cloud 上的用户帐户中设置。

由于密钥对是在上述 OCI CLI 设置中创建的，因此请将公钥设置为用户帐户。

首先，在 Tera Term 中执行以下命令来显示公钥。

    猫 ~/.oci/oci_api_key_public.pem

接下来，移动到控制台并转换到用户详细信息屏幕。

![](03-02.png)


向下滚动用户详细信息屏幕，然后单击“API Key”。

![](03-05-01.png)

单击添加公钥。

![](03-05.png)

显示“添加公钥”对话框的输入字段。
这次点击`Paste public key`，粘贴之前在Tera Term中显示的公钥，然后点击`Add`按钮（`-----BEGIN PUBLIC KEY----- and `-----END PUBLIC KEY-----`行）。
如果要将公钥注册为文件，请单击“选择公钥文件”并注册公钥。

![](03-16.png)

OCI CLI 设置现已完成。
