pkgs:
  {% if grains['os_family'] == 'RedHat' %}
  vim: vim-enhanced
  apache: httpd
  {% elif grains['os_family'] == 'Debian' %}
  vim: vim
  apache: apache2
  {% elif grains['os'] == 'Arch' %}
  vim: vim
  apache: httpd
  {% endif %}
