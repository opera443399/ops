vim:
  pkg.installed:
    - name: {{ pillar['pkgs']['vim'] }}

/root/.vimrc:
  file.managed:
    - source: salt://conf.d/vim/vimrc
    - require:
      - pkg: vim
