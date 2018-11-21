/etc/yum.repos.d/local-office.repo:
  file.managed:
    - name: /etc/yum.repos.d/local-office.repo
    - source: salt://conf.d/yum/local-office.repo
    - mode: 644
