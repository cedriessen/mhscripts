#!/bin/sh
# built with Scala 2.9.2
exec scala -save -deprecation "$0" "$@"
!#
import java.io.File
import java.io.InputStream
import scala.io.Source
import scala.sys.process._
import scala.xml.NodeSeq
import scala.xml.XML

object Deploy {
	import EitherImplicits._
	import ProcessImplicits._
	import Pipe._
	
	val mhHome = "/Users/ced/dev/matterhorn"
	val mhVersions = mhHome + "/versions"
	val mhDev = mhHome + "/matterhorn"
	val versionCfgFile = "version.cfg"
	
	sealed trait Flavor
	final case object V14 extends Flavor
	final case object V13 extends Flavor
		
	sealed abstract class Err(msg: String)
	final case class ErrParam(msg: String) extends Err(msg)
  final case class ErrExec(msg: String) extends Err(msg) 
  final case class ErrCfg(msg: String) extends Err(msg) 

	case class VersionCfg(flavor: Flavor, baseDir: String, mvnOpts: Option[String])

  def main(args: Array[String]) {
		val startTime = System.currentTimeMillis()
    val opts = parseCmdLine(Opts(), args.toList)
    // dispatch commands
		val result: Either[Any, Any] = opts.command match {
			case Some("deploy") => cmdDeploy(opts)
			case Some("test") => cmdIntegrationTest(opts)
			case Some("jrebel") => cmdJrebel(opts)
			case Some(x) => ErrParam(x + " is an unknown command").fail
			case _ => ErrParam("Please provide a command").fail
		}
		// print the results
		result match {
			case Left(ErrParam(a)) => 
				println(a)
				println(help)
			case Left(a) =>
				println(a)
			case _ => 	
				val millis = System.currentTimeMillis() - startTime		
				println(<s>
				          |result: {result}
									|  time: {if (millis > 60000) "%.2f min".format(millis / 60000.0) else "%d sec".format(millis / 1000)}
								  |</s>.text.stripMargin)
	  }
  }

	/** Handle command "deploy". */
	def cmdDeploy(opts: Opts) = {
		// calc flavor and version directory
		def versionCfg: Either[Err, VersionCfg] = for {
			version <- opts.version toRight ErrParam("Please provide a version")
			mhVersionDir = mhVersions + "/" + version
			versionCfg <- loadVersionCfg(mhVersionDir)
		} yield 
			versionCfg
		// get the current branch name
		val branch = Process("git branch", new File(mhDev)).lines.filter(_.startsWith("*")).head.drop(2)		
		val commit = Process("git rev-parse --short head", new File(mhDev)).lines.head.trim
		// run maven
		for (cfg <- versionCfg) yield {
			val deployTo = cfg.flavor match {
				case V14 => cfg.baseDir + "/felix"
				case V13 => cfg.baseDir + "/felix/matterhorn"
			}
			// create maven command line
			import CmdLineBuilder._
			val mvn: CmdLine = ("mvn"
				++? (opts.clean, "clean")
				+++ "install" 
				++? (!opts.test, "-Dmaven.test.skip=true")
				++? (!opts.checkStyle, "-Dcheckstyle.skip=true")
				+++ ("-DdeployTo=" + deployTo)
				+++ ("-Dbuild.number=" + commit)
        +++ opts.additionalOpts
				+++ cfg.mvnOpts)
			println(<s>     opts: {opts}
								|   config: {cfg}
								|executing: {mvn}</s>.text.stripMargin)
			// scan process output					
			def scan(line: String) = line match {
				case CheckstyleError(module) => 
					printCheckstyle(module)
					false
				case TestError(module) =>
					println("[TEST FAILED] " + line)
					false
				case MavenResume(module) =>
					println("Resume with " + mvn + " -rf :" + module)
					false
				case _ => 
					println(line)
					true
			}
			// run maven
			opts.modules match {
			  case Nil => // no modules -> deploy all
					println(<s>Full deployment of branch {branch} to {cfg.baseDir} with flavor {cfg.flavor}</s>.text)
					processInDev(mvn).processLines(scan) |> handleExitValue
				case modules => 
					println(<s>Deploying modules {modules.mkString(", ")} of branch {branch} to {cfg.baseDir} with flavor {cfg.flavor}</s>.text)
					val result = for (module <- modules) 
						yield for (moduleDir <- safeFile(mhDev + "/modules/" + module))
							yield Process(mvn, moduleDir).processLines(scan)
					// todo inspect result and return the appropriate type .fail or .success 		
					result.success		
			}
		}
	}

	/** Handle command "jrebel". */
	def cmdJrebel(opts: Opts) = runInDevSimple("mvn jrebel:generate -Drebel.xml.dir=src/main/resources -Drebel.generate.show=true")
	
	/** Handle command "test" (integration testing). */
	def cmdIntegrationTest(opts: Opts) = runInDevSimple("mvn -Ptest -Dharness=server")
	
	/** Run `cmd` in development directory, print all its output to the console and return the exit value. */
	def runInDevSimple(cmd: String): Either[Err, Int] = processInDev(cmd) ! ProcessLogger(a => println(a)) |> handleExitValue

	val handleExitValue: Int => Either[Err, Int] = {
		case 0 => 0.success
		case a => ErrExec(a.toString).fail
	}

	/** Create a process to be run in the development directory. */
	def processInDev(cmd: String) = Process(cmd, new File(mhDev))

	/** Load the MH installation flavor. */
	def loadFlavor(flavorDir: String): Option[String] = {
		try {
			Source.fromFile(flavorDir + "/flavor.mh").getLines.take(1).toList.headOption
		} catch {
			case _ => None
		}
	}
	
	/** Load and parse the config for the selected version. */
	def loadVersionCfg(versionDir: String): Either[Err, VersionCfg] = {
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
			case _ => ErrCfg("Please provide a " + versionCfgFile).fail
		}
		for {
			cfg <- cfgFile.right
			flavorString <- opt(cfg \\ "flavor") toRight ErrCfg("Please provide a flavor")
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
		checkStyle: Boolean = true,
		test: Boolean = true,
		clean: Boolean = false,
		version: Option[String] = None)
		
	def help = """deploy -v <version> 
	             |      [-m <module>,...]  // modules, comma separated list
	             |      [-p <mvn_params>]  // mvn parameters
	             |      [--nocheck]        // no checkstyle
	             |      [--notest]         // no unit tests 
	             |      [-c]               // clean
	             |test                     // run server integration test""".stripMargin
  
  def parseCmdLine(opts: Opts, cmdline: List[String]): Opts = {
    cmdline match {
      case "-m" :: modules :: xs => 				
        parseCmdLine(opts.copy(modules = modules.split(",").toList), xs)
      case "-p" :: additionalOpts :: xs => 
        parseCmdLine(opts.copy(additionalOpts = Some(additionalOpts)), xs)
		  case "--nocheck" :: xs =>
				parseCmdLine(opts.copy(checkStyle = false), xs)
		  case "--notest" :: xs =>
				parseCmdLine(opts.copy(test = false), xs)
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
	
	final class OptionToEither
	
	implicit def _Any_Left[A](a: A): ToLeft[A] = new ToLeft(a)	
	
	implicit def _Any_Right[B](b: B): ToRight[B] = new ToRight(b)
	
	implicit def _Either_RightProjection[A, B](a: Either[A, B]): Either.RightProjection[A, B] = a.right
	
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
	class Pipe[A](a: A) {
    def |>[B](f: A => B): B = f(a)
  }
  implicit def _Any_Pipe[A](a: A): Pipe[A] = new Pipe(a)
}

Deploy.main(args)



