#!/bin/sh
exec scala -save -deprecation "$0" "$@"
!#

/*
Example call
./sort-packages.sh 'org.opencastproject.capture;version=${project.version},
              org.opencastproject.mediapackage.attachment;version=${project.version},
              org.opencastproject.event;version=${project.version},
              org.opencastproject.mediapackage.identifier;version=${project.version},
              org.opencastproject.mediapackage.selector;version=${project.version},
              org.opencastproject.mediapackage.track;version=${project.version},
              org.opencastproject.job.api;version=${project.version},
              org.opencastproject.mediapackage.elementbuilder;version=${project.version},
              org.opencastproject.mediapackage;version=${project.version},
              org.opencastproject.security.util;version=${project.version},
              org.opencastproject.serviceregistry.api;version=${project.version},
              org.opencastproject.rest;version=${project.version},
              org.opencastproject.security.api;version=${project.version},
              org.opencastproject.storage;version=${project.version},
              org.opencastproject.util.*;version=${project.version};-split-package:=merge-first'
*/
object Sort {
  def main(args: Array[String]) {
    val sorted = args(0).split("\n").map(_.trim).map(dropComma).sortWith(_ > _)
    val fixedLineEnds = ((false, Nil: List[String]) /: sorted){
      case ((appendComma, sum), a) => if (appendComma) (true, (a + ",") :: sum) else (true, a :: sum)
    }._2
    fixedLineEnds.foreach(println _)
  }
  
  def dropComma(a: String) = if (a endsWith ",") a take (a.length - 1) else a
}