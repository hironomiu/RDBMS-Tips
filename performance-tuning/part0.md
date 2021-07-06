# RDBMS パフォーマンスチューニング入門 Part0

## 準備

[part1 で利用するテーブルデータ:GitHub/SQL-DATA](https://github.com/hironomiu/SQL-DATA)

[MySQL:GitHub/Docker-DockerCompose-Training/recipe-x](https://github.com/hironomiu/Docker-DockerCompose-Training/tree/main/recipe-x)

vim のインストール（任意）

```
docker container exec -it mysqld bash

apt install -y vim
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
