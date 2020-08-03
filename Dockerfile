# pull repository
FROM alpine/git AS git-clone
RUN mkdir -p /app/src && \
    git clone https://github.com/limorton/vj4.git /app/src

# `stage-node` generates some files
FROM node:8-stretch AS stage-node
COPY --from=git-clone /app/src /app/src
WORKDIR /app/src

RUN npm install \
    && npm run build:production

# main
FROM python:3.6-alpine3.9
COPY --from=stage-node /app/src/vj4 /app/vj4
COPY --from=stage-node /app/src/LICENSE /app/src/README.md /app/src/requirements.txt /app/src/setup.py /app/
WORKDIR /app

RUN apk add --no-cache libmaxminddb \
        libmaxminddb-dev alpine-sdk git && \
    python -m pip install -r requirements.txt && \
    apk del --no-cache --purge \
        libmaxminddb-dev alpine-sdk git && \
    curl "https://cdn.vijos.org/fs/254b16ee0aff6a0a885b8265964939dffc413fdb" > GeoLite2-City.mmdb

ENV GIT_PYTHON_REFRESH=quiet
ENV VJ_LISTEN=http://0.0.0.0:8888

ADD docker-entrypoint.py /app/
ENTRYPOINT [ "python", "docker-entrypoint.py" ]

EXPOSE 8888
CMD [ "vj4.server" ]
