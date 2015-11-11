
## 此处列出需要的软件包
#
python-pip:
  pkg.installed:
    - name: python-pip
    - require_in:
      -file: pip-pkgs

pip-pkgs:
  pip.installed:
    - names: 
      - virtualenvwrapper
      - pwgen

/usr/bin/sendEmail:
  file.managed:
    - source: salt://conf.d/ops/bin/sendEmail
    - mode: 755

/usr/bin/pw:
  file.managed:
    - source: salt://conf.d/ops/bin/pw
    - mode: 755

/usr/bin/randchars:
  file.managed:
    - source: salt://conf.d/ops/bin/randchars.py
    - mode: 755

