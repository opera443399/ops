## 使用cron.file这个方法来控制，可以替换全部的crontab内容
cron-ntpdate-office:
  cron.file:
    - name: salt://conf.d/crontab/client.conf
