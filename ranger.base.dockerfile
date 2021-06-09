FROM ubuntu:21.04

# prepare to install tools
RUN apt-get update && apt-get upgrade -y

# build tool
RUN apt-get install -y git openjdk-8-jdk
# install maven after JDK
RUN apt-get install -y maven

# clone repo
WORKDIR /root/
RUN git clone https://github.com/apache/ranger.git
WORKDIR /root/ranger
RUN mvn -T 10 dependency:go-offline -Dmaven.artifact.threads=10