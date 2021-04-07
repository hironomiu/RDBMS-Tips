from django.contrib import admin
from .models import Customers, Items, Orders, Order_details

admin.site.register(Customers)
admin.site.register(Items)
admin.site.register(Orders)
admin.site.register(Order_details)
