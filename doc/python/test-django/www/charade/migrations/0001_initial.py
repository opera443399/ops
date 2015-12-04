# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='GameScoreBoard',
            fields=[
                ('id', models.AutoField(verbose_name='ID', serialize=False, auto_created=True, primary_key=True)),
                ('amount', models.IntegerField(default=0, verbose_name='\u5355\u8bcd\u603b\u6570')),
                ('scores', models.IntegerField(default=0, verbose_name='\u603b\u5f97\u5206')),
                ('dt_start', models.DateTimeField(auto_now_add=True, verbose_name='\u5f00\u59cb\u65f6\u95f4')),
                ('dt_end', models.DateTimeField(auto_now=True, verbose_name='\u7ed3\u675f\u65f6\u95f4')),
            ],
        ),
        migrations.CreateModel(
            name='GameTemporaryTable',
            fields=[
                ('id', models.AutoField(verbose_name='ID', serialize=False, auto_created=True, primary_key=True)),
                ('en', models.CharField(max_length=200, verbose_name='en')),
                ('zh', models.CharField(max_length=100, verbose_name='\u4e2d\u6587')),
                ('exp', models.TextField(null=True, verbose_name='\u89e3\u91ca')),
                ('scores', models.IntegerField(default=0, verbose_name='\u5f97\u5206')),
                ('used', models.IntegerField(default=0, verbose_name='used')),
                ('board', models.ForeignKey(to='charade.GameScoreBoard')),
            ],
        ),
        migrations.CreateModel(
            name='Vocabulary',
            fields=[
                ('id', models.AutoField(verbose_name='ID', serialize=False, auto_created=True, primary_key=True)),
                ('en', models.CharField(unique=True, max_length=200, verbose_name='en')),
                ('zh', models.CharField(max_length=100, verbose_name='\u4e2d\u6587')),
                ('exp', models.TextField(null=True, verbose_name='\u89e3\u91ca')),
                ('dt', models.DateTimeField(auto_now_add=True, verbose_name='\u65f6\u95f4')),
            ],
        ),
    ]
