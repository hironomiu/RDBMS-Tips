# RDBMS パフォーマンスチューニング入門 Part0

## 準備

[part1 で利用するテーブルデータ:GitHub/SQL-DATA](https://github.com/hironomiu/SQL-DATA)

[MySQL:GitHub/Docker-DockerCompose-Training/recipe-x](https://github.com/hironomiu/Docker-DockerCompose-Training/tree/main/recipe-x)

my.cnf を編集するため vim のインストール

```
docker container exec -it mysqld bash

apt install -y vim

exit
```

DB の作成

パスワードについて適時変更（値、直接入力せずなど）すること

```
docker container exec -it mysqld bash

mysql -u root -pmysql

create database part1;

exit;

exit
```

データの投入(linux)

パスワードについて適時変更（値、直接入力せずなど）すること

```
zcat users.dump.gz                  | mysql -u root -pmysql -h127.0.0.1 part1
```

データの投入(max)

パスワードについて適時変更（値、直接入力せずなど）すること

```
gzcat users.dump.gz                  | mysql -u root -pmysql -h127.0.0.1 part1
```
