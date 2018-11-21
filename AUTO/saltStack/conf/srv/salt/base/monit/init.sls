monit:
  pkg.installed:
## for local-office.repo
#
    - fromrepo: office
    - name: monit
    - skip_verify: True
    - refresh: True
    - version: 5.14-1.el6

  service.running:
    - enable: True

/etc/monit.d/monit-mail.conf:
  file.managed:
    - source: salt://conf.d/monit/monit-mail.conf
    - require:
      - pkg: monit

/etc/monit.d/salt-minion.conf:
  file.absent
#  file.managed:
#    - source: salt://conf.d/monit/salt-minion.conf
#    - require:
#      - pkg: monit

