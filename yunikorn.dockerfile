ARG GOLANG=1.16
FROM golang:$GOLANG

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
ARG REPO=https://github.com/apache/incubator-yunikorn-core.git
RUN git clone $REPO /home/$USER/repo
WORKDIR /home/$USER/repo

ARG BRANCH=master
RUN git config pull.rebase false
RUN git checkout $BRANCH
RUN make test