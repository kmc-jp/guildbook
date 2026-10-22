FROM debian:trixie-slim

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends slapd ldap-utils \
    && rm -rf /var/lib/apt/lists/*

COPY schema/kmc.schema /etc/ldap/schema/kmc.schema
COPY spec/integration/ldap/ssh.schema /etc/ldap/schema/ssh.schema
COPY spec/integration/ldap/slapd.conf /etc/ldap/slapd.conf
COPY spec/integration/ldap/entries.ldif /entries.ldif

EXPOSE 389
CMD ["/bin/sh", "-ec", "slapadd -f /etc/ldap/slapd.conf -l /entries.ldif; exec slapd -f /etc/ldap/slapd.conf -h ldap:/// -d 256"]
