ARG BASE=azul/zulu-openjdk:15
FROM $BASE

# prepare to install tools
RUN apt-get update && apt-get upgrade -y


# build tool
# 1) git
# 2) curl (kafka needs to download gradlew)
# 3) zip (for gradle)
# 4) wget (for gradle)
RUN apt-get install -y \
  curl \
  git \
  zip \
  wget

# add script
COPY ./loop.sh /
RUN chmod +x /loop.sh

# change user
ARG USER=jenkins
RUN groupadd $USER
RUN useradd -ms /bin/bash -g $USER $USER
USER $USER

# clone repo
ARG REPO=https://github.com/apache/kafka.git
RUN git clone $REPO /home/$USER/repo
WORKDIR /home/$USER/repo

ARG BRANCH=trunk
RUN git config pull.rebase false
RUN git checkout $BRANCH

ARG BUILD_COMMAND="./gradlew clean build -x test --no-daemon"
RUN $BUILD_COMMAND