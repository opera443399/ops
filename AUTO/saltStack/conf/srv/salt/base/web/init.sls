apache:
  pkg.installed:
    - name: {{ pillar['pkgs']['apache'] }}
  service.running:
    - name: {{ pillar['pkgs']['apache'] }}
    - enable: True
    - require:
        - pkg: apache
