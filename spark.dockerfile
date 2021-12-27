FROM ubuntu:21.10

# prepare to install tools
RUN apt-get update && apt-get upgrade -y

# Do not ask for confirmations when running apt-get, etc.
ENV DEBIAN_FRONTEND noninteractive

# build tool
ARG JDK=openjdk-11-jdk
RUN apt-get install -y \
  curl \
  git \
  zip \
  wget \
  $JDK \
  python3 \
  python3-pip \
  flake8

ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

# install latest maven
ARG MAVEN="3.8.4"
WORKDIR /tmp
RUN wget https://dlcdn.apache.org/maven/maven-3/${MAVEN}/binaries/apache-maven-${MAVEN}-bin.zip
RUN unzip apache-maven-${MAVEN}-bin.zip
RUN ln -s /tmp/apache-maven-${MAVEN}/bin/mvn /bin/ && ln -s /tmp/apache-maven-${MAVEN}/bin/mvn /sbin/
ENV MAVEN_HOME="/tmp/apache-maven-${MAVEN}"
ENV MAVEN_OPTS="-Xss64m -Xmx4g"

# change user
ARG USER=jenkins
RUN groupadd $USER
RUN useradd -ms /bin/bash -g $USER $USER
USER $USER

# clone and build repo
#ARG REPO=https://github.com/apache/spark.git
#ARG BRANCH=master
#RUN git clone $REPO /home/$USER/repo
#WORKDIR /home/$USER/repo
#RUN git config pull.rebase false
#RUN git checkout $BRANCH
#RUN mvn clean package -DskipTests
