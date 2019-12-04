FROM centos:7
LABEL maintainer="Adam W Zheng <adam.w.zheng@icloud.com>"

ENV S6_RELEASE 1.22.1.0
ENV SIMPLESAMLPHP_RELEASE 1.18.2

#Add s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v$S6_RELEASE/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C / --exclude="./bin" \
 && tar xzf /tmp/s6-overlay-amd64.tar.gz -C /usr ./bin

#Install simplesamlphp requirements
RUN yum -y install centos-release-scl \
 && yum -y install rh-nginx114 rh-php72 rh-php72-php-fpm rh-php72-php-mbstring rh-php72-php-pdo rh-php72-php-ldap sclo-php72-php-pecl-memcached postfix \
 && sed -i 's/user = apache/user = nginx/' /etc/opt/rh/rh-php72/php-fpm.d/www.conf \
 && sed -i 's/group = apache/group = nginx/' /etc/opt/rh/rh-php72/php-fpm.d/www.conf

#Configure webserver
RUN echo -e 'server {\n    listen       80 default_server;\n    listen       [::]:80 default_server;\n    server_name  _;\n    root         /var/simplesamlphp/www/;\n    index        index.php;\n\n    location /simplesaml {\n        alias /var/simplesamlphp/www/;\n        location ~ ^(?<prefix>/simplesaml)(?<phpfile>.+?.php)(?<pathinfo>/.*)?$ {\n            include fastcgi_params;\n            fastcgi_pass 127.0.0.1:9000;\n            fastcgi_split_path_info ^(.+?.php)(/.+)$;\n            fastcgi_param SCRIPT_FILENAME $document_root$phpfile;\n            fastcgi_param PATH_INFO $pathinfo if_not_empty;\n        }\n    }\n\n    location ~ .php$ {\n        fastcgi_split_path_info ^(.+.php)(/.+)$;\n        fastcgi_pass 127.0.0.1:9000;\n        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;\n        include fastcgi_params;\n        add_header Cache-control no-cache;\n    }\n}'  > /etc/opt/rh/rh-nginx114/nginx/conf.d/default.conf \
 && sed -i '/        listen       80 default_server;/d' /etc/opt/rh/rh-nginx114/nginx/nginx.conf \
 && sed -i '/        listen       \[::\]:80 default_server;/d' /etc/opt/rh/rh-nginx114/nginx/nginx.conf \
 && sed -i '/        server_name  _;/d' /etc/opt/rh/rh-nginx114/nginx/nginx.conf \
 && mkdir -p /var/lib/php/session/ \
 && chown -Rv nginx:nginx /var/lib/php/session/ \
 && chmod a+t /var/lib/php/session/

#Download simplesamlphp and retain archive for seeding
RUN curl -Lo /var/simplesamlphp.tar.gz https://github.com/simplesamlphp/simplesamlphp/releases/download/v$SIMPLESAMLPHP_RELEASE/simplesamlphp-$SIMPLESAMLPHP_RELEASE.tar.gz \
 && tar xzf /var/simplesamlphp.tar.gz --directory /var \
 && mv /var/simplesamlphp-* /var/simplesamlphp \
 && touch /var/simplesamlphp/cert/breadcrumb \
 && touch /var/simplesamlphp/log/breadcrumb

#Redirect nginx logs
RUN ln -sf /dev/stdout /var/opt/rh/rh-nginx114/log/nginx/access.log \
 && ln -sf /dev/stderr /var/opt/rh/rh-nginx114/log/nginx/error.log

#Add service nginx to s6-supervisor
RUN mkdir -p /etc/services.d/nginx/ \
 && touch /etc/services.d/nginx/run \
 && echo '#!/usr/bin/execlineb -P' > /etc/services.d/nginx/run \
 && echo '/opt/rh/rh-nginx114/root/usr/sbin/nginx -g "daemon off;"' >> /etc/services.d/nginx/run

#Add service php-fpm to s6-supervisor
RUN mkdir -p /etc/services.d/php-fpm/ \
 && touch /etc/services.d/php-fpm/run \
 && echo '#!/usr/bin/execlineb -P' > /etc/services.d/php-fpm/run \
 && echo '/opt/rh/rh-php72/root/usr/sbin/php-fpm' >> /etc/services.d/php-fpm/run --nodaemonize \
 && sed -i 's|pid = /run/php-fpm/php-fpm.pid|pid = /run/php-fpm.pid|g' /etc/opt/rh/rh-php72/php-fpm.conf

#Add service postfix to s6-supervisor
RUN mkdir -p /etc/services.d/postfix/ \
 && touch /etc/services.d/postfix/run \
 && echo '#!/usr/bin/execlineb -P' > /etc/services.d/postfix/run \
 && echo '/usr/libexec/postfix/master -c /etc/postfix -d' >> /etc/services.d/postfix/run

#Copy the simplesamlphp install script into the container to be executed on startup
COPY install-simplesamlphp.sh /etc/cont-init.d/
RUN chmod u+x /etc/cont-init.d/install-simplesamlphp.sh

RUN yum -y update && yum clean all && rm -rf /var/cache/yum && > /var/log/yum.log

ENTRYPOINT ["/init"]
