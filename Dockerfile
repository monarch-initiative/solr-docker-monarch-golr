#
# Oracle Java 8 Dockerfile
#
# https://github.com/dockerfile/java
# https://github.com/dockerfile/java/tree/master/oracle-java8
#

# Pull base image.
FROM ubuntu:16.04
# use bash
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

VOLUME /solr

RUN apt-get -y update && apt-get install -y software-properties-common python-software-properties
RUN apt-get install -y curl

# Install Java.
RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer

# Install Maven.
RUN apt-get -y update && apt-get install -y maven

# Install Git.
RUN apt-get -y update && apt-get install -y git

# Define working directory.
WORKDIR /data
ADD files/functions.inc /data/
ADD files/logback.xml /data/
ADD files/run.sh /data/

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

RUN git clone https://github.com/SciGraph/SciGraph.git /data/scigraph
RUN git clone -b solr-socket-fix https://github.com/SciGraph/golr-loader.git /data/golr-loader
RUN git clone https://github.com/monarch-initiative/monarch-cypher-queries.git /data/monarch-cypher-queries
RUN git clone https://github.com/monarch-initiative/dipper.git /data/dipper
RUN git clone https://github.com/monarch-initiative/monarch-app.git /data/monarch-app
RUN git clone https://github.com/berkeleybop/golr-schema /data/golr-schema

RUN cd /data/scigraph && mvn install -DskipTests -DskipITs
RUN cd /data/golr-loader && mvn install -Dmaven.test.skip
RUN cd /data/dipper/maven && mvn install
RUN cd /data/monarch-cypher-queries && mvn install
RUN cd /data/golr-schema && mvn install

RUN wget http://archive.apache.org/dist/lucene/solr/6.2.1/solr-6.2.1.tgz -P /data/
RUN cd /data && tar xzfv /data/solr-6.2.1.tgz

RUN cd /data && source /data/functions.inc && getGraphConfiguration /data/graph https://raw.githubusercontent.com/monarch-initiative/dipper/master/dipper/curie_map.yaml > graph.yaml

CMD /data/run.sh
