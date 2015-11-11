{% if grains['virtual'] == 'physical' or (grains['virtual'] == 'xen' and grains['virtual_subtype'] == 'Xen Dom0') %}
dellpkgs:
  pkg.installed:
    - pkgs:
      - srvadmin-all
    - refresh: True

/usr/bin/omreport:
  file.symlink:
    - target: /opt/dell/srvadmin/sbin/omreport
    - require:
      - pkg: dellpkgs

/usr/bin/omconfig:
  file.symlink:
    - target: /opt/dell/srvadmin/sbin/omconfig
    - require:
      - pkg: dellpkgs

{% for ss in 'dataeng','instsvcdrv' %}
{{ ss }}:
  service:
    - running
    - enable: True
    - watch:
      - pkg: dellpkgs
{% endfor %}

sblim-sfcb:
  service.dead:
    - enable: False

{% endif %}
