FROM docker.io/debian:jessie
MAINTAINER Matic Meznar <matic@meznar.si>

ENV DEBIAN_FRONTEND=noninteractive \
	DEBCONF_NONINTERACTIVE_SEEN=true \
	GOSU_VER=1.7

COPY apt-proxy.conf /etc/apt/apt.conf.d/01proxy
COPY gpg/* /root/.gnupg/

RUN chmod -R go-rwx /root/.gnupg \
	&& chown -R root:root /root/.gnupg

# Setup APT and update packages
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
	&& apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install --no-install-recommends -y \
		ca-certificates \
		curl \
		gnupg-curl \
		less \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Install gosu
RUN gpg --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -fSL "https://github.com/tianon/gosu/releases/download/${GOSU_VER}/gosu-$(dpkg --print-architecture)" \
       && curl -o /usr/local/bin/gosu.asc -fSL "https://github.com/tianon/gosu/releases/download/${GOSU_VER}/gosu-$(dpkg --print-architecture).asc" \
        && gpg --verify /usr/local/bin/gosu.asc \
        && rm /usr/local/bin/gosu.asc \
        && chmod +x /usr/local/bin/gosu \
	&& gpg --batch --delete-keys B42F6819007F00F88E364FD4036A9C25BF357DD4

# Add Blinkr CA certs
COPY certs/* /usr/local/share/ca-certificates/
RUN update-ca-certificates

# Remove setuid/setgid permissions from files
RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true

CMD ["/bin/bash"]
