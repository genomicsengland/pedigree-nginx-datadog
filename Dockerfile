FROM nginx

USER root
RUN mkdir -p /var/cache/nginx /var/run /var/log/nginx
RUN chmod -R 777 /var/cache/nginx /var/run /var/log/nginx /etc/nginx /etc/nginx/nginx.conf


COPY assets /usr/share/nginx/html

COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080 80 443

# Prepare for Entrypoint
COPY entrypoint.sh entrypoint.sh
RUN chmod g+rwx entrypoint.sh

RUN addgroup nginx root
#USER nginx

ENTRYPOINT "./entrypoint.sh"

