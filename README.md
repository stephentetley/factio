# factio

Fact importing and exporting for the Flix programming language.
Imports CSV, SQLite and flat text files, and exports CSV and SQLite.

## Build instructions

I currently build factio within a Flix compiler project in IntelliJ.

Acquire `sqlite-jdbc-3.31.1.jar` and Apache `commons-csv-1.8.jar`
and Apache `commons-io-2.6.jar` and drop them in Flix's `lib` folder.

https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/

https://commons.apache.org/proper/commons-csv/download_csv.cgi

https://commons.apache.org/proper/commons-io/download_io.cgi

In Flix `main/src/flix/runtime` create a folder `spt/factio` and drop in the Java
modules from Factio `src/java`.

In Flix `main/src/library` create a folder `spt/factio` and drop in the Flix
modules from Factio `src/flix`.

Edit Flix `main/src/ca/uwaterloo/flix/api/Flix.scala` to include the 
Factio Flix modules, i.e. add this code to the list of libraries:

~~~ {.Scala}

   // factio
    "Internal/ImportStrategies.flix" -> LocalResource.get("/src/library/spt/factio/Internal/ImportStrategies.flix"),
    "Csv/CsvFormat.flix" -> LocalResource.get("/src/library/spt/factio/Csv/CsvFormat.flix"),
    "Csv/Export.flix" -> LocalResource.get("/src/library/spt/factio/Csv/Export.flix"),
    "Csv/Import.flix" -> LocalResource.get("/src/library/spt/factio/Csv/Import.flix"),
    "Csv/RowEvaluator.flix" -> LocalResource.get("/src/library/spt/factio/Csv/RowEvaluator.flix"),
    "FlatFile/Internal/LinesIterator.flix" -> LocalResource.get("/src/library/spt/factio/FlatFile/Internal/LinesIterator.flix"),
    "FlatFile/LineEvaluator.flix" -> LocalResource.get("/src/library/spt/factio/FlatFile/LineEvaluator.flix"),
    "FlatFile/RowEvaluator.flix" -> LocalResource.get("/src/library/spt/factio/FlatFile/RowEvaluator.flix"),
    "FlatFile/RowWithHeadersEvaluator.flix" -> LocalResource.get("/src/library/spt/factio/FlatFile/RowWithHeadersEvaluator.flix"),
    "FlatFile/SimpleParser.flix" -> LocalResource.get("/src/library/spt/factio/FlatFile/SimpleParser.flix"),
    "FlatFile/Split.flix" -> LocalResource.get("/src/library/spt/factio/FlatFile/Split.flix"),
    "SQLite/Internal/Output.flix" -> LocalResource.get("/src/library/spt/factio/SQLite/Internal/Output.flix"),
    "SQLite/Internal/PreparedStatement.flix" -> LocalResource.get("/src/library/spt/factio/SQLite/Internal/PreparedStatement.flix"),
    "SQLite/RowWriter.flix" -> LocalResource.get("/src/library/spt/factio/SQLite/RowWriter.flix"),
    "SQLite/Export.flix" -> LocalResource.get("/src/library/spt/factio/SQLite/Export.flix"),
    "SQLite/Import.flix" -> LocalResource.get("/src/library/spt/factio/SQLite/Import.flix"),
    "SQLite/RowEvaluator.flix" -> LocalResource.get("/src/library/spt/factio/SQLite/RowEvaluator.flix"),

~~~

**Note** Factio depends on `flix-sandbox` an incubator project geared towards adding 
more "base" modules to Flix. 

Add at least the Text/Charset, Text/Regex and System/Error modules from here:

https://github.com/stephentetley/flix-sandbox

Build / rebuild the Flix compiler.

Run the demos - currently you will need to edit the paths to the sample data.
