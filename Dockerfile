FROM alpine:3.17.1 AS alpine-lua

ENV LUA_VERSION="5.1.5"
ENV LUA_SHA1_CHECKSUM="b3882111ad02ecc6b972f8c1241647905cb2e3fc"

RUN set -ex \
    \
    && apk update \
    && apk upgrade \
    && apk add readline-dev \
    && apk add --no-cache --virtual .build-deps \
        make \
        gcc \
        libc-dev \
        ncurses-dev \
    \
    && wget -c https://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz \
        -O lua.tar.gz \
    && [ "$(sha1sum lua.tar.gz | cut -d' ' -f1)" = "${LUA_SHA1_CHECKSUM}" ] \
    && tar -xzf lua.tar.gz \
    && rm lua.tar.gz \
    \
    && cd lua-${LUA_VERSION} \
    && make -j"$(nproc)" linux \
    && make install \
    && cd .. \
    && rm -rf lua-${LUA_VERSION} \
    \
    && apk del .build-deps

FROM alpine-lua as alpine-luarocks

ENV LUAROCKS_VERSION="3.9.2"
ENV LUAROCKS_GPG_KEY="3FD8F43C2BB3C478"

RUN set -ex \
    && apk add --no-cache gnupg \
    && gpg --keyserver keyserver.ubuntu.com --recv-keys ${LUAROCKS_GPG_KEY} \
    && wget -c https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz \
    && wget -c https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz.asc \
    && gpg --verify luarocks-${LUAROCKS_VERSION}.tar.gz.asc luarocks-${LUAROCKS_VERSION}.tar.gz \
    && apk add --no-cache build-base \
      m4 \
      bsd-compat-headers \
      openssl \
      openssl-dev \
      ca-certificates \
      wget \
      curl \
      unzip \
      zip \
      git \
    && tar -xzf luarocks-${LUAROCKS_VERSION}.tar.gz \
    && cd luarocks-${LUAROCKS_VERSION} \
    && ./configure --with-lua=/usr/local \
    && make build \
    && make install \
    && cd .. \
    && rm -f luarocks-${LUAROCKS_VERSION}.tar.gz \
    && rm -rf luarocks-${LUAROCKS_VERSION}

FROM alpine-luarocks AS luarocks-tag-release

RUN luarocks install dkjson
COPY *.rockspec rockspec.template entrypoint.lua /

ENTRYPOINT ["/entrypoint.lua"]
