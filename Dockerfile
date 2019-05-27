FROM frolvlad/alpine-java:jdk8-slim
# https://hub.docker.com/r/frolvlad/alpine-miniconda3/dockerfile

# VERSIONS
ENV SPARK_VER=2.4.1
ENV HADOOP_VER=2.7
ENV CONDA_VERSION=4.2.12
ENV PYTHON_VERSION=3.5
ENV ZEPPELIN_VERSION=0.8.1

# COMMON TOOLS
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN apk add --no-cache tini bash
RUN apk add --no-cache --virtual=.build-dependencies wget ca-certificates

# INSTALL PYTHON FROM CONDA
ENV CONDA_DIR="/opt/conda"
ENV PATH="$CONDA_DIR/bin:$PATH"
ENV CONDA_MD5=d0c7c71cc5659e54ab51f2005a8d96f3

RUN mkdir -p "$CONDA_DIR" && \
    wget "http://repo.continuum.io/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh" && \
    echo "$CONDA_MD5  Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh" | md5sum -c && \
    bash Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh -f -b -p "$CONDA_DIR" && \
    echo "export PATH=$CONDA_DIR/bin:\$PATH" > /etc/profile.d/conda.sh && \
    rm Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh && \
    conda config --set auto_update_conda False && \
    conda config --add channels conda-forge && \
    conda install python=$PYTHON_VERSION --yes && \
    conda update --all --yes

# # INSTALL ZEPPELIN
ENV ZEPPELIN_HOME="/opt/zeppelin-${ZEPPELIN_VERSION}-bin-all"

RUN apk add --no-cache --virtual=.build-dependencies gfortran lapack-dev libpng-dev freetype-dev libxft-dev libxml2-dev libxslt-dev zlib-dev  && \
    conda install -q -y tk numpy=1.12.1 pandas=0.21.1 matplotlib=2.1.1 pandasql=0.7.3 ipython=5.4.1 jupyter_client=5.1.0 ipykernel=4.7.0 bokeh=0.12.10 && \
    pip install -q ggplot==0.11.5 grpcio==1.8.2 bkzep==0.4.0 && \
    wget -qO- http://archive.apache.org/dist/zeppelin/zeppelin-${ZEPPELIN_VERSION}/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz | tar xfz - -C /opt/

# # INSTALL CURRENT VERSION OF SPARK
ENV SPARK_FILENAME=spark-${SPARK_VER}-bin-hadoop${HADOOP_VER}
ENV SPARK_HOME=/opt/${SPARK_FILENAME}

RUN wget -qO- https://archive.apache.org/dist/spark/spark-${SPARK_VER}/${SPARK_FILENAME}.tgz | tar xfz - -C /opt/

# # CLEAN UP
RUN apk del --purge .build-dependencies && \
    conda clean --all && \
    rm -r "$CONDA_DIR/pkgs/" && \
    mkdir -p "$CONDA_DIR/locks" && \
    chmod 777 "$CONDA_DIR/locks"

ENTRYPOINT ["/sbin/tini", "--"]
WORKDIR ${ZEPPELIN_HOME}
CMD ["bin/zeppelin.sh"]