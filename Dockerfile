FROM nginx:1.17.3-alpine


#Datadog opentracing
ENV NGINX_VERSION="1.17.3"
ENV NGINX_OPENTRACING_VERSION="v0.9.0"
ENV NGINX_OPENTRACING_CPP_VERSION="v1.5.1"
ENV DATADOG_OPENTRACING_VERSION="v1.1.4"

RUN \
     apk update && \
     apk upgrade && \
     apk add curl && \
     apk add curl-dev protobuf-dev pcre-dev openssl-dev && \
     apk add build-base cmake autoconf automake git msgpack-c-dev

RUN  git clone -b $NGINX_OPENTRACING_CPP_VERSION https://github.com/opentracing/opentracing-cpp.git

RUN  cd opentracing-cpp && \
     mkdir .build && cd .build && ls && \
     cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF .. && ls && \
     make && make install

RUN git clone -b $DATADOG_OPENTRACING_VERSION https://github.com/DataDog/dd-opentracing-cpp

RUN  cd dd-opentracing-cpp && \
    mkdir .build && cd .build && \
    cmake -DBUILD_SHARED_LIBS=1 -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF .. && \
    make && make install


RUN  git clone https://github.com/opentracing-contrib/nginx-opentracing.git
RUN  ls -l /nginx-opentracing/opentracing
RUN  git clone -b release-1.17.3 https://github.com/nginx/nginx.git
RUN \
     cd nginx && \
     auto/configure \
        --with-compat \
        --add-dynamic-module=/nginx-opentracing/opentracing \
        --with-debug && \
     make modules && \
     ls -l objs && \
     echo Made
RUN  ls -l /usr/local/lib
RUN  ls -l /nginx/objs    

#Uncomment when multi-stage builds work
#FROM nginx:1.17.3-alpine

#RUN \
#     apk update && \
#     apk upgrade && \
#     apk add curl && \
#     apk add curl-dev protobuf-dev pcre-dev openssl-dev

#COPY --from=builder /usr/local/lib /usr/local/lib
#COPY --from=builder /usr/local/lib64 /usr/local/lib64
#COPY --from=builder /nginx/objs/ngx_http_opentracing_module.so /etc/nginx/modules/ngx_http_opentracing_module.so
RUN cp nginx/objs/ngx_http_opentracing_module.so /etc/nginx/modules/ngx_http_opentracing_module.so

COPY nginx.conf /etc/nginx/nginx.conf
COPY assets /usr/share/nginx/html

ADD dd-config.template.json dd-config.template.json

RUN mkdir config
COPY dd-config.template.json /config/dd-config.json

# Prepare for Entrypoint
COPY entrypoint.sh entrypoint.sh

RUN mkdir -p /var/cache/nginx /var/run /var/log/nginx
#RUN chmod -R 777 /var/cache/nginx /var/run /var/log/nginx /etc/nginx /etc/nginx/nginx.conf
RUN chmod -R g+rwx /var/cache/nginx /var/run /var/log/nginx /etc/nginx /etc/nginx/nginx.conf /usr/share/nginx/html /etc/nginx/modules /config /config/dd-config.json entrypoint.sh

RUN chgrp -R root  /var/cache/nginx /var/run /var/log/nginx /etc/nginx /etc/nginx/nginx.conf /usr/share/nginx/html /etc/nginx/modules /config /config/dd-config.json entrypoint.sh

EXPOSE 8080 80 443


#RUN chown -R nginx:nginx /usr/share/nginx/html && chmod -R 755 /usr/share/nginx/html && \
#        chown -R nginx:nginx /var/cache/nginx && \
#        chown -R nginx:nginx /var/log/nginx && \
#        chown -R nginx:nginx /etc/nginx/conf.d && \
#	chown -R nginx:nginx /config && \
#	chown -R nginx:nginx dd-config.template.json && \
#	chown -R nginx:nginx /etc/nginx/modules

#RUN touch /var/run/nginx.pid && \
#        chown -R nginx:nginx /var/run/nginx.pid

RUN addgroup nginx root
USER nginx

ENTRYPOINT "./entrypoint.sh"

