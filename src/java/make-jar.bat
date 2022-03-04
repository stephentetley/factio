
javac -cp "../../lib/commons-csv-1.8.jar;../../lib/commons-io-2.6.jar;../../lib/sqlite-jdbc-3.36.0.3.jar" -d ./build  flixspt/factio/csv/*.java flixspt/factio/flatfile/*.java flixspt/factio/jdbc/*.java

cd build 

jar cf factiojava-1.1.jar ./flixspt/factio/csv/*.class ./flixspt/factio/flatfile/*.class ./flixspt/factio/jdbc/*.class

