from django.conf.urls import url

from . import views

urlpatterns = [
    url(r'^$', views.index, name="index"),
    url(r'^cache/(.*)$', views.get_resource, name="cache"),
    url(r'^wcs', views.wcs, name="wcs")
]
