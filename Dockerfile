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

RUN rpm -e --nodeps --noscripts --root=$DST almalinux-repos almalinux-release almalinux-gpg-keys openssl procps-ng systemd systemd-libs systemd-pam ;\
    rm -rf $DST/etc/yum.repos.d/almalinux* $DST/etc/pki/rpm-gpg/*

RUN rm -rf $DST/usr/lib64/nginx/modules/*debug.so $DST/etc/nginx/conf.d/default.conf
RUN rm -rf $DST/etc/dnf $DST/var/cache/* $DST/var/lib/{dnf,rpm} $DST/var/log/*

FROM scratch
LABEL org.opencontainers.image.title=nginx \
      org.opencontainers.image.authors="purplegrape4@gmail.com"

COPY --from=system-build /mnt/sysroot/ /
COPY nginx.conf /etc/nginx/
COPY default.conf /etc/nginx/conf.d/

RUN mkdir -p /var/log/nginx ; ln -sf /dev/stdout /var/log/nginx/access.log ; ln -sf /dev/stderr /var/log/nginx/error.log

USER nginx
VOLUME [ "/var/cache/nginx" ]
VOLUME [ "/var/www/html" ]
WORKDIR /var/www/html
CMD [ "/usr/sbin/nginx" ]

EXPOSE 8080
