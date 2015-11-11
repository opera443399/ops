## 使用cron.present这个方法来控制，默认是追加到现有的crontab中
crontab-REPO-UPDATE:
  cron.present:
    - identifier: CRON-REPO-UPDATE
    - name: '/bin/bash /data/ops/bin/repo_update.sh >/tmp/repo_update.log 2>&1 &'
    - user: root
    - minute: '0'
    - hour: '12'
    - daymonth: '*'
    - month: '*'
    - dayweek: '*'

