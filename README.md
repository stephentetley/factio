# factio

Fact importing and exporting for the Flix programming language.
Imports and exports CSV and SQLite.

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
    "CsvFormat.flix" -> LocalResource.get("/src/library/spt/factio/CsvFormat.flix"),
    "CsvRowEvaluator.flix" -> LocalResource.get("/src/library/spt/factio/CsvRowEvaluator.flix"),
    "CsvImport.flix" -> LocalResource.get("/src/library/spt/factio/CsvImport.flix"),
    "CsvExport.flix" -> LocalResource.get("/src/library/spt/factio/CsvExport.flix"),
    "Internal/SQLite/Output.flix" -> LocalResource.get("/src/library/spt/factio/Internal/SQLite/Output.flix"),
    "Internal/SQLite/PreparedStatement.flix" -> LocalResource.get("/src/library/spt/factio/Internal/SQLite/PreparedStatement.flix"),
    "SQLiteRowEvaluator.flix" -> LocalResource.get("/src/library/spt/factio/SQLiteRowEvaluator.flix"),
    "SQLiteRowWriter.flix" -> LocalResource.get("/src/library/spt/factio/SQLiteRowWriter.flix"),
    "SQLiteImport.flix" -> LocalResource.get("/src/library/spt/factio/SQLiteImport.flix"),
    "SQLiteExport.flix" -> LocalResource.get("/src/library/spt/factio/SQLiteExport.flix"),
    "FlatFileLineEvaluator.flix" -> LocalResource.get("/src/library/spt/factio/FlatFileLineEvaluator.flix"),
    "FlatFileImport.flix" -> LocalResource.get("/src/library/spt/factio/FlatFileImport.flix"),
    
~~~

**Note** Factio depends on `flix-sandbox` an incubator project geared towards adding 
more "base" modules to Flix. 

Add at least the Text/Charset, Text/Regex and System/Error modules from here:

https://github.com/stephentetley/flix-sandbox

Build / rebuild the Flix compiler.

Run the demos - currently you will need to edit the paths to the sample data.
