ARG BASE=azul/zulu-openjdk:8
FROM $BASE

# prepare to install tools
RUN apt-get update && apt-get upgrade -y


# build tool
RUN apt-get install -y \
  curl \
  git \
  zip \
  wget \
  bzip2 \
  gcc \
  python3

# add script
COPY loop.sh /
RUN chmod +x /loop.sh

# add user
ARG USER=jenkins
RUN groupadd $USER
RUN useradd -ms /bin/bash -g $USER $USER

# change user
USER $USER

# clone repo
ARG REPO=https://github.com/apache/ranger.git
RUN git clone $REPO /home/$USER/repo
WORKDIR /home/$USER/repo

ARG BRANCH=master
RUN git config pull.rebase false
RUN git checkout $BRANCH
RUN mvn clean package -DskipTests