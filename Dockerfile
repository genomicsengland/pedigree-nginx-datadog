FROM nginx:1.17.3-alpine


# Start Datadog opentracing
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

#End Datadog opentracing

#Uncomment when multi-stage builds work in OpenShift
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
ADD env.txt env.txt

RUN mkdir config
COPY dd-config.template.json /config/dd-config.json
COPY env.txt /config/env.txt

# Container entry point
COPY entrypoint.sh entrypoint.sh

RUN mkdir -p /var/cache/nginx /var/run /var/log/nginx

COPY env.txt /config/env.txt

# OpenShift Container Platform runs containers using an arbitrarily assigned user ID. 
# This is meant to provide additional security against processes escaping the container due to a container engine vulnerability and 
# thereby achieving escalated permissions on the host node.
# For an image to support running as an arbitrary user, directories and files that may be written to by processes in the image 
# should be owned by the root group and be read/writable by that group. 
# Files to be executed should also have group execute permissions.

RUN chmod -R g+rwx /var/cache/nginx /var/run /var/log/nginx /etc/nginx /etc/nginx/nginx.conf /usr/share/nginx/html /etc/nginx/modules /config /config/dd-config.json entrypoint.sh

RUN chgrp -R root  /var/cache/nginx /var/run /var/log/nginx /etc/nginx /etc/nginx/nginx.conf /usr/share/nginx/html /etc/nginx/modules /config /config/dd-config.json entrypoint.sh

EXPOSE 8080 80 443


RUN addgroup nginx root
USER nginx




ENTRYPOINT "./entrypoint.sh"

