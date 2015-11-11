## 此处列出主机上线时需要的软件包
#
common-pkgs:
  pkg.installed:
    - pkgs:
      - lrzsz
      - wget
      - curl
      - rsync
      - screen
      - dos2unix
      - tree
      - ntp
      - bind-utils
      - nc
      - telnet
      - git  

## 此处列出需要update的软件包
#
up2date-pkgs:
  pkg.latest:
    - pkgs:
      - bash
      - openssl
