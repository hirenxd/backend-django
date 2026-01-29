from django.urls import path
from . import views

from django.http import HttpResponse

from django.http import JsonResponse


def health(request):
    return HttpResponse("OK", status=200)


def health_api(request):
    return JsonResponse({"status": "oki", "service": "diary-backend"})


urlpatterns = [
    path("", views.home_view, name="home"),
    path("health/", health),
    path("test/", health_api),
    path("register/", views.register_view, name="register"),
    path("login/", views.login_view, name="login"),
    path("logout/", views.logout_view, name="logout"),
    path("add-entry/", views.add_entry_view, name="add_entry"),
    path("delete-entry/<int:entry_id>/", views.delete_entry_view, name="delete_entry"),
]
