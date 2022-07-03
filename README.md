# factio

Fact importing and exporting for the Flix programming language.
Imports and exports CSV, SQLite.

Note - this project is largely moth-balled. I use the following projects 
for reading data into Flix:

https://github.com/stephentetley/csvio (Csv files)

https://github.com/stephentetley/fix-basicdb (SQLite / JDBC etc.)

https://github.com/stephentetley/sheetio (Excel files)

## Build instructions

July 2022 - `factio` now builds as a Flix package. 

Compatible *.pkg and *.jar files for the dependencies are included in the folder `lib`.

`src-java` contains a some Java wrappers that are compile to `factiojava-n.n.jar`. A 
verion is included in `lib`.

Dependencies:

Apache Commons CSV
Apache Commons IO
sqlite-jdbc Java library

https://github.com/stephentetley/flix-regex
https://github.com/stephentetley/flix-sandbox
https://github.com/stephentetley/charset-locale
https://github.com/stephentetley/collection-interop

