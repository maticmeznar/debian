FROM debian:jessie
MAINTAINER Matic Meznar <matic@meznar.si>

# Add Blinkr CA certs
COPY certs/* /usr/local/share/ca-certificates/

# Setup APT and update packages
ENV DEBIAN_FRONTEND=noninteractive \
	DEBCONF_NONINTERACTIVE_SEEN=true
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
	&& apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install --no-install-recommends -y \
		ca-certificates \
		curl \
		gnupg-curl \
		iputils-ping \
		jq \
		less \
		nano \
		unzip \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Set other variables
ENV GOSU_VER=1.7 \
	VAULT_VERSION=0.5.0 \
        VAULT_SHA256=f81accce15313881b8d53b039daf090398b2204b1154f821a863438ca2e5d570 \
	VAULT_TMP=/tmp/vault.zip \
	VAULT_ADDR=https://vault:8200/ \
	BIN_HOME=/usr/local/bin \
	CONFD_VERSION=0.11.0 \
	CONFD_SHA256=a67bab5d6c6d5bd6c5e671f8ddd473fa67eb7fd48494d51a855f5e4482f2d54c \
        CONFD_BIN=/usr/local/bin/confd \
	DOCKERIZE_VERSION=0.0.4 \
	DOCKERIZE_SHA256=f9a3a1e86ade98d52c189de881f99416ce7c38bfa69b7cbfd1c18e9239509e81 \
	DOCKERIZE_TMP=/tmp/dockerize-linux-amd64.tar.gz


# Setup GnuPG
COPY gpg/* /root/.gnupg/
RUN chmod -R go-rwx /root/.gnupg \
	&& chown -R root:root /root/.gnupg

# Install Dockerize
RUN curl -fL -o ${DOCKERIZE_TMP} "https://github.com/jwilder/dockerize/releases/download/v${DOCKERIZE_VERSION}/dockerize-linux-amd64-v${DOCKERIZE_VERSION}.tar.gz" \
        && echo "${DOCKERIZE_SHA256}  ${DOCKERIZE_TMP}" | sha256sum -c \
	&& tar -C ${BIN_HOME} -xzvf ${DOCKERIZE_TMP} \
        && rm -f ${DOCKERIZE_TMP} \
	&& chmod 0555 ${BIN_HOME}/dockerize

# Install confd
RUN curl -fL -o ${CONFD_BIN} "https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-linux-amd64" \
	&& echo "${CONFD_SHA256}  ${CONFD_BIN}" | sha256sum -c \
	&& chmod 0555 ${CONFD_BIN}

# Install Hashicorp Vault
RUN curl -fL -o ${VAULT_TMP} "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip" \
	&& echo "${VAULT_SHA256}  ${VAULT_TMP}" | sha256sum -c \
	&& unzip ${VAULT_TMP} -d ${BIN_HOME} \
	&& rm -f ${VAULT_TMP} \
	&& chmod 0555 ${BIN_HOME}/vault

# Install gosu
RUN gpg --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& curl -o /usr/local/bin/gosu -fSL "https://github.com/tianon/gosu/releases/download/${GOSU_VER}/gosu-$(dpkg --print-architecture)" \
	&& curl -o /usr/local/bin/gosu.asc -fSL "https://github.com/tianon/gosu/releases/download/${GOSU_VER}/gosu-$(dpkg --print-architecture).asc" \
        && gpg --verify /usr/local/bin/gosu.asc \
        && rm /usr/local/bin/gosu.asc \
	&& chmod 0555 /usr/local/bin/gosu \
	&& gpg --batch --delete-keys B42F6819007F00F88E364FD4036A9C25BF357DD4

# Remove setuid/setgid permissions from files
#RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true

COPY apt-proxy.conf /etc/apt/apt.conf.d/01proxy
COPY vault.sh /etc/vault.sh

CMD ["/bin/bash"]
