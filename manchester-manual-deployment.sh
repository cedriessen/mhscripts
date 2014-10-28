#!/bin/sh
hosts="man-s-admin man-s-present man-s-ingest1 man-s-ingest2 man-s-w1 man-s-w2"
viewLogHost="man-s-admin"
modules="matterhorn-serviceregistry"
#modules="matterhorn-participation-api matterhorn-participation-persistence manchester-participation-management-ui-teacher"
#modules="manchester-participation-management-ui-teacher"

echo "++ build"
cd /Users/ced/dev/mh/scripts
for m in $modules; do
  mh deploy -v 1.5.x -m $m
done

for host in $hosts; do
  echo "++ sync $host"
  cd /Users/ced/dev/mh/matterhorn
  for m in $modules; do
    scp modules/$m/target/*.jar $host:/home/entwine
  done

  echo "++ deploy $host"
  ssh $host "sudo cp *.jar /opt/matterhorn/lib/matterhorn/"
done

for host in $hosts; do
  echo "++ restart $host"
  ssh $host "sudo service matterhorn restart"
done

echo "++ view log $viewLogHost"
ssh $viewLogHost "tail -f /var/log/matterhorn/matterhorn.log"
