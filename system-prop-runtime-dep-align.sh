#!/bin/sh
# developed with Scala 2.9.2
exec scala -save -deprecation "$0" "$@"
!#
import java.io.File
import java.io.InputStream
import scala.io.Source
import scala.sys.process._
import scala.xml.NodeSeq
import scala.xml.XML

object Main {
	val Jar = """.*?file:.*/([^ ]*).*""".r
	val BundleVersion = """(.*)-([0-9].*)\.jar""".r
	
	val dir = for {
			a <- Data.dir.split("\n").toList
			BundleVersion(b, v) = a.trim
		} yield 
			(b, v)
			
		
	val sys = Data.sys.split("\n").flatMap({
			case Jar(x) => x match {
				case BundleVersion(b, v) => List(b -> v)
				case _ => Nil
			}
			case _ => Nil
		}).toList
				
	val sorter = (a: (String, String), b: (String, String)) => a._1 < b._1			
				
  def main(args: Array[String]) {
		val diff = dir.filterNot(sys.contains).sortWith(sorter)
		println("JARs different in lib directory")
		println("-------------------------------")
		diff foreach println
		
		val inSys = sys.flatMap{case (b, v) => diff.find{case (b1, _) => b == b1}}.sortWith(sorter)
		println()
		println("Update JARs in system.properties to")
		println("-----------------------------------")
		inSys foreach println
  }
}

object Data {
	// get with ls -1 in modules/matterhorn-runtime-dependencies/target/dependency
	val dir = """com.springsource.org.aopalliance-1.0.0.jar
	com.springsource.org.apache.commons.beanutils-1.7.0.jar
	com.springsource.org.apache.xalan-2.7.1.jar
	com.springsource.org.apache.xml.security-1.4.2.jar
	com.springsource.org.apache.xml.serializer-2.7.1.jar
	com.springsource.org.cyberneko.html-1.9.13.jar
	com.springsource.org.jasig.cas.client-3.1.12.jar
	com.springsource.org.jdom-1.0.0.jar
	com.springsource.org.openid4java-0.9.5.jar
	com.springsource.org.opensaml-1.1.0.jar
	commons-codec-1.6.jar
	commons-collections-3.2.1.jar
	commons-compress-1.5.jar
	commons-dbcp-1.4.jar
	commons-fileupload-1.2.1.jar
	commons-io-2.1.jar
	commons-lang-2.6.jar
	commons-pool-1.5.3.jar
	cxf-bundle-jaxrs-2.2.9.jar
	geronimo-annotation_1.1_spec-1.0.1.jar
	geronimo-servlet_2.5_spec-1.2.jar
	guava-osgi-9.0.0.jar
	httpclient-osgi-4.2.5.jar
	httpcore-osgi-4.2.4.jar
	jackson-core-lgpl-1.8.1.jar
	jackson-mapper-lgpl-1.8.1.jar
	javax.activation-mail-1.1.1.1.4.2-1.4.2.jar
	javax.persistence-2.0.3.jar
	jettison-1.3.1.jar
	joda-time-1.6.jar
	jolokia-osgi-1.0.4.jar
	neethi-3.0.1.jar
	org.apache.felix.configadmin-1.2.8.jar
	org.apache.felix.eventadmin-1.2.12.jar
	org.apache.felix.fileinstall-3.1.10.jar
	org.apache.felix.http.bundle-2.2.0.jar
	org.apache.felix.metatype-1.0.4.jar
	org.apache.felix.prefs-1.0.4.jar
	org.apache.felix.scr-1.6.0.jar
	org.apache.felix.webconsole-3.1.8.jar
	org.apache.servicemix.bundles.asm-2.2.3_1.jar
	org.apache.servicemix.bundles.bcel-5.2_3.jar
	org.apache.servicemix.bundles.cglib-2.2_2.jar
	org.apache.servicemix.bundles.commons-httpclient-3.1_7.jar
	org.apache.servicemix.bundles.jaxb-impl-2.1.6_1.jar
	org.apache.servicemix.bundles.quartz-1.8.5_1.jar
	org.apache.servicemix.bundles.rome-1.0_2.jar
	org.apache.servicemix.bundles.woodstox-3.2.7_1.jar
	org.apache.servicemix.bundles.wsdl4j-1.6.1_1.jar
	org.apache.servicemix.bundles.xerces-2.9.1_3.jar
	org.apache.servicemix.bundles.xmlresolver-1.2_1.jar
	org.apache.servicemix.bundles.xmlschema-1.4.3_1.jar
	org.apache.servicemix.specs.jaxb-api-2.1-1.9.0.jar
	org.apache.servicemix.specs.jaxp-api-1.4-1.9.0.jar
	org.apache.servicemix.specs.jsr311-api-1.1.1-1.9.0.jar
	org.apache.servicemix.specs.stax-api-1.0-1.9.0.jar
	org.eclipse.persistence.antlr-2.0.2.jar
	org.eclipse.persistence.asm-2.0.2.jar
	org.eclipse.persistence.core-2.0.2.jar
	org.eclipse.persistence.jpa-2.0.2.jar
	org.osgi.compendium-4.2.0.jar
	org.osgi.enterprise-4.2.0.jar
	org.springframework.jdbc-3.1.0.RELEASE.jar
	org.springframework.ldap-1.3.1.RELEASE.jar
	pax-confman-propsloader-0.2.2.jar
	pax-logging-api-1.6.4.jar
	pax-logging-service-1.6.4.jar
	pax-web-jsp-1.1.1.jar
	spring-aop-3.1.0.RELEASE.jar
	spring-asm-3.1.0.RELEASE.jar
	spring-beans-3.1.0.RELEASE.jar
	spring-context-3.1.0.RELEASE.jar
	spring-context-support-3.1.0.RELEASE.jar
	spring-core-3.1.0.RELEASE.jar
	spring-expression-3.1.0.RELEASE.jar
	spring-osgi-core-1.2.1.jar
	spring-osgi-extender-1.2.1.jar
	spring-osgi-io-1.2.1.jar
	spring-security-cas-3.1.0.RELEASE.jar
	spring-security-config-3.1.0.RELEASE.jar
	spring-security-core-3.1.0.RELEASE.jar
	spring-security-ldap-3.1.0.RELEASE.jar
	spring-security-openid-3.1.0.RELEASE.jar
	spring-security-web-3.1.0.RELEASE.jar
	spring-tx-3.1.0.RELEASE.jar
	spring-web-3.1.0.RELEASE.jar
	tika-bundle-1.1.jar
	tika-core-1.1.jar
	tika-parsers-1.1.jar"""
		
	// content of system.properties	
	val sys = """# Licensed to the Apache Software Foundation (ASF) under one
	# or more contributor license agreements.  See the NOTICE file
	# distributed with this work for additional information
	# regarding copyright ownership.  The ASF licenses this file
	# to you under the Apache License, Version 2.0 (the
	# "License"); you may not use this file except in compliance
	# with the License.  You may obtain a copy of the License at
	#
	#   http://www.apache.org/licenses/LICENSE-2.0
	#
	# Unless required by applicable law or agreed to in writing,
	# software distributed under the License is distributed on an
	# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
	# KIND, either express or implied.  See the License for the
	# specific language governing permissions and limitations
	# under the License.

	#
	# Framework config properties.
	#

	# To override the packages the framework exports by default from the
	# class path, set this variable.
	# Packages 'javax.xml.stream, javax.xml.stream.events, javax.xml.stream.util' removed --> provided by ServiceMix STAX bundle
	# Packages 'javax.mail, javax.mail.internet' removed --> provided by Jeronimo JavaMail bundle
	org.osgi.framework.system.packages=org.osgi.framework;version=1.6.0,org.osgi.framework.hooks.bundle;version=1.0.0,org.osgi.framework.hooks.resolver;version=1.0.0,org.osgi.framework.hooks.service;version=1.1.0,org.osgi.framework.hooks.weaving;version=1.0.0,org.osgi.framework.launch;version=1.0.0,org.osgi.framework.startlevel;version=1.0.0,org.osgi.framework.wiring;version=1.0.0,org.osgi.service.packageadmin;version=1.2.0,org.osgi.service.startlevel;version=1.1.0,org.osgi.service.url;version=1.0.0,org.osgi.util.tracker;version=1.5.0,javax.accessibility, javax.activity, javax.annotation, javax.annotation.processing, javax.crypto, javax.crypto.interfaces, javax.crypto.spec, javax.imageio, javax.imageio.event, javax.imageio.metadata, javax.imageio.plugins.bmp, javax.imageio.plugins.jpeg, javax.imageio.spi, javax.imageio.stream, javax.jws, javax.jws.soap, javax.lang.model, javax.lang.model.element, javax.lang.model.type, javax.lang.model.util, javax.management, javax.management.loading, javax.management.modelmbean, javax.management.monitor, javax.management.openmbean, javax.management.relation, javax.management.remote, javax.management.remote.rmi, javax.management.timer, javax.naming, javax.naming.directory, javax.naming.event, javax.naming.ldap, javax.naming.spi, javax.net, javax.net.ssl, javax.print, javax.print.attribute, javax.print.attribute.standard, javax.print.event, javax.rmi, javax.rmi.CORBA, javax.rmi.ssl, javax.script, javax.security.auth, javax.security.auth.callback, javax.security.auth.kerberos, javax.security.auth.login, javax.security.auth.spi, javax.security.auth.x500, javax.security.cert, javax.security.sasl, javax.sound.midi, javax.sound.midi.spi, javax.sound.sampled, javax.sound.sampled.spi, javax.sql, javax.sql.rowset, javax.sql.rowset.serial, javax.sql.rowset.spi, javax.swing, javax.swing.border, javax.swing.colorchooser, javax.swing.event, javax.swing.filechooser, javax.swing.plaf, javax.swing.plaf.basic, javax.swing.plaf.metal, javax.swing.plaf.multi, javax.swing.plaf.synth, javax.swing.table, javax.swing.text, javax.swing.text.html, javax.swing.text.html.parser, javax.swing.text.rtf, javax.swing.tree, javax.swing.undo, javax.tools, javax.transaction, javax.transaction.xa, javax.xml, javax.xml.bind, javax.xml.bind.annotation, javax.xml.bind.annotation.adapters, javax.xml.bind.attachment, javax.xml.bind.helpers, javax.xml.bind.util, javax.xml.crypto, javax.xml.crypto.dom, javax.xml.crypto.dsig, javax.xml.crypto.dsig.dom, javax.xml.crypto.dsig.keyinfo, javax.xml.crypto.dsig.spec, javax.xml.datatype, javax.xml.namespace, javax.xml.soap, javax.xml.transform, javax.xml.transform.dom, javax.xml.transform.sax, javax.xml.transform.stax, javax.xml.transform.stream, javax.xml.validation, javax.xml.ws, javax.xml.ws.handler, javax.xml.ws.handler.soap, javax.xml.ws.http, javax.xml.ws.soap, javax.xml.ws.spi, javax.xml.ws.wsaddressing1, javax.xml.xpath, org.ietf.jgss, org.omg.CORBA, org.omg.CORBA_2_3, org.omg.CORBA_2_3.portable, org.omg.CORBA.DynAnyPackage, org.omg.CORBA.ORBPackage, org.omg.CORBA.portable, org.omg.CORBA.TypeCodePackage, org.omg.CosNaming, org.omg.CosNaming.NamingContextExtPackage, org.omg.CosNaming.NamingContextPackage, org.omg.Dynamic, org.omg.DynamicAny, org.omg.DynamicAny.DynAnyFactoryPackage, org.omg.DynamicAny.DynAnyPackage, org.omg.IOP, org.omg.IOP.CodecFactoryPackage, org.omg.IOP.CodecPackage, org.omg.Messaging, org.omg.PortableInterceptor, org.omg.PortableInterceptor.ORBInitInfoPackage, org.omg.PortableServer, org.omg.PortableServer.CurrentPackage, org.omg.PortableServer.POAManagerPackage, org.omg.PortableServer.POAPackage, org.omg.PortableServer.portable, org.omg.PortableServer.ServantLocatorPackage, org.omg.SendingContext, org.omg.stub.java.rmi

	# To append packages to the default set of exported system packages,
	# set this value.
	org.osgi.framework.system.packages.extra=sun.awt,sun.misc,com.sun.jndi.ldap,com.sun.net.ssl.internal.ssl

	# The following property makes specified packages from the class path
	# available to all bundles. You should avoid using this property.
	#org.osgi.framework.bootdelegation=

	# Felix tries to guess when to implicitly boot delegate in certain
	# situations to ease integration without outside code. This feature
	# is enabled by default, uncomment the following line to disable it.
	#felix.bootdelegation.implicit=false

	# The following property explicitly specifies the location of the bundle
	# cache, which defaults to "felix-cache" in the current working directory.
	# If this value is not absolute, then the felix.cache.rootdir controls
	# how the absolute location is calculated. (See next property)
	#org.osgi.framework.storage=${dollar}{felix.cache.rootdir}/felix-cache

	# The following property is used to convert a relative bundle cache
	# location into an absolute one by specifying the root to prepend to
	# the relative cache path. The default for this property is the
	# current working directory.
	#felix.cache.rootdir=${dollar}{user.dir}

	# The following property controls whether the bundle cache is flushed
	# the first time the framework is initialized. Possible values are
	# "none" and "onFirstInit"; the default is "none".
	#org.osgi.framework.storage.clean=onFirstInit

	# The following property determines which actions are performed when
	# processing the auto-deploy directory. It is a comma-delimited list of
	# the following values: 'install', 'start', 'update', and 'uninstall'.
	# An undefined or blank value is equivalent to disabling auto-deploy
	# processing.
	felix.auto.deploy.action=install,start

	# The following property specifies the directory to use as the bundle
	# auto-deploy directory; the default is 'bundle' in the working directory.
	felix.auto.deploy.dir=${felix.home}/lib/felix

	# The startlevel for bundles in the framework's bundle directory
	felix.auto.deploy.startlevel=1

	# The following property is a space-delimited list of bundle URLs
	# to install when the framework starts. The ending numerical component
	# is the target start level. Any number of these properties may be
	# specified for different start levels.
	#felix.auto.install.1=

	# Sets the initial start level of the framework upon startup.
	org.osgi.framework.startlevel.beginning=6

	# Sets the start level of newly installed bundles.
	felix.startlevel.bundle=6

	# Felix installs a stream and content handler factories by default,
	# uncomment the following line to not install them.
	#felix.service.urlhandlers=false

	# The launcher registers a shutdown hook to cleanly stop the framework
	# by default, uncomment the following line to disable it.
	#felix.shutdown.hook=false

	# The felix log level.
	felix.log.level=1

	# The following property is a space-delimited list of bundle URLs
	# to install and start when the framework starts. The ending numerical
	# component is the target start level. Any number of these properties
	# may be specified for different start levels.
	#felix.auto.start.1=

	# core
	felix.auto.start.1= \
	 file:${felix.home}/lib/ext/org.osgi.compendium-4.2.0.jar \
	 file:${felix.home}/lib/ext/org.osgi.enterprise-4.2.0.jar \
	 file:${felix.home}/lib/ext/org.apache.felix.configadmin-1.2.8.jar \
	 file:${felix.home}/lib/ext/pax-confman-propsloader-0.2.2.jar \
	 file:${felix.home}/lib/ext/pax-logging-api-1.6.4.jar \
	 file:${felix.home}/lib/ext/pax-logging-service-1.6.4.jar \
	 file:${felix.home}/lib/ext/org.apache.felix.eventadmin-1.2.12.jar \
	 file:${felix.home}/lib/ext/org.apache.felix.http.bundle-2.2.0.jar \
	 file:${felix.home}/lib/ext/org.apache.felix.scr-1.6.0.jar \
	 file:${felix.home}/lib/ext/org.apache.felix.metatype-1.0.4.jar \
	 file:${felix.home}/lib/ext/org.apache.felix.http.bundle-2.2.0.jar \
	 file:${felix.home}/lib/ext/org.apache.felix.fileinstall-3.1.10.jar \

	# specs
	felix.auto.start.2= \
	 file:${felix.home}/lib/ext/geronimo-annotation_1.1_spec-1.0.1.jar \
	 file:${felix.home}/lib/ext/geronimo-servlet_2.5_spec-1.2.jar \
	 file:${felix.home}/lib/ext/org.apache.servicemix.specs.stax-api-1.0-1.9.0.jar \
	 file:${felix.home}/lib/ext/javax.activation-mail-1.1.1.1.4.2-1.4.2.jar \
	 file:${felix.home}/lib/ext/org.apache.servicemix.specs.jaxp-api-1.4-1.9.0.jar \
	 file:${felix.home}/lib/ext/org.apache.servicemix.specs.jaxb-api-2.1-1.9.0.jar \
	 file:${felix.home}/lib/ext/org.apache.servicemix.specs.jsr311-api-1.1.1-1.9.0.jar \
	 file:${felix.home}/lib/ext/com.springsource.org.aopalliance-1.0.0.jar \
	 file:${felix.home}/lib/ext/javax.persistence-2.0.3.jar

	# libraries
	felix.auto.start.3= \
	 file:${felix.home}/lib/ext/commons-compress-1.5.jar \
	 file:${felix.home}/lib/ext/commons-fileupload-1.2.1.jar \
	 file:${felix.home}/lib/ext/commons-io-2.1.jar \
	 file:${felix.home}/lib/ext/commons-lang-2.6.jar \
	 file:${felix.home}/lib/ext/commons-codec-1.6.jar \
	 file:${felix.home}/lib/ext/commons-pool-1.5.3.jar \
	 file:${felix.home}/lib/ext/commons-dbcp-1.4.jar \
	 file:${felix.home}/lib/ext/commons-collections-3.2.1.jar \
	 file:${felix.home}/lib/ext/neethi-3.0.1.jar \
	 file:${felix.home}/lib/ext/joda-time-1.6.jar \
	 file:${felix.home}/lib/ext/jettison-1.3.1.jar \
	 file:${felix.home}/lib/ext/guava-osgi-9.0.0.jar \
	 file:${felix.home}/lib/ext/org.apache.servicemix.bundles.jaxb-impl-2.1.6_1.jar \
	 file:${felix.home}/lib/ext/org.apache.servicemix.bundles.quartz-1.8.5_1.jar \
	 file:${felix.home}/lib/ext/org.apache.servicemix.bundles.woodstox-3.2.7_1.jar \
	 file:${felix.home}/lib/ext/org.apache.servicemix.bundles.commons-httpclient-3.1_7.jar \
	 file:${felix.home}/lib/ext/com.springsource.org.apache.commons.beanutils-1.7.0.jar \
	 file:${felix.home}/lib/ext/org.apache.servicemix.bundles.wsdl4j-1.6.1_1.jar \
	 file:${felix.home}/lib/ext/org.apache.servicemix.bundles.xmlschema-1.4.3_1.jar \
	 file:${felix.home}/lib/ext/org.apache.servicemix.bundles.xmlresolver-1.2_1.jar \
	 file:${felix.home}/lib/ext/org.apache.servicemix.bundles.asm-2.2.3_1.jar \
	 file:${felix.home}/lib/ext/org.apache.servicemix.bundles.xerces-2.9.1_3.jar \
	 file:${felix.home}/lib/ext/org.apache.servicemix.bundles.cglib-2.2_2.jar \
	 file:${felix.home}/lib/ext/cxf-bundle-jaxrs-2.2.9.jar \
	 file:${felix.home}/lib/ext/com.springsource.org.cyberneko.html-1.9.13.jar \
	 file:${felix.home}/lib/ext/org.apache.servicemix.bundles.bcel-5.2_3.jar \
	 file:${felix.home}/lib/ext/com.springsource.org.apache.xalan-2.7.1.jar \
	 file:${felix.home}/lib/ext/com.springsource.org.apache.xml.serializer-2.7.1.jar \
	 file:${felix.home}/lib/ext/com.springsource.org.jdom-1.0.0.jar \
	 file:${felix.home}/lib/ext/org.apache.servicemix.bundles.rome-1.0_2.jar \
	 file:${felix.home}/lib/ext/jackson-core-lgpl-1.8.1.jar \
	 file:${felix.home}/lib/ext/jackson-mapper-lgpl-1.8.1.jar \
	 file:${felix.home}/lib/ext/spring-osgi-io-1.2.1.jar \
	 file:${felix.home}/lib/ext/spring-osgi-core-1.2.1.jar \
	 file:${felix.home}/lib/ext/spring-osgi-extender-1.2.1.jar \
	 file:${felix.home}/lib/ext/spring-core-3.1.0.RELEASE.jar \
	 file:${felix.home}/lib/ext/spring-asm-3.1.0.RELEASE.jar \
	 file:${felix.home}/lib/ext/spring-aop-3.1.0.RELEASE.jar \
	 file:${felix.home}/lib/ext/spring-beans-3.1.0.RELEASE.jar \
	 file:${felix.home}/lib/ext/spring-expression-3.1.0.RELEASE.jar \
	 file:${felix.home}/lib/ext/spring-tx-3.1.0.RELEASE.jar \
	 file:${felix.home}/lib/ext/spring-context-3.1.0.RELEASE.jar \
	 file:${felix.home}/lib/ext/spring-context-support-3.1.0.RELEASE.jar \
	 file:${felix.home}/lib/ext/spring-web-3.1.0.RELEASE.jar \
	 file:${felix.home}/lib/ext/spring-security-core-3.1.0.RELEASE.jar \
	 file:${felix.home}/lib/ext/spring-security-config-3.1.0.RELEASE.jar \
	 file:${felix.home}/lib/ext/spring-security-web-3.1.0.RELEASE.jar \
	 file:${felix.home}/lib/ext/httpcore-osgi-4.2.4.jar \
	 file:${felix.home}/lib/ext/httpclient-osgi-4.2.5.jar \
	 file:${felix.home}/lib/ext/tika-core-1.1.jar \
	 file:${felix.home}/lib/ext/tika-bundle-1.1.jar \
	 file:${felix.home}/lib/ext/org.eclipse.persistence.antlr-2.0.2.jar \
	 file:${felix.home}/lib/ext/org.eclipse.persistence.asm-2.0.2.jar \
	 file:${felix.home}/lib/ext/org.eclipse.persistence.core-2.0.2.jar \
	 file:${felix.home}/lib/ext/org.eclipse.persistence.jpa-2.0.2.jar \
	 file:${felix.home}/lib/ext/jolokia-osgi-1.0.4.jar

	#NB:  When adding the following jars to the list above, you must add a 
	#     backslash (\) to the end of the line above and then *move* the new lines
	#     from where they are to the bottom of the list.  If you uncomment them
	#     in place they will silently be ignored.

	# Add for LDAP authentication support
	# file:${felix.home}/lib/ext/org.springframework.ldap-1.3.1.RELEASE.jar \
	# file:${felix.home}/lib/ext/spring-security-ldap-3.1.0.RELEASE.jar \

	# Add for CAS support
	# Also must enable OpenID support
	# file:${felix.home}/lib/ext/com.springsource.org.apache.xml.security-1.4.2.jar \
	# file:${felix.home}/lib/ext/com.springsource.org.opensaml-1.1.0.jar \
	# file:${felix.home}/lib/ext/spring-security-cas-3.1.0.RELEASE.jar \
	# file:${felix.home}/lib/ext/com.springsource.org.jasig.cas.client-3.1.12.jar \

	# Add for OpenID support
	# These are also required for CAS support
	# file:${felix.home}/lib/ext/com.springsource.org.openid4java-0.9.5.jar \
	# file:${felix.home}/lib/ext/spring-security-openid-3.1.0.RELEASE.jar \

	#
	# Bundle config properties.
	#

	org.osgi.service.http.port=8080
	obr.repository.url=http://felix.apache.org/obr/releases.xml

	# Enable the Felix Http Service
	org.apache.felix.http.enable=true
	org.apache.felix.http.jettyEnabled=true

	# Enable the Felix Http Service's whiteboard pattern implementation
	org.apache.felix.http.whiteboardEnabled=true

	# Increase the connection timeout to 5 minutes in order to give the workflow some time to start after ingest.
	org.apache.felix.http.timeout=300000
		
	"""
}

Main.main(args)



