#!/bin/bash

set -e

/data/solr-6.2.1/bin/solr start
/data/solr-6.2.1/bin/solr create -c golr 
/data/solr-6.2.1/bin/solr stop
rm /data/solr-6.2.1/server/solr/golr/conf/managed-schema 
cd /data/golr-schema && mvn exec:java -Dexec.mainClass="org.bbop.cli.Main" -Dexec.args="-c /data/monarch-app/conf/golr-views/oban-config.yaml -o /data/solr-6.2.1/server/solr/golr/conf/schema.xml"
wget -O /data/scigraph.tgz http://scigraph-data-dev.monarchinitiative.org/static_files/scigraph.tgz 
cd /data/ && tar xzfv scigraph.tgz
mkdir -p /data/json
/data/solr-6.2.1/bin/solr start
cd /data/golr-loader && java -Xmx50G -Dlog4j.configuration=file:/data/log4j.properties -jar target/golr-loader-0.0.1-SNAPSHOT-jar-with-dependencies.jar -g /data/graph.yaml -q /data/monarch-cypher-queries/src/main/cypher/golr-loader -o /data/json/ -s http://localhost:8983/solr/golr
/data/solr-6.2.1/bin/solr stop
cd /data/solr-6.2.1/server/solr && tar czfv golr.tgz golr/
cp /data/solr-6.2.1/server/solr/golr.tgz /solr