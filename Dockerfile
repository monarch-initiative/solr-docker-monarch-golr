FROM maven:3.6.0-jdk-8-slim
# use bash
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

ARG CURIE_MAP='https://archive.monarchinitiative.org/beta/translationtable/curie_map.yaml'

# Install git and wget
RUN apt-get -y update && apt-get install -y git wget

RUN adduser --disabled-password --uid 1006 monarch
USER monarch

ARG WORKDIR=/home/monarch/data

ENV MAVEN_CONFIG "$WORKDIR/.m2"

VOLUME /solr

# Define working directory.
RUN mkdir $WORKDIR
WORKDIR $WORKDIR
ADD files/functions.inc $WORKDIR
ADD files/logback.xml $WORKDIR
ADD files/run.sh $WORKDIR
ADD files/solrconfig.xml $WORKDIR
ADD files/golr-config.yaml $WORKDIR

RUN git clone https://github.com/SciGraph/SciGraph.git $WORKDIR/scigraph
RUN git clone https://github.com/SciGraph/golr-loader.git $WORKDIR/golr-loader
RUN git clone https://github.com/monarch-initiative/monarch-cypher-queries.git $WORKDIR/monarch-cypher-queries
RUN git clone https://github.com/berkeleybop/golr-schema $WORKDIR/golr-schema

RUN cd $WORKDIR/scigraph && mvn install -DskipTests -DskipITs
RUN cd $WORKDIR/golr-loader && mvn install -Dmaven.test.skip
RUN cd $WORKDIR/monarch-cypher-queries && mvn install
RUN cd $WORKDIR/golr-schema && mvn install

RUN wget http://archive.apache.org/dist/lucene/solr/6.2.1/solr-6.2.1.tgz -P $WORKDIR
RUN cd $WORKDIR && tar xzfv $WORKDIR/solr-6.2.1.tgz

RUN source $WORKDIR/functions.inc && getGraphConfiguration $WORKDIR/graph $CURIE_MAP > graph.yaml

CMD /home/monarch/data/run.sh
