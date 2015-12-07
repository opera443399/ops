from django.conf.urls import url
from . import views

urlpatterns = [
    # ex: /charade/
    url(r'^$', views.game_ready, name='game_ready'),
    # ex: /charade/set/10
    url(r'^set/(?P<amount>[0-9]+)/$', views.game_set, name='game_set'),
    # ex: /charade/set/10/play
    url(r'^set/(?P<board_id>[0-9]+)/play/$', views.game_play, name='game_play'),
    # ex: /charade/set/10/score
    url(r'^score/(?P<wid>[0-9]+)/$', views.game_score, name='game_score'),
    # ex: /charade/board
    url(r'^board/$', views.game_board, name='game_board'),
    # ex: /charade/explanation/11
    url(r'^explanation/(?P<pk>[0-9]+)/$', views.Explanation.as_view(), name='explanation'),
]
