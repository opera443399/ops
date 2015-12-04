# coding: utf-8
from __future__ import unicode_literals
from django.utils.encoding import python_2_unicode_compatible

import datetime

from django.db import models
from django.utils import timezone

# Create your models here.

@python_2_unicode_compatible
class Vocabulary(models.Model):
    en = models.CharField('en', max_length=200, unique=True)
    zh = models.CharField('中文', max_length=100)
    exp = models.TextField('解释', null=True)

    dt = models.DateTimeField('时间', auto_now_add = True)

    def __str__(self):
        return self.en

    def was_added_recently(self):
        now = timezone.now()
        return now - datetime.timedelta(days=1) <= self.dt <= now
        

@python_2_unicode_compatible
class GameScoreBoard(models.Model):
    amount = models.IntegerField('单词总数', default=0)
    scores = models.IntegerField('总得分', default=0)
    dt_start = models.DateTimeField('开始时间', auto_now_add = True)
    dt_end = models.DateTimeField('结束时间', auto_now = True)

    def __str__(self):
        return "小组 %s" % self.id

@python_2_unicode_compatible
class GameTemporaryTable(models.Model):
    board = models.ForeignKey(GameScoreBoard)
    en = models.CharField('en', max_length=200)
    zh = models.CharField('中文', max_length=100)
    exp = models.TextField('解释', null=True)
    scores = models.IntegerField('得分', default=0)
    used = models.IntegerField('used', default=0)


    def __str__(self):
        return self.en

