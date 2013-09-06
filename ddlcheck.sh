#!/bin/sh
exec scala -save -deprecation "$0" "$@"
!#

// developed with Scala 2.9.2
import scala.io._

object CheckDdl {
  val CreateTable = "create table.*?([a-z_]+).*".r

  def main(args: Array[String]) {
    val ddlSource = Source.fromFile(args(0)).getLines.map(_.toLowerCase).toList
    val tables = Map.empty ++ (
			for ((CreateTable(table), lineNr) <- ddlSource.zipWithIndex) 
			yield (table, lineNr))
		val forwardReferences = for ((line, lineNr) <- ddlSource.zipWithIndex; 
		     word <- line.split("\\W").filterNot(_.isEmpty);
		     creationLineNr <- tables.get(word)
		     if lineNr < creationLineNr) 
		yield (word, lineNr, creationLineNr)		  
		// 
		println("TABLES")
    for ((table, creationLineNr) <- tables) 
			println("%s LINE %d".format(table, creationLineNr))
	  println("\nFORWARD REFERENCES")
		for ((ref, lineNr, creationLineNr) <- forwardReferences)
			println("Table %s is used in line %d but gets created in line %d".format(ref, lineNr, creationLineNr))
  }
}
