ARG JDK_VERSION=21
FROM azul/zulu-openjdk:$JDK_VERSION

# prepare to install tools
RUN apt-get update && apt-get upgrade -y

# build tool
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
RUN git clone --depth=1 $REPO /home/$USER/kafka
WORKDIR /home/$USER/kafka

ARG BRANCH=trunk
RUN git config pull.rebase false
RUN git checkout $BRANCH

RUN ./gradlew clean build -x test --no-daemon && ./gradlew clean