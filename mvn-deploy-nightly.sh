#!/bin/sh

# Create a nightly build with appropriate version from a revision of Opencast.
#
# Check out the branch to build from then run the script in the project's root.

sha=$(git log -1 --format=%h)
today=$(date +%Y%m%d)
version="2.2-NIGHTLY-$today-$sha"

# process all module and assemblies pom and the main pom
poms="$(find modules -name "pom.xml" -depth 2) $(find assemblies -name "pom.xml") pom.xml"

# XML rewriting with xmlstarlet (http://xmlstar.sourceforge.net)
# See http://xmlstar.sourceforge.net/doc/UG/ch04s03.html to learn about document editing
docker run --rm -v $(pwd):/tmpi elchubi/xmlstarlet ed -L -N m=http://maven.apache.org/POM/4.0.0 -u "/m:project/m:version|/m:project/m:parent/m:version" -v "$version" $poms

# build and deploy
mvn clean deploy -DskipTests -DaltDeploymentRepository=entwine.releases::default::http://maven.entwinemedia.com/content/repositories/releases

# reset versions
git reset --hard HEAD
