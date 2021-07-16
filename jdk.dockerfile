FROM ubuntu:21.10

# source of jdk 15 by default
ARG JDK=openjdk-15-jdk

# prepare to install tools
RUN apt-get update && apt-get upgrade -y

# build tool
RUN apt-get install -y \
  curl \
  git \
  zip \
  wget \
  $JDK