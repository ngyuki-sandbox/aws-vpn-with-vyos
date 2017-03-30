# AWS ハードウェア VPN に VyOS から接続する

AWS を今後も使っていくならそのうち VPN で繋ぎたくなることもあるかと思ったので、試してみました。

## はじめに

AWS に VPN で接続するにはいくつか方法があります。

- AWS ハードウェア VPN
    - IPSec VPN
    - AWS 側にマネージドな VPN ゲートウェイが作られる
    - オンプレ側の VPN 機器から AWS の VPN ゲートウェイに接続
    - 0.048 USD/時間 (t2.small と t2.medium の間ぐらいの値段)
- AWS Direct Connect
    - 専用線とか IP-VPN とかの閉域網な VPN
    - べらぼうに高い
- ソフトウェア VPN
    - ソフトウェア VPN のインスタンスを EC2 で作る
    - オンプレでもソフトウェア VPN のサーバを立てて EC2 に繋ぐ
    - OpenVPN とか

（AWS VPN CloudHub はよくわからん）

**参考: http://docs.aws.amazon.com/ja_jp/AmazonVPC/latest/UserGuide/vpn-connections.html**

「AWS Direct Connect」ちょっと試すのは無理があるし、「ソフトウェア VPN」は面白みがないので、「AWS ハードウェア VPN」を試してみます。

いきなり社内のサーバと VPN 繋ぐのはどうかと思ったので、AWS のオレゴンリージョンを社内に見立てて IPSec VPN が可能なインスタンスを EC2 で構築し、東京リージョンの VPN ゲートウェイに接続して、オレゴン～東京間で VPN します。

## VPC とか EC2 とかの準備

サブネットの構成を次の通りに作成します。

| Region    | VPC               | Availability Zone | Subnet  
| ---       | ---               | ---               | ---
| Oregon    | 192.168.8.0/24    | us-west-2a        | 192.168.8.0/25
| Tokyo     | 10.8.0.0/24       | ap-northeast-1a   | 10.8.0.0/25
|           |                   | ap-northeast-1c   | 10.8.0.128/25

それぞれインターネットゲートウェイを作成して VPC にアタッチします。

東京リージョンで下記の通りに VPN 関係のリソースを作成します。

- カスタマーゲートウェイを作成します
    - ルーティングは「静的」で良いです
    - IP アドレスは↑で取得した Elastic IP です
- 仮想プライベートゲートウェイを作成します
    - 作成したら VPC にアタッチします
- VPN 接続を作成します
    - ↑で作成したカスタマーゲートウェイや仮想プライベートゲートウェイを選択します
    - ルーティングオプションは「動的」にします
    - 作成したら「設定のダウンロード」で「Vyatta」用の設定をダウンロードしておきます

それぞれの VPC でセキュリティグループを作ります。相互に接続できるように相手方の VPC からのアクセスを許可するので、下記の要領でインバウンドルールを作成します。

| Region    | Type        | Protocol | Port Range | Source
| ---       | ---         | ---      | ---        | ---
| Oregon    | ALL Traffic | ALL      | ALL        | sg-xxxxxxxx (同じセキュリティグループ)
| Oregon    | ALL Traffic | ALL      | ALL        | 10.8.0.0/24   
| Oregon    | SSH (22)    | TCP (6)  | 22         | MyIP
| Tokyo     | ALL Traffic | ALL      | ALL        | sg-xxxxxxxx (同じセキュリティグループ)
| Tokyo     | ALL Traffic | ALL      | ALL        | 192.168.8.0/24  
| Tokyo     | SSH (22)    | TCP (6)  | 22         | MyIP

オレゴンリージョンで VyOS のインスタンスにつけるための Elastic IP を取得します。

EC2 インスタンスを立ち上げます。

.

.

.


・・・めんどくさくなってきたので後は Terraform で・・・

## Terraform

ここまでの作業をさくっとやるための Terraform のテンプレートを用意しました。

- https://github.com/ngyuki-sandbox/aws-vpn-with-vyos

`terraform.tfvars.example` をコピーして `terraform.tfvars` を作ります。

```sh
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` を開いて変数を設定します。

- `my_key_name`
    - EC2 のキーペア
    - オレゴンと東京で同じ名前で登録されている必要あり
- `my_cidr_blocks`
    - SSH 接続を許可するアドレス
    - いわゆる MyIP です

terraform を実行して VPC や EC2 をサクッと準備します。

```sh
terraform plan
terraform apply
```

## VyOS の設定

VyOS に SSH でログインします。

```sh
ssh -l vyos xxx.xxx.xxx.xxx
```

ちょっと古いので最新版にアップデートしてリブートします。

```sh
add system image http://packages.vyos.net/iso/release/1.1.7/vyos-1.1.7-amd64.iso
show system image
reboot
```

東京リージョンの VPC の「VPN 接続」から、「設定のダウンロード」で「Vyatta」用の設定をダウンロードします。

ダウンロードした設定の下記を書き換えます。

```sh
# local-address の部分を VyOS のプライベートアドレスに書き換える（２箇所）
set vpn ipsec site-to-site peer xxx.xxx.xxx.xxx local-address '192.168.8.10'

# network の部分を VyOS が属するネットワークに書き換える（２箇所）
set protocols bgp 65000 network 192.168.8.0/25
```

もう一度 VyOS に SSH でログインします。

```sh
ssh -l vyos xxx.xxx.xxx.xxx
```

コンフィグレーションモードに入って、ダウンロードした設定をぺたぺた貼り付けます。

```sh
configure

# はりつけ
```

コミットして保存します。

```sh
commit
save
exit
```

他の EC2 インスタンスにログインして、相互にアクセスできることを確認します。

```sh
# オレゴンのサーバにログイン
ssh -l centos xxx.xxx.xxx.xxx

  # 東京のプライベートアドレスに ping とか ssh できる？
  ping 10.8.0.100
  ping 10.8.0.200
  ssh 10.8.0.100 uname -n
  ssh 10.8.0.200 uname -n

  # 逆方向もできる？
  ssh -A 10.8.0.100
    ping 192.168.8.20
    ssh 192.168.8.20 uname -n
  exit
  ssh -A 10.8.0.200
    ping 192.168.8.20
    ssh 192.168.8.20 uname -n
  exit

exit
```

## 後始末

お金がもったいないのでさくっと削除します。

```sh
terraform destroy
```

## 参考

- http://docs.aws.amazon.com/ja_jp/AmazonVPC/latest/UserGuide/VPC_VPN.html
