#!/bin/bash

set -e

/data/solr-6.2.1/bin/solr start
/data/solr-6.2.1/bin/solr -p 8983 create -c golr
/data/solr-6.2.1/bin/solr -p 8983 stop
rm /data/solr-6.2.1/server/solr/golr/conf/managed-schema
cd /data/golr-schema && mvn exec:java -Dexec.mainClass="org.bbop.cli.Main" -Dexec.args="-c /data/golr-config.yaml -o /data/solr-6.2.1/server/solr/golr/conf/schema.xml"
# Set jetty idle timeout to 200 seconds
sed -i 's/<Set name="idleTimeout"><Property name="solr.jetty.http.idleTimeout" default="50000"\/><\/Set>/<Set name="idleTimeout"><Property name="solr.jetty.http.idleTimeout" default="200000"\/><\/Set>/' /data/solr-6.2.1/server/etc/jetty-http.xml
wget -O /data/scigraph.tgz http://scigraph-data-dev.monarchinitiative.org/static_files/scigraph.tgz
cd /data/ && tar xzfv scigraph.tgz
mv /data/solrconfig.xml  /data/solr-6.2.1/server/solr/golr/conf/
mkdir -p /solr/json
/data/solr-6.2.1/bin/solr start -m 10g
cd /data/golr-loader && java -Xmx300G -Dlogback.configurationFile=file:/data/logback.xml -jar target/golr-loader-0.0.1-SNAPSHOT.jar -g /data/graph.yaml -q /data/monarch-cypher-queries/src/main/cypher/golr-loader/ -s http://localhost:8983/solr/golr
rm /data/scigraph.tgz
rm -rf /data/graph/
curl http://localhost:8983/solr/golr/update?optimize=true
/data/solr-6.2.1/bin/solr stop || true
cd /data/solr-6.2.1/server/solr && tar cfv golr.tar golr/
rm -rf /data/solr-6.2.1/server/solr/golr
mv /data/solr-6.2.1/server/solr/golr.tar /solr
