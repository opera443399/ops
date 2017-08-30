FROM python:2.7
MAINTAINER PC

ADD . /code
WORKDIR /code
RUN pip install -r requirements.txt
EXPOSE 5000
CMD python app.py

HEALTHCHECK --interval=10s --timeout=2s --retries=3 \
  CMD curl --silent --fail localhost:5000 || exit 1
