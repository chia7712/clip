FROM ubuntu:22.04

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y git curl git make unzip wget gcc

RUN wget https://golang.org/dl/go1.15.15.linux-amd64.tar.gz
RUN tar -zxvf go1.15.15.linux-amd64.tar.gz
RUN rm -f go1.15.15.linux-amd64.tar.gz
RUN mv go /opt/

# add script
COPY loop.sh /
RUN chmod +x /loop.sh

# add user
ARG USER=jenkins
RUN groupadd $USER
RUN useradd -ms /bin/bash -g $USER $USER

# change user
USER $USER

ENV GO_HOME=/opt/go
ENV PATH=$PATH:$GO_HOME/bin

# install golangci
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.33.0

# clone core
ARG CORE_REPO=https://github.com/apache/incubator-yunikorn-core.git
RUN git clone $CORE_REPO /home/$USER/incubator-yunikorn-core
WORKDIR /home/$USER/incubator-yunikorn-core

ARG BRANCH=master
RUN git config pull.rebase false
RUN git checkout $BRANCH
RUN make test

# clone k8shim
ARG K8SHIM_REPO=https://github.com/apache/incubator-yunikorn-k8shim.git
RUN git clone $K8SHIM_REPO /home/$USER/incubator-yunikorn-k8shim
WORKDIR /home/$USER/incubator-yunikorn-k8shim

ARG BRANCH=master
RUN git config pull.rebase false
RUN git checkout $BRANCH
RUN make test