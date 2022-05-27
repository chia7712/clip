FROM ubuntu:21.10

# prepare to install tools
RUN apt-get update && apt-get upgrade -y

# Do not ask for confirmations when running apt-get, etc.
ENV DEBIAN_FRONTEND noninteractive

# build tool
RUN apt-get install -y \
  curl \
  git \
  zip \
  wget \
  openjdk-11-jdk \
  python3 \
  python3-pip

RUN pip install 'numpy>=1.20.0' 'pyarrow<5.0.0' pandas scipy xmlrunner coverage 'flake8==3.9.0' \
    pydata_sphinx_theme 'mypy==0.920' numpydoc 'jinja2<3.0.0' 'black==21.12b0' pandas-stubs \
    git+https://github.com/typeddjango/pytest-mypy-plugins.git@b0020061f48e85743ee3335bd62a3a608d17c6bd \
    'sphinx<3.1.0' mkdocs ipython nbsphinx sphinx_plotly_directive 'plotly>=4.8'

ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

# change user
ARG USER=jenkins
RUN groupadd $USER
RUN useradd -ms /bin/bash -g $USER $USER
USER $USER

# clone and build repo
ARG REPO=https://github.com/apache/spark.git
ARG BRANCH=master
ARG PROFILER="-Pyarn -Pmesos -Pkubernetes -Phive -Phive-thriftserver -Phadoop-cloud -Pkinesis-asl \
                  -Pdocker-integration-tests -Pkubernetes-integration-tests -Pspark-ganglia-lgpl"
RUN git clone $REPO /home/$USER/repo
WORKDIR /home/$USER/repo
RUN git config pull.rebase false
RUN git checkout $BRANCH
RUN ./build/sbt $PROFILER clean package
RUN ./build/sbt $PROFILER clean
