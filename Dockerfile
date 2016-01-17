FROM docker.io/debian:jessie
MAINTAINER Matic Meznar <matic@meznar.si>

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
		less \
		unzip \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Set other variables
ENV GOSU_VER=1.7 \
	VAULT_VERSION=0.4.0 \
        VAULT_SHA256=f56933cb7a445db89f8832016a862ca39b3e63dedb05709251e59d6bb40c56e8 \
	VAULT_TMP=/tmp/vault.zip \
	BIN_HOME=/usr/local/bin \
	CONFD_VERSION=0.11.0 \
	CONFD_SHA256=a67bab5d6c6d5bd6c5e671f8ddd473fa67eb7fd48494d51a855f5e4482f2d54c \
        CONFD_BIN=/usr/local/bin/confd

# Setup GnuPG
COPY gpg/* /root/.gnupg/
RUN chmod -R go-rwx /root/.gnupg \
	&& chown -R root:root /root/.gnupg

# Install confd
RUN curl -fL -o ${CONFD_BIN} "https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-linux-amd64" \
	&& echo "${CONFD_SHA256}  ${CONFD_BIN}" | sha256sum -c

# Install Hashicorp Vault
RUN curl -fL -o ${VAULT_TMP} "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip" \
	&& echo "${VAULT_SHA256}  ${VAULT_TMP}" | sha256sum -c \
	&& unzip ${VAULT_TMP} -d ${BIN_HOME} \
	&& rm -f ${VAULT_TMP}

# Install gosu
RUN gpg --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -fSL "https://github.com/tianon/gosu/releases/download/${GOSU_VER}/gosu-$(dpkg --print-architecture)" \
       && curl -o /usr/local/bin/gosu.asc -fSL "https://github.com/tianon/gosu/releases/download/${GOSU_VER}/gosu-$(dpkg --print-architecture).asc" \
        && gpg --verify /usr/local/bin/gosu.asc \
        && rm /usr/local/bin/gosu.asc \
        && chmod +x /usr/local/bin/gosu \
	&& gpg --batch --delete-keys B42F6819007F00F88E364FD4036A9C25BF357DD4

# Setup up permissions for just installed binaries
RUN chmod 0555 -R ${BIN_HOME}

# Add Blinkr CA certs
COPY certs/* /usr/local/share/ca-certificates/
RUN update-ca-certificates

# Remove setuid/setgid permissions from files
RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true

COPY apt-proxy.conf /etc/apt/apt.conf.d/01proxy

CMD ["/bin/bash"]
