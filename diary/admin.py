from django.contrib import admin
from .models import DiaryEntry

@admin.register(DiaryEntry)
class DiaryEntryAdmin(admin.ModelAdmin):
    list_display = ['title', 'user', 'date', 'created_at']
    list_filter = ['date', 'user']
    search_fields = ['title', 'content']
