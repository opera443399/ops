/etc/resolv.conf:
  file.managed:
    {% if grains['id'] == 'tvm-yum' %}
    - source: salt://conf.d/resolv/server.conf
    {% else %}
    - source: salt://conf.d/resolv/client.conf
    {% endif %}
