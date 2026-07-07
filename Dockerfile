# syntax=docker/dockerfile:1
FROM docker.io/almalinux/9-base:latest as system-build
ARG DST=/mnt/sysroot

RUN cat > /etc/yum.repos.d/nginx.repo <<'EOF'
[nginx-stable]
name=nginx stable repo
baseurl=https://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
EOF
RUN dnf install -y --nodocs --nogpgcheck \
      --releasever 9 \
      --installroot /mnt/sysroot \
      --setopt install_weak_deps=false \
      coreutils-single bash openssl-libs tzdata nginx nginx-module-acme nginx-module-otel ; \
    dnf --installroot $DST clean all

RUN ln -sf /dev/stdout access.log ;mv access.log $DST/var/log/nginx/
RUN ln -sf /dev/stderr error.log ;mv error.log $DST/var/log/nginx/

RUN rm -rf $DST/usr/lib64/nginx/modules/*debug.so
RUN rm -rf $DST/etc/dnf $DST/var/cache/* $DST/var/lib/{dnf,rpm} $DST/var/log/*


COPY nginx.conf /etc/nginx/

FROM scratch
LABEL org.opencontainers.image.title=nginx \
      org.opencontainers.image.authors="purplegrape4@gmail.com"

COPY --from=system-build /mnt/sysroot/ /

USER nginx
VOLUME [ "/var/www/html" ]
WORKDIR /var/www/html
CMD [ "/usr/sbin/nginx" ]

EXPOSE 8080
