#!/bin/sh
# docker-entrypoint.sh — vá cổng lắng nghe HTTP của Tomcat theo biến môi trường PORT
# trước khi khởi động, vì server.xml của Tomcat khai cổng cố định "8080" ở dạng tĩnh.
#
# Vì sao cần: Render (và Railway, Fly.io, Heroku…) gán cổng container phải lắng nghe
# ĐỘNG lúc chạy qua biến PORT, có thể khác 8080 tuỳ nền tảng/thời điểm. Không vá thì
# Tomcat vẫn lắng nghe 8080 trong khi platform route traffic vào cổng khác — healthcheck
# fail, app "deploy thành công" nhưng không request nào tới được.
set -e

PORT="${PORT:-8080}"

if [ "$PORT" != "8080" ]; then
  sed -i "s/port=\"8080\"/port=\"$PORT\"/" /usr/local/tomcat/conf/server.xml
fi

exec "$@"
