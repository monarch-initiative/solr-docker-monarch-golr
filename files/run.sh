#!/bin/bash

set -e

WORKDIR=/home/monarch/data

cd $WORKDIR

./solr-6.2.1/bin/solr start -p 8983
./solr-6.2.1/bin/solr create -p 8983 -c golr
./solr-6.2.1/bin/solr stop -p 8983
rm ./solr-6.2.1/server/solr/golr/conf/managed-schema
cd ./golr-schema && mvn exec:java -Dexec.mainClass="org.bbop.cli.Main" -Dexec.args="-c $WORKDIR/golr-config.yaml -o $WORKDIR/solr-6.2.1/server/solr/golr/conf/schema.xml"
# Set jetty idle timeout to 200 seconds
sed -i 's/<Set name="idleTimeout"><Property name="solr.jetty.http.idleTimeout" default="50000"\/><\/Set>/<Set name="idleTimeout"><Property name="solr.jetty.http.idleTimeout" default="200000"\/><\/Set>/' $WORKDIR/solr-6.2.1/server/etc/jetty-http.xml
wget -O $WORKDIR/scigraph.tgz http://scigraph-data-dev.monarchinitiative.org/static_files/scigraph.tgz
cd $WORKDIR && tar xzfv scigraph.tgz
mv ./solrconfig.xml  ./solr-6.2.1/server/solr/golr/conf/
./solr-6.2.1/bin/solr start -p 8983 -m 10g
cd ./golr-loader && java -Xmx275G -Dlogback.configurationFile=file:$WORKDIR/logback.xml -jar target/golr-loader-0.0.1-SNAPSHOT.jar -g $WORKDIR/graph.yaml -q $WORKDIR/monarch-cypher-queries/src/main/cypher/golr-loader/ -s http://localhost:8983/solr/golr
rm $WORKDIR/scigraph.tgz
rm -rf $WORKDIR/graph/
curl http://localhost:8983/solr/golr/update?optimize=true
$WORKDIR/solr-6.2.1/bin/solr stop || true
cd $WORKDIR/solr-6.2.1/server/solr && tar cfv golr.tar golr/
rm -rf $WORKDIR/solr-6.2.1/server/solr/golr
mv $WORKDIR/solr-6.2.1/server/solr/golr.tar /solr
