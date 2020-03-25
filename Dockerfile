FROM nginx

RUN mkdir -p /var/cache/nginx /var/run /var/log/nginx
RUN chmod -R 777 /var/cache/nginx /var/run /var/log/nginx /etc/nginx /etc/nginx/nginx.conf


COPY assets /usr/share/nginx/html

COPY nginx.conf /etc/nginx/nginx.conf

# support running as arbitrary user which belogs to the root group
RUN chmod -R g+rwx /var/cache/nginx /var/run /var/log/nginx /usr/share/nginx/html 

# users are not allowed to listen on priviliged ports
# RUN sed -i.bak 's/listen\(.*\)80;/listen 8080;/' /etc/nginx/conf.d/default.conf
EXPOSE 8080 80 443

# comment user directive as master process is run as user in OpenShift anyhow
#RUN sed -i.bak 's/^user/#user/' /etc/nginx/nginx.conf

# Prepare for Entrypoint
COPY entrypoint.sh entrypoint.sh
RUN chmod g+rwx entrypoint.sh

RUN addgroup nginx root
#USER nginx

ENTRYPOINT "./entrypoint.sh"
