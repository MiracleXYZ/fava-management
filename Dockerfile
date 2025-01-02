FROM python:3.13-alpine

WORKDIR /app
ENV BEANCOUNT_FILE /bean/main.bean
COPY requirements.txt /app
COPY cargo-config /root/.cargo/config

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories && \
    apk add --update --no-cache  --virtual .build-deps gcc libc-dev libxml2-dev rust cargo python3-dev libxml2 libxslt-dev && \
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip install --no-cache-dir -r /app/requirements.txt && \
    apk del .build-deps

RUN apk add openssh git && \
    mkdir /root/.ssh

COPY . /app
COPY docker/prestart.sh /app/prestart.sh
COPY docker/* /docker/
ENV PYTHONPATH /bean

RUN yes | python3 manage.py collectstatic && \
    sed -i 's/DEBUG = True/DEBUG = False/g' management/settings.py

ENV WORKERS 2
ENTRYPOINT [ "/app/prestart.sh" ]
CMD ["gunicorn", "management.wsgi", "-w", "2", "-b", ":80"]
