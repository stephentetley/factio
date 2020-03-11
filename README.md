# factio

Fact importing and exporting for the Flix programming language.
Imports CSV, SQLite and flat text files, exports CSV.

## Build instructions

I currently build factio within a Flix compiler project in IntelliJ.

Acquire `sqlite-jdbc-3.27.2.1.jar` and Apache `commons-csv-1.7.jar`
and drop them in Flix's `lib` folder.

https://bitbucket.org/xerial/sqlite-jdbc/downloads/

https://commons.apache.org/proper/commons-csv/download_csv.cgi

In Flix `main/src/flix/runtime` create a folder `factio` and drop in the Java
modules from Factio `src/java`.

In Flix `main/src/library` create a folder `factio` and drop in the Flix
modules from Factio `src/flix`.

Edit Flix `main/src/ca/uwaterloo/flix/api/Flix.scala` to include the 
Factio Flix modules, i.e. add this code to the list of libraries:

~~~

    "FactIOBase.flix" -> LocalResource.get("/library/factio/FactIOBase.flix"),
    "ValidationExtras.flix" -> LocalResource.get("/library/factio/ValidationExtras.flix"),
    "Strategies.flix" -> LocalResource.get("/library/factio/Strategies.flix"),
    "CsvImport.flix" -> LocalResource.get("/library/factio/CsvImport.flix"),
    "SQLiteImport.flix" -> LocalResource.get("/library/factio/SQLiteImport.flix"),
    "LinesImport.flix" -> LocalResource.get("/library/factio/LinesImport.flix"),
    "CsvExport.flix" -> LocalResource.get("/library/factio/CsvExport.flix"),

~~~

Build / rebuild the Flix compiler.

If building fails it will probably be due to missing String / Array functions - please 
contact me for assistance.

Run the tests - currently you will need to edit the paths to the sample data.