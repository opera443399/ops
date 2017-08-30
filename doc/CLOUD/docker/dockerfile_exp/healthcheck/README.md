[example]
image name: healthcheck
info: build flask from default image in docker with healthcheck instruction.

# instruction
HEALTHCHECK --interval=10s --timeout=2s --retries=3 \
  CMD curl --silent --fail localhost:5000 || exit 1
  
# output like this:
127.0.0.1 - - [30/Aug/2017 07:57:40] "GET / HTTP/1.1" 200 -
172.17.0.1 - - [30/Aug/2017 07:57:44] "GET / HTTP/1.1" 200 -
127.0.0.1 - - [30/Aug/2017 07:57:50] "GET / HTTP/1.1" 200 -
127.0.0.1 - - [30/Aug/2017 07:58:00] "GET / HTTP/1.1" 200 -
127.0.0.1 - - [30/Aug/2017 07:58:10] "GET / HTTP/1.1" 200 -
127.0.0.1 - - [30/Aug/2017 07:58:21] "GET / HTTP/1.1" 200 -

docker will run healthcheck-cmd every 10s