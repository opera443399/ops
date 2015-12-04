# coding: utf-8
from __future__ import unicode_literals
from django.utils.encoding import python_2_unicode_compatible

import datetime

from django.db import models
from django.utils import timezone

# Create your models here.


@python_2_unicode_compatible
class Question(models.Model):
    question_text = models.CharField('问题', max_length=200)
    pub_date = models.DateTimeField('发布日期')

    def __str__(self):              # __unicode__ on Python 2
        return self.question_text

    def was_published_recently(self):
        now = timezone.now()
        return now - datetime.timedelta(days=1) <= self.pub_date <= now
    was_published_recently.admin_order_field = 'pub_date'
    was_published_recently.boolean = True
    was_published_recently.short_description = 'Published recently?'


@python_2_unicode_compatible
class Choice(models.Model):
    question = models.ForeignKey(Question)
    choice_text = models.CharField('选项', max_length=200)
    votes = models.IntegerField('票数', default=0)

    def __str__(self):              # __unicode__ on Python 2
        return self.choice_text
