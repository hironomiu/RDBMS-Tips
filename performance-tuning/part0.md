# RDBMS パフォーマンスチューニング入門 Part0

## 準備

### データの準備

[part1 で利用するテーブルデータ:GitHub/SQL-DATA](https://github.com/hironomiu/SQL-DATA)を clone する

### Docker

Dockerfile を作成し構築する場合はこちら[MySQL:GitHub/Docker-DockerCompose-Training/recipe-mysql](https://github.com/hironomiu/Docker-DockerCompose-Training/tree/main/recipe-mysql)

コマンドで構築する場合はこちら[MySQL:GitHub/Docker-DockerCompose-Training/recipe-x](https://github.com/hironomiu/Docker-DockerCompose-Training/tree/main/recipe-x)

my.cnf を編集するため vim のインストール

```
docker container exec -it mysqld bash

apt install -y vim

exit
```

### DB の作成

bash モードで接続

```
docker container exec -it mysqld bash
```

パスワードについて適時変更（値、直接入力せずなど）すること

```
mysql -u root -pmysql -e "create database part1;"
```

bash モードから exit

```
exit
```

### データの投入

※ 以下実行の際に MySQL Client が必要

※ [part1 で利用するテーブルデータ:GitHub/SQL-DATA](https://github.com/hironomiu/SQL-DATA)を clone したディレクトリ直下に移動し以下を実行

※ データの投入はマシンによって 30 分以上掛かるため注意

linux

パスワードについて適時変更（値、直接入力せずなど）すること

```
zcat users.dump.gz                  | mysql -u root -pmysql -h127.0.0.1 part1
zcat messages.dump.gz               | mysql -u root -pmysql -h127.0.0.1 part1
```

mac

パスワードについて適時変更（値、直接入力せずなど）すること

```
gzcat users.dump.gz                  | mysql -u root -pmysql -h127.0.0.1 part1
gzcat messages.dump.gz               | mysql -u root -pmysql -h127.0.0.1 part1
```
