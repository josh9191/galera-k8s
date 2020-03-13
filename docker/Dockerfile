# not used mariadb base image because there is an additional setup script on starting
FROM ubuntu:18.04

ENV MARIADB_VERSION 10.5

# add mysql user and group
RUN groupadd -r mysql && \
        useradd -r -g mysql mysql

# add mariadb repo
RUN set -ex; \
        apt-get update; \
        apt-get install -y software-properties-common; \
        apt-key adv --fetch-keys "https://mariadb.org/mariadb_release_signing_key.asc"; \
        add-apt-repository "deb [arch=amd64,arm64,ppc64el] http://mariadb.petarmaric.com/repo/${MARIADB_VERSION}/ubuntu bionic main"

# install mariadb server
RUN set -ex; \
        apt-get update; \
        echo "mariadb-server-${MARIADB_VERSION} mysql-server/root_password password pwnotset" | debconf-set-selections; \
        echo "mariadb-server-${MARIADB_VERSION} mysql-server/root_password_again password pwnotset" | debconf-set-selections; \
        apt-get install -y mariadb-server; \
        rm -rf /var/lib/mysql; \
        mkdir -p /var/lib/mysql /var/run/mysqld; \
        chown -R mysql:mysql /var/lib/mysql /var/run/mysqld

# install libnet-dns package for Perl(used in service discovery)
RUN set -ex; \
        apt-get update; \
        apt install -y libnet-dns-perl

COPY entrypoint.sh /
COPY svc-discovery.pl /

RUN chmod +x /entrypoint.sh

# RUN sh /prepare.sh

CMD ["/entrypoint.sh"]
