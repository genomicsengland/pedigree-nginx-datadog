FROM nginx:1.17.3


RUN  apt-get update \
  && apt-get install -y wget \
  && rm -rf /var/lib/apt/lists/*

#Install nginx-opentracing
RUN get_latest_release() { \
        wget -qO- "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'; \
    } && \
    NGINX_VERSION=1.17.3 && \
    OPENTRACING_NGINX_VERSION="$(get_latest_release opentracing-contrib/nginx-opentracing)" && \
    DD_OPENTRACING_CPP_VERSION="$(get_latest_release DataDog/dd-opentracing-cpp)" && \
    # Install NGINX plugin for OpenTracing
    wget https://github.com/opentracing-contrib/nginx-opentracing/releases/download/${OPENTRACING_NGINX_VERSION}/linux-amd64-nginx-${NGINX_VERSION}-ngx_http_module.so.tgz && \
    tar zxf linux-amd64-nginx-${NGINX_VERSION}-ngx_http_module.so.tgz -C /usr/lib/nginx/modules && \
    # Install Datadog Opentracing C++ Plugin
    wget https://github.com/DataDog/dd-opentracing-cpp/releases/download/${DD_OPENTRACING_CPP_VERSION}/linux-amd64-libdd_opentracing_plugin.so.gz && \
    gunzip linux-amd64-libdd_opentracing_plugin.so.gz -c > /usr/local/lib/libdd_opentracing_plugin.so


USER root
RUN mkdir -p /var/cache/nginx /var/run /var/log/nginx
RUN chmod -R 777 /var/cache/nginx /var/run /var/log/nginx /etc/nginx /etc/nginx/nginx.conf


COPY assets /usr/share/nginx/html

COPY nginx.conf /etc/nginx/nginx.conf

ADD dd-config.template.json dd-config.template.json


EXPOSE 8080 80 443

# Prepare for Entrypoint
COPY entrypoint.sh entrypoint.sh
RUN chmod g+rwx entrypoint.sh

RUN addgroup nginx root
#USER nginx

ENTRYPOINT "./entrypoint.sh"

