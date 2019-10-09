FROM ubuntu:18.04
LABEL maintainer="Betacloud Solutions GmbH (https://www.betacloud-solutions.de)"

ARG VERSION
ENV VERSION ${VERSION:-latest}
ENV MANAGER_VERSION ${VERSION:-latest}

ENV DEBIAN_FRONTEND noninteractive

ENV USER_ID ${USER_ID:-45000}
ENV GROUP_ID ${GROUP_ID:-45000}

USER root

ADD files/run.sh /run.sh

RUN apt update \
    && apt upgrade -y \
    && apt install -y \
        bash \
        git \
        locales \
        python3-pip

RUN groupadd -g $GROUP_ID dragon \
    && useradd -g dragon -u $USER_ID -m -d /home/dragon dragon

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN mkdir -p /ansible/roles /ansible/secrets /opt/configuration \
    && chown -R dragon: /ansible \
    && git clone https://github.com/osism/cfg-master \
    && pip3 install -r /cfg-master/requirements.txt \
    && ( cd /cfg-master; MANAGER_VERSION=$VERSION gilt overlay ) \
    && cp /cfg-master/environments/manager/requirements.yml /ansible \
    && pip3 install -r /cfg-master/environments/manager/requirements.txt \
    && ansible-galaxy install -r /ansible/requirements.yml -p /ansible/roles

RUN apt clean \
    && rm -rf \
      /var/lib/apt/lists/* \
      /var/tmp/*  \
      /usr/share/doc/* \
      /usr/share/man/* \
      /cfg-master \
      /root/.gilt

USER dragon
WORKDIR /home/dragon

VOLUME ["/opt/configuration"]

ENTRYPOINT ["/run.sh"]
