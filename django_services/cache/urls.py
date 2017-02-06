from django.conf.urls import url

from . import views

urlpatterns = [
    url(r'^$', views.index, name="index"),
    url(r'^cache/(?P<filename>.*)$', views.cache, name="cache")
]