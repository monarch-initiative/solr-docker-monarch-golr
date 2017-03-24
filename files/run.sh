#!/bin/bash

set -e

/data/solr-6.2.1/bin/solr start
/data/solr-6.2.1/bin/solr create -c golr
/data/solr-6.2.1/bin/solr stop
rm /data/solr-6.2.1/server/solr/golr/conf/managed-schema
cd /data/golr-schema && mvn exec:java -Dexec.mainClass="org.bbop.cli.Main" -Dexec.args="-c /data/monarch-app/conf/golr-views/oban-config.yaml -o /data/solr-6.2.1/server/solr/golr/conf/schema.xml"
wget -O /data/scigraph.tgz http://scigraph-data-dev.monarchinitiative.org/static_files/scigraph.tgz
cd /data/ && tar xzfv scigraph.tgz
mkdir -p /solr/json
/data/solr-6.2.1/bin/solr start -m 10g
cd /data/golr-loader && java -Xmx100G -Dlogback.configurationFile=file:/data/logback.xml -jar target/golr-loader-0.0.1-SNAPSHOT.jar -g /data/graph.yaml -q /data/monarch-cypher-queries/src/main/cypher/golr-loader/ -o /solr/json/ -s http://localhost:8983/solr/golr -d
/data/solr-6.2.1/bin/solr stop || true
rm -rf /solr/json
cd /data/solr-6.2.1/server/solr && tar czfv golr.tgz golr/
rm -rf /data/solr-6.2.1/server/solr/golr
mv /data/solr-6.2.1/server/solr/golr.tgz /solr
