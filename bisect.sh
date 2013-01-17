#!/bin/sh
e=modules/matterhorn-episode-service-api/src/main/java/org/opencastproject/episode/api/EpisodeService.java
if [ -e $e ] ; then
  exit $(cat $e|grep 'Map<String, String>')
fi
exit 0
