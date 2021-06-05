FROM ubuntu:20.04

# source of jdk 15 by default
ARG JDK=15

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
  wget \
  openjdk-${JDK}-jdk