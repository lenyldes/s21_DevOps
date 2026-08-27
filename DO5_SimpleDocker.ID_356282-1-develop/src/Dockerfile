FROM nginx:latest

COPY server/server.c /app/server.c
COPY server/nginx/nginx.conf /etc/nginx/nginx.conf
COPY server/start.sh /app/start.sh

RUN apt-get update && apt-get install -y \
    gcc \
    libfcgi-dev \
    spawn-fcgi \
    && rm -rf /var/lib/apt/lists/* \
    && gcc /app/server.c -o /app/server -lfcgi \
    && chmod +x /app/start.sh \
    && chown -R nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /run

USER nginx

CMD ["/app/start.sh"]