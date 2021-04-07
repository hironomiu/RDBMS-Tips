from django.db import models
from django.utils import timezone


class Customers(models.Model):
    name = models.CharField('受注先', max_length=100)
    address = models.CharField('受注先住所', max_length=100)
    created_at = models.DateTimeField('作成日時', default=timezone.now)
    updated_at = models.DateTimeField('更新日時', default=timezone.now)

    class Meta:
        db_table = "customers"

    def __str__(self):
        return self.name


class Items(models.Model):
    name = models.CharField('商品', max_length=100)
    price = models.IntegerField('単価')
    created_at = models.DateTimeField('作成日時', default=timezone.now)
    updated_at = models.DateTimeField('更新日時', default=timezone.now)

    class Meta:
        db_table = "items"

    def __str__(self):
        return self.name


class Orders(models.Model):
    order_date = models.DateField('受注日', default=timezone.now)
    customer = models.ForeignKey(
        Customers, verbose_name='受注先', on_delete=models.PROTECT,
    )
    created_at = models.DateTimeField('作成日時', default=timezone.now)
    updated_at = models.DateTimeField('更新日時', default=timezone.now)

    class Meta:
        db_table = "orders"

    def __str__(self):
        return f'受注番号:{self.id}-受注日:{self.order_date}'


class Order_details(models.Model):
    order = models.ForeignKey(
        Orders, verbose_name='受注ID', on_delete=models.PROTECT,
    )
    item = models.ForeignKey(
        Items, verbose_name='商品ID', on_delete=models.PROTECT,
    )
    item_quantity = models.IntegerField('数量')
    created_at = models.DateTimeField('作成日時', default=timezone.now)
    updated_at = models.DateTimeField('更新日時', default=timezone.now)

    class Meta:
        db_table = "order_details"
        constraints = [
            models.UniqueConstraint(
                fields=["order_id", "item_id"],
                name="order_id_item_id_unique"
            ),
        ]

    def __str__(self):
        return f'id:{self.id}-受注番号:{self.order_id}-商品番号:{self.item_id}'
