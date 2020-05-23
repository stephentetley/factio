# factio

Fact importing and exporting for the Flix programming language.
Imports CSV, SQLite and flat text files, and exports CSV.

## Build instructions

I currently build factio within a Flix compiler project in IntelliJ.

Acquire `sqlite-jdbc-3.31.1.jar` and Apache `commons-csv-1.8.jar`
and Apache `commons-io-2.6.jar` and drop them in Flix's `lib` folder.

https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/

https://commons.apache.org/proper/commons-csv/download_csv.cgi

https://commons.apache.org/proper/commons-io/download_io.cgi

In Flix `main/src/flix/runtime` create a folder `factio` and drop in the Java
modules from Factio `src/java`.

In Flix `main/src/library` create a folder `spt/factio` and drop in the Flix
modules from Factio `src/flix`.

Edit Flix `main/src/ca/uwaterloo/flix/api/Flix.scala` to include the 
Factio Flix modules, i.e. add this code to the list of libraries:

~~~ {.Scala}

    "spt/factio/Internal/ImportStrategies.flix" -> LocalResource.get("/library/spt/factio/Internal/ImportStrategies.flix"),
    "spt/factio/Internal/LinesIterator.flix" -> LocalResource.get("/library/spt/factio/Internal/LinesIterator.flix"),
    "spt/factio/CsvFormat.flix" -> LocalResource.get("/library/spt/factio/CsvFormat.flix"),
    "spt/factio/CsvRowEvaluator.flix" -> LocalResource.get("/library/spt/factio/CsvRowEvaluator.flix"),
    "spt/factio/CsvImport.flix" -> LocalResource.get("/library/spt/factio/CsvImport.flix"),
    "spt/factio/CsvExport.flix" -> LocalResource.get("/library/spt/factio/CsvExport.flix"),
    "spt/factio/SQLiteRowEvaluator.flix" -> LocalResource.get("/library/spt/factio/SQLiteRowEvaluator.flix"),
    "spt/factio/SQLiteImport.flix" -> LocalResource.get("/library/spt/factio/SQLiteImport.flix"),
    "spt/factio/LineEvaluator.flix" -> LocalResource.get("/library/spt/factio/LineEvaluator.flix"),
    "spt/factio/LinesImporter.flix" -> LocalResource.get("/library/spt/factio/LinesImporter.flix"),

~~~

**Note** Factio depends on `flix-sandbox` an incubator project geared towards adding 
more "base" modules to Flix. 

Add at least the Text/Charset, Text/Regex and System/Error modules from here:

https://github.com/stephentetley/flix-sandbox

Build / rebuild the Flix compiler.

Run the tests - currently you will need to edit the paths to the sample data.