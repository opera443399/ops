from django.contrib import admin

from .models import Vocabulary, GameTemporaryTable, GameScoreBoard

# Register your models here.

class VocabularyAdmin(admin.ModelAdmin):
    date_hierarchy = 'dt'
    list_display = ('en', 'zh', 'exp', 'dt')
    fieldsets = [
        ('word', {'fields': ['en', 'zh']}),
        ('explanation', {'fields':['exp']}),
    ]
    list_filter = ['dt']
    search_fields = ['en']


class GameTemporaryTableInline(admin.TabularInline):
    model = GameTemporaryTable
    extra = 0

class GameScoreBoardAdmin(admin.ModelAdmin):
    fieldsets = [
        (None,               {'fields': ['amount']}),
        (None,               {'fields': ['scores']}),
    ]
    inlines = [GameTemporaryTableInline]
    list_display = ('id', 'amount', 'scores', 'dt_start', 'dt_end')


admin.site.register(Vocabulary, VocabularyAdmin)
admin.site.register(GameScoreBoard, GameScoreBoardAdmin)
