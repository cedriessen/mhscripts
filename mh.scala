#!/bin/sh
# developed with Scala 2.9.2
# updated to run under Scala 2.10.2
# updated to run under Scala 2.11.2
exec scala -feature -language:implicitConversions -save -deprecation "$0" "$@"
!#
import java.io.File
import java.io.InputStream
import java.util.Date
import scala.io.Source
import scala.sys.process._
import scala.xml.NodeSeq
import scala.xml.XML
import scala.util._

object Deploy {
	import EitherImplicits._
	import ProcessImplicits._
	import Pipe._
	import Trial._

	/* Base config
	 * ----------- */

  // directory structure
  // -------------------
  // $mhVersion/$version/felix
  // 
  // $mhVersion=absolute_base_path
  // $version=path_element
  // 
  // $mhVersion/$version must contain the "version.cfg"

	val mhHome = "/Users/ced/dev/mh"
	val mhVersions = mhHome + "/versions"
	val mhDev = mhHome + "/matterhorn"
	val mhDevFile = new File(mhDev)
	val versionCfgFile = "version.cfg"

  val vagrantTarget = "/Users/ced/dev/mh/systems/vagrant/share/matterhorn"

	/* Types
	 * ----- */

	sealed trait Flavor
	case object V14 extends Flavor
	case object V13 extends Flavor

	sealed abstract class Err(val msg: String)
	final case class ErrParam(override val msg: String) extends Err(msg)
  final case class ErrExec(override val msg: String) extends Err(msg)
  final case class ErrCfg(override val msg: String) extends Err(msg)

	case class VersionCfg(flavor: Flavor, baseDir: String, mvnOpts: Option[String]) {
		def ofFlavor(flv: Flavor): Option[VersionCfg] = Some(this) filter (_.flavor == flv)
	}

	type Valid[A] = Either[Err, A]

	/* Main code
	 * --------- */

  def main(args: Array[String]) {
		val startTime = System.currentTimeMillis()
    val opts = parseCmdLine(Opts(), args.toList)
    // print some environment info
    println(<s>mhVersions: {mhVersions}
              |     mhDev: {mhDev}</s>.text.stripMargin)
    // dispatch commands
		val result: Valid[Any] = opts.command match {
			case Some("deploy") => cmdDeploy(opts)
      case Some("vagrantdeploy") => cmdVagrantDeploy(opts)
			case Some("allprofiles") => cmdBuildAllProfiles(opts)
			case Some("test") => cmdIntegrationTest(opts)
			case Some("jrebel") => cmdJrebel(opts)
			case Some("javadoc") => cmdJavadoc(opts)
		  case Some("deployconfig") => cmdDeployConfig(opts)
      case Some("lastmodified") => cmdLastModified(opts)
			case Some(x) => ErrParam(s"$x is an unknown command").fail
			case _ => ErrParam("Please provide a command").fail
		}
		// print the results
		result match {
			case Left(ErrParam(a)) =>
				println(a)
				println(help)
			case Left(a) =>
				println(a.msg)
			case _ =>
				val millis = System.currentTimeMillis() - startTime
				println(s"""result: $result
				 					 |  time: ${if (millis > 60000) "%.2f min".format(millis / 60000.0) else "%d sec".format(millis / 1000)}""".stripMargin)
	  }
  }

	/** Handle command "deploy". */
	def cmdDeploy(opts: Opts) = {
		// get the current branch name
		val branch = Process("git branch", mhDevFile).lineStream.filter(_.startsWith("*")).head.drop(2)
		val buildNumber = {
			val commit = Process("git rev-parse --short head", mhDevFile).lineStream.head.trim
			Process("git status --porcelain --untracked-files=no").lineStream.isEmpty match {
				case true => commit
				case false =>
					val date = (new Date).toString map {
						case c if c.isLetterOrDigit => c
						case _ => '-'
					}
					s"$commit-$date"
			}
		}
		// get the current db version or use "?"
		val dbVersion = Process("git log -1 --format=%ad_%h --date=short -- modules/matterhorn-db/src/main/resources/mysql5.sql", mhDevFile)
		  .lineStream.headOption.map(_.trim).getOrElse("?")
		// run maven
		for (cfg <- loadVersionCfg(opts)) yield {
			val deployTo = cfg.flavor match {
				case V14 => s"${cfg.baseDir}/felix"
				case V13 => s"${cfg.baseDir}/felix/matterhorn"
			}
			// create maven command line
			import CmdLineBuilder._
			val mvn: CmdLine = ("mvn"
				++? (opts.clean, "clean")
				+++ "install"
				+++ (opts.test map mvnOptTest)
				+++ (opts.checkStyle map mvnOptCheckstyle)
				+++ (s"-DdeployTo=$deployTo")
				+++ (s"-Dbuild.number=$buildNumber")
				+++ (s"-Dmh.db.version=$dbVersion")
        +++ opts.additionalOpts
				+++ cfg.mvnOpts)
			println(<s>     opts: {opts}
								|   config: {cfg}
								|executing: {mvn}</s>.text.stripMargin)
			// run maven
			opts.modules match {
			  case Nil => // no modules -> deploy all
					println(s"Full deployment of branch $branch to ${cfg.baseDir} with flavor ${cfg.flavor}")
					runInDevHandled(mvn)(handleMvnOut)
				case modules =>
					println(s"Deploying modules ${modules mkString ", "} of branch $branch to $cfg.baseDir with flavor $cfg.flavor")
          val builtModules =
            (modules flatMap (module => safeFile(s"$mhDev/modules/$module").right.toOption)
                     takeWhile (moduleDir => Process(mvn, moduleDir).processLines(handleMvnOut) == 0))
          if (builtModules.size == modules.size)
            "All modules built successfully".success
          else
            "Build abandoned due to failed module build".fail
			}
		}
	}

  def cmdVagrantDeploy(opts: Opts) = {
    // todo Copy pasted from cmdDeploy. Better share some code!
  	// get the current branch name
		val branch = Process("git branch", mhDevFile).lineStream.filter(_.startsWith("*")).head.drop(2)
		val commit = Process("git rev-parse --short head", mhDevFile).lineStream.head.trim
		// get the current db version or use "?"
		val dbVersion = Process("git log -1 --format=%ad_%h --date=short -- modules/matterhorn-db/src/main/resources/mysql5.sql", mhDevFile)
		  .lineStream.headOption.map(_.trim).getOrElse("?")
		// run maven
    import CmdLineBuilder._
    val mvn: CmdLine = ("mvn"
      ++? (opts.clean, "clean")
      +++ "install"
      +++ (opts.test map mvnOptTest)
      +++ (opts.checkStyle map mvnOptCheckstyle)
      +++ s"-DdeployTo=$vagrantTarget"
      +++ s"-Dbuild.number=$commit"
      +++ s"-Dmh.db.version=$dbVersion"
      +++ opts.additionalOpts)
    println(<s>     opts: {opts}
              |executing: {mvn}</s>.text.stripMargin)
    // run maven
    opts.modules match {
      case Nil => // no modules -> deploy all
        println(s"Full deployment of branch $branch to $vagrantTarget")
        runInDevHandled(mvn)(handleMvnOut)
      case modules =>
        println(s"Deploying modules ${modules mkString ", "} of branch $branch to $vagrantTarget")
        val builtModules =
          (modules flatMap (module => safeFile(s"$mhDev/modules/$module").right.toOption)
                   takeWhile (moduleDir => Process(mvn, moduleDir).processLines(handleMvnOut) == 0))
        if (builtModules.size == modules.size)
          "All modules built successfully".success
        else
          ErrExec("Build abandoned due to failed module build").fail
    }
  }

	/** Handle command "jrebel". */
	def cmdJrebel(opts: Opts) = runInDevSimple(s"mvn jrebel:generate -Drebel.xml.dir=src/main/resources -Drebel.generate.show=true $allProfilesAsMvnArg")

	/** Handle command "test" (integration testing). */
	def cmdIntegrationTest(opts: Opts) = runInDevSimple("mvn -Ptest -Dharness=server")

  /** Handle command "allprofiles". */
	def cmdBuildAllProfiles(opts: Opts) = {
    import CmdLineBuilder._
    val mvn: CmdLine = ("mvn"
      ++? (opts.clean, "clean")
			+++ "install"
			+++ (opts.checkStyle map mvnOptCheckstyle)
			+++ (opts.test map mvnOptTest)
      +++ allProfilesAsMvnArg
      +++ opts.additionalOpts)
    println("executing: " + mvn)
    runInDevHandled(mvn)(handleMvnOut)
	}

	/** Handle command "javadoc". */
	def cmdJavadoc(opts: Opts) = runInDevSimple(s"mvn javadoc:javadoc ${mvnOptCheckstyle(false)}")

	// todo
	def cmdDeployConfig(opts: Opts) =
		for {
			cfg_ <- loadVersionCfg(opts);
			cfg <- (cfg_ ofFlavor V14) failed ErrCfg(s"Version config $cfg_ does not have the required flavor $V14")
			_ = println(s"Copy config $mhDev -> ${cfg.baseDir}/felix/")
			_ <- runInDevSimple(s"cp -R $mhDev/etc/ ${cfg.baseDir}/felix/etc/")
			cp2 <- runInDevSimple(s"cp -R $mhDev/bin/ ${cfg.baseDir}/felix/bin/")
		} yield
			cp2

  /** Handle command "lastmodified" */
  def cmdLastModified(opts: Opts) = {
    val Module = """^.*?\bmodules/(.*?)/.*""".r
    val modules = for (Module(m) <- processInDev("git status --porcelain").lineStream) yield m
    println(s"""-m "${modules.distinct.mkString(",")}"""")
    true.success
  }


	/* Helper functions
	 * ---------------- */

	def mvnOptCheckstyle(enable: Boolean) = s"-Dcheckstyle.skip=${!enable}"

	def mvnOptTest(enable: Boolean) = s"-Dmaven.test.skip=${!enable}"

	/** Get a list of all maven profiles. */
	def allProfiles = (for {
    line <- processInDev("mvn help:all-profiles").lineStream
    if line.contains("Profile Id") && !line.contains("test") && !line.contains("capture")
  } yield
    line.split("""\s+""")(3)).distinct

	def allProfilesAsMvnArg = "-P" + allProfiles.mkString(",")

  /** Handle maven process output. */
  def handleMvnOut(line: String) = line match {
    case CheckstyleError(module) =>
      printCheckstyle(module)
      false
    case TestError(module) =>
      println("[TEST FAILED] " + line)
      false
    case MavenResume(module) =>
      println("Resume with -rf :" + module)
      false
    case _ =>
      println(line)
      true
  }

  /** Run `cmd` in development directory using handler `f` to process the output. */
  def runInDevHandled(cmd: String)(f: String => Boolean): Valid[Int] = processInDev(cmd).processLines(f) |> handleExitValue

	/** Run `cmd` in development directory, print all its output to the console and return the exit value. */
	def runInDevSimple(cmd: String): Valid[Int] = processInDev(cmd) ! ProcessLogger(a => println(a)) |> handleExitValue

  /** Turn the exit value of a process into an either. */
	val handleExitValue: Int => Valid[Int] = {
		case 0 => 0.success
		case a => ErrExec(a.toString).fail
	}

	/** Create a process to be run in the development directory. */
	def processInDev(cmd: String) = Process(cmd, new File(mhDev))

	/** Load the MH installation flavor. */
	def loadFlavor(flavorDir: String): Option[String] =
		Source.fromFile(s"$flavorDir/flavor.mh").getLines.take(1).toList.headOption.tryOption.flatten

	def loadVersionCfg(opts: Opts): Valid[VersionCfg] = for {
		version <- opts.version failed ErrParam("Please provide a version")
		mhVersionDir = mhVersions + "/" + version
		versionCfg <- loadVersionCfg(mhVersionDir)
	} yield
		versionCfg

	/** Load and parse the config for the selected version. */
	def loadVersionCfg(versionDir: String): Valid[VersionCfg] = {
		def opt(ns: NodeSeq): Option[String] = ns.text.trim match {
			case "" => None
			case x => Some(x)
		}
		def toFlavor(s: String) = s match {
			case "1.4" => V14.success
			case "1.3" => V13.success
			case x => ErrCfg(x).fail
		}
		val cfgFile = try {
			XML.loadFile(versionDir + "/" + versionCfgFile).success
		} catch {
			case _: Throwable => ErrCfg("Please provide a " + versionCfgFile).fail
		}
		for {
			cfg <- cfgFile
			flavorString <- opt(cfg \\ "flavor") failed ErrCfg("Please provide a flavor")
			flavor <- toFlavor(flavorString)
		} yield
			VersionCfg(flavor, versionDir, opt(cfg \\ "mvn-opts"))
	}

	/** Safe file creation. Ensures its existence. */
	def safeFile(file: String): Either[String, File] = {
		val f = new File(file)
		if (f.exists) Right(f) else Left(file + " does not exist")
	}

	val CheckstyleError = """\[ERROR\].*?on project (.*?): Failed during checkstyle execution.*""".r
	val TestError = """\[ERROR\].*?on project (.*?): There are test failures.*""".r
	val MavenResume = """\[ERROR\].*?mvn <goals> -rf :(.*?)""".r

	def printCheckstyle(module: String) {
		println("[CHECKSTYLE ERROR] " + module)
		val checkstyle = XML.loadFile(mhDev + "/modules/" + module + "/target/checkstyle-result.xml")
		for {
			file <- checkstyle \\ "file"
			errors = file \ "error"
			if !errors.isEmpty
		} {
			val fileName = (file \ "@name").text
			println("[FILE] " + fileName.drop(mhDev.length))
			for (error <- errors) {
				val line = (error \ "@line").text
				val col = (error \ "@column").text
				val msg = (error \ "@message").text
				println(<s>{"%5s".format(line)}:{"%-3s".format(col)} {msg}</s>.text)
			}
		}
	}

	case class Opts(
		command: Option[String] = None,
		modules: List[String] = Nil,
		additionalOpts: Option[String] = None,
		checkStyle: Option[Boolean] = None,
		test:Option[Boolean] = None,
		clean: Boolean = false,
		version: Option[String] = None)

	def help = s"""deploy               build and deploy
	             |  -v <version>       target dir name
	             |  [-m <module>,...]  modules, comma separated list
	             |  [-p <mvn_params>]  additional mvn parameters
	             |  [--nocheck|-C]     no checkstyle
	             |  [--notest|-T]      no unit tests
	             |  [-c]               clean
               |
               |vagrantdeploy        deploy to shared Vagrant directory
               |                     $vagrantTarget
	             |
	             |test                 run server integration test
	             |
	             |allprofiles          build all profiles without deployment
	             |  [-c]               clean
	             |  [-p <mvn_params>]  additional mvn parameters
	             |  [--nocheck|-C]     no checkstyle
	             |  [--notest|-T]      no unit tests							 
							 |
							 |jrebel               generate rebel.xml for each module of the project
							 |javadoc              generate javadoc
							 |deployconfig         copy 1.4 config from development to deployment directory
               |lastmodified         print a list of last modified modules
	             |""".stripMargin

  def parseCmdLine(opts: Opts, cmdline: List[String]): Opts = {
    cmdline match {
      case "-m" :: modules :: xs =>
        parseCmdLine(opts.copy(modules = modules.split(",").toList), xs)
      case "-p" :: additionalOpts :: xs =>
        parseCmdLine(opts.copy(additionalOpts = Some(additionalOpts)), xs)
		  case ("--nocheck" | "-C") :: xs =>
				parseCmdLine(opts.copy(checkStyle = Some(false)), xs)
		  case ("--notest" | "-T") :: xs =>
				parseCmdLine(opts.copy(test = Some(false)), xs)
      case "-v" :: version :: xs =>
        parseCmdLine(opts.copy(version = Some(version)), xs)
			case "-c" :: xs =>
				parseCmdLine(opts.copy(clean = true), xs)
			case cmd :: xs =>
				parseCmdLine(opts.copy(command = Some(cmd)), xs)
      case _ =>
        opts
    }
  }
}

object CmdLineBuilder {
	final class CmdLine(line: List[String]) {
		/** Append an element. */
		def +++(e: String) = new CmdLine(e :: line)
		/** Append multiple elements. */
		def +++(es: List[String]) = new CmdLine(es ++ line)
		/** Append element if not none. */
		def +++(e: Option[String]) = e.map(e => new CmdLine(e :: line)).getOrElse(this)
		/** Append element if predicate is true. */
		def ++?(p: Boolean, e: String) = if (p) +++(e) else this
		override def toString = line.reverse.mkString(" ")
	}

	implicit def _String_CmdLine(a: String): CmdLine = new CmdLine(a :: Nil)
	implicit def _CmdLine_String(a: CmdLine): String = a.toString
}

object ProcessImplicits {
	final class ProcessWrapper(p: ProcessBuilder) {
		/**
		 * Process line by line of what the process writes to stdout by function f.
		 * @param f return false on error
		 * @return exit value of process or 1 if f returned false
		 */
		def processLines(f: String => Boolean): Int = {
			var ok = false
			def scan(in: InputStream) {
				// apply f first since && is lazy but we want to handle _all_ lines even if a previous line contained an error
				ok = (true /: Source.fromInputStream(in).getLines)((ok, line) => f(line) && ok)
				in.close()
			}
			val exit = p.run(new ProcessIO(_.close(), scan, _.close())).exitValue
			if (exit != 0) exit else if (!ok) 1 else 0
		}
	}

	implicit def _ProcessBuilder_ProcessWrapper(p: ProcessBuilder): ProcessWrapper = new ProcessWrapper(p)
}

object EitherImplicits {
	final class ToLeft[A](a: A) {
		def fail = Left(a)
	}

	final class ToRight[B](b: B) {
		def success = Right(b)
	}

	final class OptionFailed[A](a: Option[A]) {
		def failed[B](left: => B) = a.toRight(left)
	}

	final class OptionToEither

	implicit def _Any_Left[A](a: A): ToLeft[A] = new ToLeft(a)

	implicit def _Any_Right[B](b: B): ToRight[B] = new ToRight(b)

	implicit def _Either_RightProjection[A, B](a: Either[A, B]): Either.RightProjection[A, B] = a.right

	implicit def _Option_OptionFailed[A](a: Option[A]): OptionFailed[A] = new OptionFailed(a)

	def test() {
		val s: Either[String, Int] = 1.success
		val f: Either[String, Int] = "hello".fail
		println(f)
		println(s)
		val r = for {
			v1 <- s
			v2 <- s
			v3 <- s
		} yield v1 + v2 + v3
		println("r=" + r)
	}
}

object Pipe {
	final class Pipe[A](a: A) {
    def |>[B](f: A => B): B = f(a)
  }
  implicit def _Any_Pipe[A](a: A): Pipe[A] = new Pipe(a)
}

object Trial {
	final class TryIt[A](a: => A) {
		def tryOption: Option[A] = try {
			Some(a)
		} catch {
			case _: Throwable => None
		}
	}

	implicit def _Any_TryIt[A](a: => A): TryIt[A] = new TryIt(a)
}

Deploy.main(args)



