# django_project_normalization

正規化ハンズオンで作成したテーブル定義を Gjango で実装したサンプルコード

## 動作環境

Python

```
$ python3 --version
Python 3.9.0
```

Django

```
$ python3 -m django --version
3.1.7
```

## 作成メモ

### Create Project

```
$ django-admin startproject djang_project
```

### Create App

```
$ python3 manage.py startapp normalization
```

### Initial Migration

管理画面用のマイグレーション

```
$ python3 manage.py migrate
```

### Create SuperUser

管理画面のユーザ作成。パスワードは`hogehoge`で作成

```
$ python3 manage.py createsuperuser
Username (leave blank to use 'h-miura'): admin
Email address: hoge@hoge.com
Password:
Password (again):
The password is too similar to the email address.
Bypass password validation and create user anyway? [y/N]: y
Superuser created successfully.
```

## run server

ビルトインサーバの起動。PORT は任意で指定(例は`9999`を指定)

```
$ python3 manage.py runserver 9999
```

## マイグレーション

今回のテーブルのマイグレーション。`models.py`に対してて定義したら都度行う

作成

```
$ python3 manage.py makemigrations normalization
Migrations for 'normalization':
  normalization/migrations/0001_initial.py
    - Create model Customers
    - Create model Items
    - Create model Orders
    - Create model Order_details
    - Create constraint order_id_item_id_unique on model order_details
```

適用

```
$ python3 manage.py migrate
Operations to perform:
  Apply all migrations: admin, auth, contenttypes, normalization, sessions
Running migrations:
  Applying normalization.0001_initial... OK
```

## 管理画面に追加

管理画面からテーブル操作を行えるよう`admin.py`に都度追加(以下例)

```
from django.contrib import admin
from .models import Customers, Items, Orders, Order_details

admin.site.register(Customers)
admin.site.register(Items)
admin.site.register(Orders)
admin.site.register(Order_details)
```
