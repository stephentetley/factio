# factio

Fact importing and exporting for the Flix programming language.
Imports and exports CSV, SQLite.

Note - this project is largely moth-balled. I use the following projects 
for reading data into Flix:

https://github.com/stephentetley/csvio (Csv files)

https://github.com/stephentetley/fix-basicdb (SQLite / JDBC etc.)

https://github.com/stephentetley/sheetio (Excel files)

## Build instructions

Feb 2020 - the Java primitives used by `factio` are now supplied as a library 
jar in the `lib` directory. This means `factio` no longer needs building inside 
the the Flix compiler. To run programs using `factio` the jar libraries in `libs`
must be passed to `flix.jar` via the classpath (i.e. the using the Java `-cp` option).

Warning - `factio` depends on `flix-sandbox`. Building `flix-sandbox` has not yet 
been disengaged from building within a fork of the Flix compiler.

https://github.com/stephentetley/flix-sandbox
