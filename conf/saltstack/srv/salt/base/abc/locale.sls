## update i18n settings
# 
# via pc @ 2015/8/19

/etc/sysconfig/i18n:
  file.managed:
    - source: salt://conf.d/locale/sysconfig_i18n

