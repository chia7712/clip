ARG JDK=11
FROM azul/zulu-openjdk:$JDK

# install libs for mysql
RUN apt update && apt upgrade -y && apt-get install -y git curl libaio1 libnuma1 libncurses5

# change user
ARG USER=jenkins
RUN groupadd $USER
RUN useradd -ms /bin/bash -g $USER $USER
USER $USER

# clone repo
ARG REPO=https://github.com/chia7712/ohara.git
RUN git clone $REPO /home/$USER/repo
WORKDIR /home/$USER/repo

ARG BRANCH=master
RUN git config pull.rebase false
RUN git checkout $BRANCH

RUN ./gradlew clean build -x test -PskipManager --no-daemon
RUN ./gradlew ohara-client:test -PskipManager --no-daemon --tests TestDatabaseClient