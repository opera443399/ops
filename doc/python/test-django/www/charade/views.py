from django.shortcuts import get_object_or_404, render
from django.http import HttpResponseRedirect, HttpResponse
from django.core.urlresolvers import reverse
from django.views import generic
from django.core.paginator import Paginator, EmptyPage, PageNotAnInteger
from django.utils import timezone

from .models import Vocabulary, GameTemporaryTable, GameScoreBoard

# Create your views here.
def index(request):
    return HttpResponseRedirect(reverse('charade:game_ready'))

def game_ready(request):
    try:
        amount = int(request.POST['amount'])
    except (KeyError):
        msgs = 'How many words you want to charade?'
        context = {'msgs': msgs}
        return render(request, 'charade/ready.html')
    else:
        return HttpResponseRedirect(reverse('charade:game_set', args=(amount,)))


def game_set(request, amount=20):
    """fetch some words into temporary table"""
    GameTemporaryTable.objects.all().delete()
    tmp_word_list = Vocabulary.objects.order_by('?')[:amount]
    tmp_board = GameScoreBoard.objects.create(amount=amount)
    tmp_table = GameScoreBoard.objects.get(pk=tmp_board.id)
    for w in tmp_word_list:
        tmp_table.gametemporarytable_set.create(en=w.en, zh=w.zh, exp=w.exp)

    return HttpResponseRedirect(reverse('charade:game_play', args=(tmp_board.id,)))


def game_play(request, board_id):
    """fetch one row """
    tmp_table = GameScoreBoard.objects.get(pk=board_id)
    tmp_word_list = tmp_table.gametemporarytable_set.exclude(used=1).order_by('?')[:1]
    if tmp_word_list:
        context = {'word_list': tmp_word_list}
    else:
        sum_scores = 0
        all_used_words = tmp_table.gametemporarytable_set.filter(used=1)
        for w in all_used_words:
            sum_scores += w.scores
        tmp_table.scores = sum_scores
        tmp_table.dt_end = timezone.now()
        tmp_table.save()
        msgs = 'team: {0}, scores: {1}'.format(board_id, sum_scores)
        context = {'msgs': msgs}
    return render(request, 'charade/play.html', context)


def game_score(request, wid):
    tmp_table = GameTemporaryTable.objects.get(id=wid)
    try:
        s = int(request.POST['scores'])
    except (KeyError):
        # Redisplay the form.
        tmp_word_list = [tmp_table]
        return render(request, 'charade/play.html', {
            'word_list': tmp_word_list,
            'msgs': "You didn't select a choice.",
        })
    else:
        tmp_table.scores = s
        tmp_table.used = 1
        tmp_table.save()
        return HttpResponseRedirect(reverse('charade:game_play', args=(tmp_table.board_id,)))
    
def game_board(request):
    """Return some words"""
    game_score_board = GameScoreBoard.objects.order_by('-dt_start')
    paginator = Paginator(game_score_board, 5) # show 5 rows per page
    page = request.GET.get('page')
    try:
        board = paginator.page(page)
    except PageNotAnInteger:
        board = paginator.page(1)
    except EmptyPage:
        board = paginator.page(paginator.num_pages)
    context = {'board': board}

    return render(request, 'charade/board.html', context)

class Explanation(generic.DetailView):
    model = GameTemporaryTable
    template_name = 'charade/explanation.html'
    

