FROM alpine:3.17.1 AS alpine-lua

ENV LUA_VERSION="5.1.5"
ENV LUA_SHA1_CHECKSUM="b3882111ad02ecc6b972f8c1241647905cb2e3fc"

RUN set -ex \
    && apk upgrade \
    && apk add --no-cache readline-dev=8.2.0-r0 \
    && apk add --no-cache --virtual .build-deps \
        make=4.3-r1 \
        gcc=12.2.1_git20220924-r4 \
        libc-dev=0.7.2-r3 \
        ncurses-dev=6.3_p20221119-r0 \
    && wget -cq https://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz \
        -O lua.tar.gz \
    && [ "$(sha1sum lua.tar.gz | cut -d' ' -f1)" = "${LUA_SHA1_CHECKSUM}" ] \
    && tar -xzf lua.tar.gz \
    && rm lua.tar.gz

WORKDIR /lua-${LUA_VERSION}
RUN make -j"$(nproc)" linux \
    && make install

WORKDIR /
RUN rm -rf lua-${LUA_VERSION} \
    && apk del .build-deps

FROM alpine-lua as alpine-luarocks

ENV LUAROCKS_VERSION="3.9.2"
ENV LUAROCKS_GPG_KEY="3FD8F43C2BB3C478"

RUN set -ex \
    && apk add --no-cache gnupg=2.2.40-r0 \
    && gpg --keyserver keyserver.ubuntu.com --recv-keys ${LUAROCKS_GPG_KEY} \
    && wget -cq https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz \
    && wget -cq https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz.asc \
    && gpg --verify luarocks-${LUAROCKS_VERSION}.tar.gz.asc luarocks-${LUAROCKS_VERSION}.tar.gz \
    && apk add --no-cache build-base=0.5-r3 \
      m4=1.4.19-r1 \
      bsd-compat-headers=0.7.2-r3 \
      openssl=3.0.7-r2 \
      openssl-dev=3.0.7-r2 \
      ca-certificates=20220614-r4 \
      wget=1.21.3-r2 \
      curl=7.87.0-r1 \
      unzip=6.0-r13 \
      zip=3.0-r10 \
      git=2.38.2-r0 \
    && tar -xzf luarocks-${LUAROCKS_VERSION}.tar.gz \
    && rm -rf /var/cache/apk/*

WORKDIR /luarocks-${LUAROCKS_VERSION}
RUN ./configure --with-lua=/usr/local \
    && make build \
    && make install

WORKDIR /
RUN rm -f luarocks-${LUAROCKS_VERSION}.tar.gz \
    && rm -rf luarocks-${LUAROCKS_VERSION}

FROM alpine-luarocks AS luarocks-tag-release

RUN luarocks install dkjson
COPY rockspec.template /rockspec.template
COPY entrypoint.lua /entrypoint.lua

ENTRYPOINT ["/entrypoint.lua"]
