---
title: "使用 Oracle Container Engine for Kubernetes (OKE) 运行 Kubernetes"
excerpt: "Oracle Container Engine for Kubernetes (OKE) 是 Oracle 云基础设施 (OCI) 上提供的托管 Kubernetes 服务。 在本次动手中，是可以让你摸到OKE的内容，包括Kubernetes本身的特点和使用方法。"
layout: single
order: "020"
tags:
---
Oracle Container Engine for Kubernetes（以下简称 OKE）是 Oracle 的托管 Kubernetes 服务。
在本次动手实践中，您可以通过将示例应用程序部署到 OKE 的过程来学习 Kubernetes 本身的基本操作方法和特性。

此类别包括以下服务：

- 适用于 Kubernetes 的 Oracle 容器引擎 (OKE)：
：提供完全托管的 Kuberentes 集群的云服务。
- Oracle 云基础设施注册表 (OCIR)：
：提供完全托管的符合 Docker v2 标准的容器注册表的服务。

先决条件
--------

- 云环境
    * 必须拥有 Oracle 云帐户
    * 完成【OKE动手准备】(/ocitutorials/cloud-native/oke-for-commons/)

1.创建容器镜像
---------------------------------
在这里，我们将创建一个运行示例应用程序的容器映像。

### 1.1. 克隆源代码

这次使用的示例应用程序已创建为 oracle-japan GitHub 帐户下的存储库。

访问 [示例应用程序存储库](https://github.com/oracle-japan/cowweb-for-wercker-demo) 并单击“代码”按钮。

有两种方法可以获取源代码。一种是使用 git 客户端克隆，另一种是下载为 ZIP 文件。在这里，我们将使用前一个过程，因此在已展开的气球形对话框中单击 URL 字符串右侧的剪贴板图标。

这会将 URL 复制到剪贴板。

![](2.3.PNG)

在 Cloud Shell 或 Linux 控制台中，执行以下命令以克隆源代码。

     git clone [复制仓库的 URL]

接下来，将克隆的目录设置为当前目录。

     cd cowweb-for-wercker-demo

### 1.2. 创建容器镜像
容器镜像由一个名为 Dockerfile 的文件定义，该文件描述了容器的配置。

示例应用程序的代码包含一个已经创建的 Dockerfile，所以让我们检查它的内容。 执行以下命令。

    cat Dockerfile

```dockerfile
# 1st stage, build the app
FROM maven:3.8.4-openjdk-17-slim as build

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
FROM openjdk:17-jdk-slim
WORKDIR /helidon

# Copy the binary built in the 1st stage
COPY --from=build /helidon/target/cowweb-helidon.jar ./
COPY --from=build /helidon/target/libs ./libs

CMD ["java", "-jar", "cowweb-helidon.jar"]

EXPOSE 8080
```

查看 Dockerfile 的内容，我们可以看到有两行以 FROM 开头。以 FROM 开头的前几行将示例应用程序的代码复制到安装了 jdk 的容器映像中，然后运行 ​​`mvn package` 来构建应用程序。

基于安装jdk的容器镜像，从以下FROM开始的一系列处理是创建应用执行用户，复制构建创建的jar文件，设置容器启动时执行的命令。增加。

现在使用这个 Dockerfile 创建一个容器镜像。执行以下命令。

    docker image build -t [存储库名称]/cowweb:v1.0 。

您可以在此命令中为 `repository name` 指定任何字符串，但通常以小写形式指定项目名称、用户名等。例如，命令将是：

    docker image build -t oke-handson/cowweb:v1.0 .

如果该过程以如下所示的 `Successfully tagged` 消息结束，则映像构建完成。

```
Sending build context to Docker daemon  128.5kB
Step 1/13 : FROM maven:3.8.4-openjdk-17-slim as build
Trying to pull repository docker.io/library/maven ... 
3.8.4-openjdk-17-slim: Pulling from docker.io/library/maven
f7a1c6dad281: Pull complete 
ea8366d5a4a5: Pull complete 
bff4abe573cd: Pull complete 
3f92e41bef06: Pull complete 
6581ea1ec5a5: Pull complete 
de879b0c951f: Pull complete 
ac1236d673e3: Pull complete 
Digest: sha256:150deb7b386bad685dcf0c781b9b9023a25896087b637c069a50c8019cab86f8
Status: Downloaded newer image for maven:3.8.4-openjdk-17-slim
 ---> 849a2a2d4242
Step 2/13 : WORKDIR /helidon
 ---> Running in 503337c170c7
Removing intermediate container 503337c170c7
 ---> e456a937870a
Step 3/13 : ADD pom.xml .
 ---> fadb77529253
Step 4/13 : RUN mvn package -Dmaven.test.skip -Declipselink.weave.skip
 ---> Running in 190344b19870

...（中略）...

Step 9/13 : WORKDIR /helidon
 ---> Running in ede9941ef284
Removing intermediate container ede9941ef284
 ---> ed9214bcc7e8
Step 10/13 : COPY --from=build /helidon/target/cowweb-helidon.jar ./
 ---> 72e6abc15a88
Step 11/13 : COPY --from=build /helidon/target/libs ./libs
 ---> 039c2d539641
Step 12/13 : CMD ["java", "-jar", "cowweb-helidon.jar"]
 ---> Running in b579e0845ce9
Removing intermediate container b579e0845ce9
 ---> 9344c0c557ac
Step 13/13 : EXPOSE 8080
 ---> Running in d19e9f20932b
Removing intermediate container d19e9f20932b
 ---> 5e997bb463db
Successfully built 5e997bb463db
Successfully tagged oke-handson/cowweb:v1.0
```

您可以使用 `docker image ls` 命令检查实际构建的图像。

    docker image ls

```
REPOSITORY           TAG                     IMAGE ID            CREATED             SIZE
oke-handson/cowweb   v1.0                    a328bfaffb52        4 minutes ago       428MB
<none>               <none>                  042346419526        5 minutes ago       505MB
openjdk              17-jdk-slim             37cb44321d04        4 months ago        408MB
maven                3.8.4-openjdk-17-slim   849a2a2d4242        5 months ago        425MB
```
你可以看到一个名为 `oke-handson/cowweb` 的图像已经被创建。

应用程序容器镜像使用安装了 maven 的容器用于构建源代码，使用安装了 openjdk 的容器用于应用程序执行环境。因此，您还会看到名称为 maven 和 openjdk 的图像。

这些容器会在构建应用程序的容器映像时自动下载和使用。

2.推送到OCIR并部署到OKE
-------------------------------------

### 2.1. 使用 OCIR 的提前准备
OCIR 是 Oracle 提供的容器注册管理服务。在这里，将 1.3. 中创建的容器镜像推送（上传）到 OCIR。

为了从 docker 命令访问 OCIR，我们将对 OCI 用户帐户进行必要的设置。

单击 OCI 控制台屏幕右上角的人形图标，然后从展开的配置文件中单击用户名 (oracleidentitycloudservice/<username>)。

![](3.2-1.png)

向下滚动并单击左侧的“身份验证令牌”以移动到令牌创建屏幕。

![](3.3.png)

单击“生成令牌”按钮。
    
![](3.4.png)

在 [Geterate Token] 对话框中，输入描述令牌用途的信息（任意字符串），然后单击“Generate Token”按钮。

![](3.5.png)
    
您将在对话框中看到生成的令牌。单击“复制”字符串会将此标记复制到剪贴板。然后点击“关闭”。

![](3.6.png)

通过将其粘贴到文本编辑器等中来记下此标记，因为它将在后面的步骤中使用。

### 2.2. 将容器镜像推送到OCIR
现在将容器图像推送到 OCIR。

首先，使用 `docker login` 命令登录 OCIR。指定要登录的注册表时，您必须为托管数据中心区域指定适当的区域代码。

从下表中找到适合您环境的区域代码。

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
uk-london-1|lhr
sa-santiago-1|scl
ap-hyderabad-1|hyd
eu-amsterdam-1|ams
me-jeddah-1|jed
ap-chuncheon-1|yny
me-dubai-1|dxb
uk-cardiff-1|cwl
us-sanjose-1|sjc
接下来，检查对象存储命名空间以登录 OCIR。

要检查对象存储命名空间，请单击 OCI 控制台屏幕右上角的人形图标，然后从展开的配置文件中检查租户：<租户名称>。


![](3.6-0.png)

检查租户信息中对象存储设置中的对象存储命名空间值。将该值复制并粘贴到文本文件中以记下它，因为它将在访问 OCIR 时使用。

![](3.6-1.png)

**关于对象存储命名空间**
每个租户分配一个对象存储命名空间。它跨越一个区域内的所有隔间。任意字符串已设置且无法更改。
{: .notice--info}

接下来，使用以下命令登录 OCIR。
    docker login [地区代码].ocir.io

例如，如果您使用的是东京地区 (nrt)，请使用以下命令登录。

    docker login nrt.ocir.io

系统会提示您输入您的用户名和密码，因此请按如下方式输入。

- 用户名：[对象存储命名空间]/[用户名]（例如 nrzftilbveen/oracleidentitycloudservice/yoi.naka.0106@gmail.com）
- 密码：[在 2.1 中创建的令牌字符串。]

**密码**
请注意，您在此处输入的密码与您用于登录 OCI 控制台的密码不同。
{: .notice--警告}

如果您看到如下所示的“Login Succeeded”消息，则表示您已成功登录。

```
Username: nrzftilbveen/Handson-001
Password:
Login Succeeded
```

接下来，更新容器图像标签以匹配 OCIR 格式。运行 `docker tag` 命令。

    docker image tag [repository name]/cowweb:v1.0 [region code].ocir.io/object storage namespace]/[repository name]/cowweb:v1.0

指定与前面步骤中指定的相同的 [Region code] 和 [Object storage namespace]。对于存储库名称，请指定您在 `docker build` 期间所做的相同字符串。

例如：

    docker image tag  oke-handson/cowweb:v1.0 nrt.ocir.io/nrzftilbveen/oke-handson/cowweb:v1.0

此操作将指定推送目标注册表的信息添加到容器映像。如果您不这样做，容器映像将采用默认注册表并使用 Docker 提供的 Docker Hub 注册表。

现在我们准备好将图像实际推送到 OCIR。执行以下命令。

    docker image push [region code].ocir.io/[object storage namespace]/[repository name]/cowweb:v1.0

例如：

    docker image push nrt.ocir.io/nrzftilbveen/oke-handson/cowweb:v1.0

如果执行结果如下，则推送成功。

```
The push refers to repository [nrt.ocir.io/nrzftilbveen/oke-handson/cowweb]
d07a2053e8fb: Pushed
93ed7a751af8: Pushed
20dd87a4c2ab: Pushed
78075328e0da: Pushed
9f8566ee5135: Pushed
v1.0: digest: sha256:5769c194f3861f71c9fd43eb763813676aaba0b41acf453fb6a09a1af7525c82 size: 1367
```

{% capture notice %}**docker push时的行为**  
如果容器注册中心被多个用户在一个组上手等情况下共享，可能会出现以下消息。
```sh
60dc38cb0cd5: Layer already exists
ea75a4331573: Layer already exists
20dd87a4c2ab: Layer already exists
…
```
这是您在上传注册表中已存在的相同内容时看到的内容，因此您可以继续执行这些步骤。{% endcapture %}
<div class="notice--warning">
  {{ notice | markdownify }}
</div>
现在让我们确认容器存储在 OCIR 中。在 OCI 控制台屏幕上，展开左上角的菜单，然后单击 `Developer Services` - `Container Registry`。

![](3.7.png)

将显示存储库列表。确保其中有一个具有指定名称的容器。

然后打开屏幕右上角的“Actions”菜单并单击“Change to Public”。

![](3.8.png)

这样就完成了在 registry 中的容器镜像存储，但默认情况下，需要与推送时获取镜像时相同的身份验证信息。为了更容易与 Kubernetes 一起使用，请将存储库更改为 Public 并将其设置为无需身份验证即可获取图像。

这样就完成了容器镜像在 OCIR 中的存储。

### 2.3. 部署到 OKE
现在是时候将应用程序的容器部署到 OKE 集群了。

从 OKE 开始，为了将容器部署到 Kubernetes 集群，需要在名为 manifest 的文件中描述集群上的放置信息。

示例应用程序的代码包含一个已创建的清单文件，因此让我们检查其内容。执行以下命令。

```
cat ./kubernetes/cowweb.yaml
```
```sh
kind: Deployment
apiVersion: apps/v1
metadata:
  name: cowweb
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cowweb
  template:
    metadata:
      labels:
        app: cowweb
        version: v1
    spec:
      containers:
        - name: cowweb
          image: ${region-code}.ocir.io/${tenancy}/${repository}/cowweb:v1.0
          imagePullPolicy: IfNotPresent
          ports:
            - name: api
              containerPort: 8080
    ...（以下略）...
```

このファイルによって、サンプルアプリケーションのコンテナが、クラスター上にどのように配置されるかが定義されています。例えば、6行目にある`replicas:2`という記述は、このコンテナが、2つ立ち上げられて冗長構成を取るということを意味しています。

**サンプルアプリについて**  
実際にKubernetes上でコンテナが動作する際には、Podと言われる管理単位に内包される形で実行されます。上記のmanifestでは、サンプルアプリのコンテナを内包するPodが、2つデプロイされることになります。
{: .notice--info}

22行目には、実際にクラスター上で動かすコンテナイメージが指定されています。現在の記述内容は、ご自身環境に合わせた記述にはなっていませんので、この部分を正しい値に修正してください。具体的には、2.2.で`docker image push`コマンドを実行する際に指定した文字列と同じ内容に修正してください。

    [リージョンコード].ocir.io/[オブジェクト・ストレージ・ネームスペース]/[リポジトリ名]/cowweb:v1.0

例えば、以下のような文字列となります。

    nrt.ocir.io/nrzftilbveen/oke-handson/cowweb:v1.0

次に、cowweb-service.yamlというmanifestファイルの内容を確認してみます。

```
cat ./kubernetes/cowweb-service.yaml
```
```sh
kind: Service
apiVersion: v1
metadata:
  name: cowweb
  labels:
    app: cowweb
  annotations:
    oci.oraclecloud.com/load-balancer-type: "lb"
    service.beta.kubernetes.io/oci-load-balancer-shape: "flexible"
    service.beta.kubernetes.io/oci-load-balancer-shape-flex-min: "10"
    service.beta.kubernetes.io/oci-load-balancer-shape-flex-max: "30"
spec:
  type: LoadBalancer
  selector:
    app: cowweb
  ports:
    - port: 80
      targetPort: 8080
      name: http
```

このmanifestファイルは、クラスターに対するリクエストのトラフィックを受け付ける際のルールを定義しています。`type: LoadBalancer`という記述は、クラスターがホストされているクラウドサービスのロードバランサーを自動プロビジョニングし、そのLBに来たトラフィックをコンテナに届けるという意味です。

それでは、Kubernetes上でサンプルアプリケーションのコンテナを動かしてみます。まずは、クラスターを区画に分けて管理するための領域である、namespaceを作成します。以下のコマンドで、namespace名は任意の文字列を指定できます。  
今回は"handson"というnamespace名で作成します。

    kubectl create namespace handson

デフォルトのNamespaceを上記で作成したものに変更しておきます。これを行うと、以降、kubectlの実行の度にNamespaceを指定する必要がなくなります。

    kubectl config set-context $(kubectl config current-context) --namespace=handson

次に、manifestファイルをクラスターに適用し、PodやServiceをクラスター内に作成します。

```
kubectl apply -f ./kubernetes/cowweb.yaml
```
```
kubectl apply -f ./kubernetes/cowweb-service.yaml
```

以下のコマンドを実行して、リソースの構成が完了しているかどうかを確認することができます。

    kubectl get pod,service

すべてのPodのSTATUSがRunnigであることと、cowwebという名前のServiceがあることが確認できれば、リソースの作成は完了です（ServiceのEXTERNAL-IPは、ロードバランサーが実際に作成されるまで表示されません。その場合は少し時間を置いて上記コマンドを再実行してください）。

```
NAME                          READY   STATUS    RESTARTS   AGE
pod/cowweb-695c65b665-sgcdk   1/1     Running   0          17s
pod/cowweb-695c65b665-vh825   1/1     Running   0          17s

NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)        AGE
service/cowweb       LoadBalancer   10.96.229.191   130.***.***.***   80:30975/TCP   1m
```

{% capture notice %}**集合ハンズオン時のロードバランサーのシェイプについて**  
集合ハンズオンなどで、一つのクラウド環境を複数のユーザーで共有している場合、利用可能なロードバランサー数の上限に達して正常にServiceが作成できない場合があります。  
そのような場合は、ロードバランサーのシェイプ（対応可能なトラフィック量）を変更して、サービスの作成を行ってみてください。
具体的には以下のコマンドを実行します。
```sh
# 作ってしまったServiceを削除
kubectl delete -f ./kubernetes/cowweb-service.yaml
```
これは既にレジストリに存在するものと同じ内容をアップロードしたときに表示されるものですので、手順をそのまま続行して問題ありません。{% endcapture %}
<div class="notice--warning">
  {{ notice | markdownify }}
</div>

**サンプルアプリについて**  
実際にKubernetes上でコンテナが動作する際には、Podと言われる管理単位に内包される形で実行されます。上記のmanifestでは、サンプルアプリのコンテナを内包するPodが、2つデプロイされることになります。
{: .notice--info}

上の例では、IPアドレス130.***.***.***の80番ポートでロードバランサーが公開されておりここにリクエストを送信すると、アプリケーションにアクセスできることを意味しています。このIPアドレスをテキストエディタ等に控えておいてください。

これでクラスターへのデプロイは完了しましたので、実際に動作確認してみます。以下のコマンドを実行してください。

    curl "http://[ロードバランサーのIP]/cowsay/say"

ローカルで動作確認したときと同様、以下のようなアスキーアートが表示されれば、アプリケーションが正常に動作しています。

```
 ______
< Moo! >
 ------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||--WWW |
                ||     ||
```

おめでとうございます。これで、OKEクラスターで実際にアプリケーションを動かすことができました！

3.Kubernetes上のオブジェクトの確認
------------------------------
ここからは、先ほどデプロイしたサンプルアプリケーションを利用してKubernetes上のオブジェクトを確認しながら、Kubernetesの基本的な特徴をみていきます。  
まずは、Depoymentからです。 

### 3.1. Deploymentオブジェクトの確認
Deploymentは、Podのレプリカ数（冗長構成でのPodの数）や、Podが内包するコンテナの指定など、動作させたいコンテナに関連する構成情報を定義するオブジェクトです。  
ここまでの手順で、Deploymentオブジェクトをクラスター上に作成済みであり、その事によって、サンプルアプリケーションがクラスタで動作しています。

では、Deploymentオブジェクトの情報を確認してみましょう。クラスターに存在するDeploymentの一覧を取得するには以下のコマンドを実行します。

```
kubectl get deployments
```
```
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
cowweb   2/2     2            2           3m53s
```

先に作成したcowwebという名前のDeploymentがあることがわかります。DESISRED, CURRENTなどの値が2となっているのは、2つのPodを動かすように指定しており、その指定通りにPodが可動していることを表しています。

このDeploymentの情報をもっと詳しく調べるには、以下のコマンドを実行します。

```
kubectl describe deployments/cowweb
```
```
Name:               cowweb
Namespace:          handson-030
CreationTimestamp:  Thu, 31 Jan 2019 17:34:44 +0000
Labels:             <none>
Annotations:        deployment.kubernetes.io/revision: 1
...（中略）...
NewReplicaSet:   cowweb-57885b669c (2/2 replicas created
Events:
  Type    Reason             Age   From                   Messag
  ----    ------             ----  ----                   ------
  Normal  ScalingReplicaSet  23m   deployment-controller  Scaled up replica set cowweb-57885b669c to 2
```

このDeploymentに関する様々な情報が表示されますが、特によく参照するのは、最後のEvents以下に表示される内容です。

これは、このPodにまつわって発生した過去のイベントが記録されているもので、Podが正常に起動しなかったときなど、特にトラブルシュートの場面で手がかりとなる情報を得るのに役立ちます。

### 3.2. Podの標準出力の表示
ここからは、Podオブジェクトについてみていきます。  
まず、Podの情報を標準出力を表示するなどして確認してみます。  
Kubernetes上で動作するアプリケーションの動作状況を確認する上で最もシンプルな方法は、Podの標準出力確認することです。Podの標準出力を表示するには、以下のコマンドを実行します。

    kubectl logs [Pod名]

ここで指定するPod名は、Podの一覧を表示して表示される2つのPodのうちのどちらかを指定してください。

```
kubectl get pods
```
```
NAME                      READY   STATUS    RESTARTS   AGE
cowweb-57885b669c-9dzg4   1/1     Running   0          43m
cowweb-57885b669c-r7l4g   1/1     Running   0          43m
```

この場合、例えば以下のようなコマンドとなります。

```
kubectl logs cowweb-57885b669c-9dzg4
```
```
...（中略）...
2022.08.25 05:09:44 INFO com.oracle.jp.cowweb.CowsayResource Thread[helidon-server-1,5,server]: I'm working...

2022.08.25 05:09:44 INFO com.oracle.jp.cowweb.CowsayResource Thread[helidon-server-2,5,server]: I'm working...

2022.08.25 05:09:49 INFO com.oracle.jp.cowweb.CowsayResource Thread[helidon-server-3,5,server]: I'm working...

2022.08.25 05:09:49 INFO com.oracle.jp.cowweb.CowsayResource Thread[helidon-server-4,5,server]: I'm working...

2022.08.25 05:09:54 INFO com.oracle.jp.cowweb.CowsayResource Thread[helidon-server-1,5,server]: I'm working...
```

これが、Podの標準出力の内容を表示した結果です。Kubernetesはクラスター内で動作するコンテナに対して、定期的に死活確認を行っています。このサンプルアプリケーションでは、死活監視のリクエストが来たときに上記のようなログを出力するように実装してあります。

{% capture notice %}**コンテナアプリケーションの死活監視について**  
コンテナの死活監視の機能はlivenessProbeと呼ばれます。  
死活確認の手段としては、以下の3通りの方法がサポートされています。

1) 特定のエンドポイントにHTTP GETリクエストを送信する  
2) 所定のコマンドを実行する  
3) TCP Socketのコネクションの生成を行う  

また、Podの起動時にも、コンテナの起動状態をチェックするために同様の確認が行われます。  
サポートされるチェックの手段はlivenessProbeと同じですが、こちらはreadinessProbeと呼ばれます。{% endcapture %}
<div class="notice--info">
  {{ notice | markdownify }}
</div>

#### 3.2.1. Podの環境変数の確認
Podに設定されている環境変数を確認するには、Pod内にアクセスして``env``コマンドを実行する必要があります。

まず、Pod内から任意のコマンドを実行するには``kubectl exec``コマンドを用います。

    kubectl exec [Pod名] -- [実行したいコマンド]

[実行したいコマンド]に``env``を当てはめて実行すると、指定したPod内でそれが呼び出され、環境変数を出力することができます。

    kubectl exec [Pod名] -- env

``kubectl exec``を利用すると、Podのシェルに入ることも可能です。

    kubectl exec -it [Pod名] -- /bin/sh

**`kubectl exec`コマンドについて**  
``kubectl exec``を利用すると、任意のコンテナをクラスター内に立ち上げて、そのコンテナのシェルを利用することができます。このテクニックはトラブルシューティングの場面で有用です。
例えば、クラスターで動作するアプリに期待通りにアクセス出来ないような状況において、クラスター内からcurlを実行して疎通確認を行うことで、問題の切り分けに役立てるといったことが可能です。
{: .notice--info}

4.アプリケーションのスケーリング
---------------------------------
ここでは、Deploymentに対してレプリカの数を指定することによって、Podのスケールアウト/インを試してみます。

### 4.1. スケールアウト
Deploymentに対してレプリカの数を指定することによって、そのDeploymentが管理するPodの数を増減することができます。

レプリカの数を変更するには、``kubectl scale``コマンドを使用します。以下のように実行することで、cowwebのPodを管理するDeploymentに対して、レプリカ数を4にするよう指示します。

    kubectl scale deployments/cowweb --replicas=4

Podの一覧を表示してみます。

    kubectl get pods

すると、4つのPodが構成されていることがわかります。

    NAME                      READY   STATUS    RESTARTS   AGE
    cowweb-57885b669c-4h5l4   0/1     Running   0          7s
    cowweb-57885b669c-9dzg4   1/1     Running   0          1h
    cowweb-57885b669c-hxvpz   0/1     Running   0          7s
    cowweb-57885b669c-r7l4g   1/1     Running   0          1h

上の例では、一部のPodは起動中の状態です。少し時間が経過すると全てのPodのSTATUSがRunningになります。

### 4.2. Serviceによるルーティングの様子の確認
この時点で、クラスターには4つのcowwebのPodがデプロイされている状態です。この状態で、Podに対するアクセスが負荷分散される様子を確認してみましょう。

cowwebには、環境変数の変数名を指定することで、その値を答えてくれる仕掛けがしてあります。これを利用してPodのホスト名を応答させることで、負荷分散の動きを見てみます。

動作確認で実行したcurlコマンドのURLに``?say=HOSTNAME``というクエリを追加して、以下のようなコマンドを実行してみてください。

    curl "http://[ロードバランサーのIP]/cowsay/say?say=HOSTNAME"

このコマンドを何度か繰り返すと、その度に異なるホスト名が返ってくることがわかります。

```
 _________________________
< cowweb-57885b669c-r7l4g >
 -------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```
```
 _________________________
< cowweb-57885b669c-hxvpz >
 -------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

### 4.3. スケールイン
Pod数を縮小することも当然ながら可能です。スケールアウトで行ったように、``kubectl scale``コマンドでレプリカ数を指定して減らすことが可能です。

他の方法として、Deploymentのmanifestファイルで現在より少ないreplica数を記述しておき、そのmanifestをクラスターに適用することで同様のことが可能になります。

最初にサンプルアプリケーションをデプロイしたときに利用したmanifestファイルには、レプリカ数に2を指定してありますので、これを適用することで4->2にスケールインしてみます。

    kubectl apply -f ./kubernetes/cowweb.yaml

Podの一覧を表示すると、2個に減っていることがわかります。

```
kubectl get pods
```
```
NAME                      READY   STATUS    RESTARTS   AGE
cowweb-57885b669c-9dzg4   1/1     Running   0          1h
cowweb-57885b669c-r7l4g   1/1     Running   0          1h
```

**スケールイン/アウトについて**  
現実の場面では、スケールアウト・インのような運用操作は、全てmanifestを編集してそれを適用するオペレーションとすることをおすすめします。manifestをソースコード管理システムで管理することによって、クラスターの構成変更をコードとして追跡可能になるためです。
{: .notice--info}

5.Podの自動復旧
-----------------
Kubernetesには、障害が発生してPodがダウンしたときに、自動的に新たなPodを立ち上げ直す機能が備わっています。

Podを削除することによって障害に相当する状況を作り、自動復旧される様子を確認してみましょう。

Podを削除するには、以下のコマンドを実行します。

    kubectl delete [Pod名]

例えばこのようなコマンドとなります（実際のPod名は、``kubectl get pods``コマンドで確認してください）。

    kubectl delete pod cowweb-57885b669c-9dzg4

この後すぐにPodの一覧を表示すると、削除したPodのPod名はなく、新しい名前のPodが起動していることがわかります。

```
NAME                      READY   STATUS    RESTARTS   AGE
cowweb-57885b669c-5mgrb   0/1     Running   0          7s    <- 新たに起動したPod
cowweb-57885b669c-r7l4g   1/1     Running   0          1h
```

DeploymentオブジェクトによってPod数を2個に指定されています。Podが削除されて1つになると、Kubernnetesは指定された数との差分を検知して自動的にPodを立ち上げてくれます。


以上で本チュートリアルは終了です。
