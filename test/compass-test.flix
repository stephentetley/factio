
namespace CompassTest {

    use FactIO/CsvImport.{CsvRow, CsvResult};
    use FactIO.CsvRowEvaluator;
    use FactIO/JdbcImport.{JdbcRow, JdbcResult};
    use FactIO.JdbcRowEvaluator;
    use FactIO.FlatFileLineEvaluator;

    @test
    def testAll(): Int32 & Impure =
        csv01();
        sqlite01();
        flatFile01();
        0


    def printResult(rarr: Result[Array[a], String]): Unit & Impure with ToString[a] = match rarr {
        case Ok(arr) => {println("Success:"); Array.foreach(x -> println("${x}"), arr) }
        case Err(msg) => println("Error: ${msg}")
    }


    rel Direction(name: String)


    def csv01(): Unit & Impure =
        use Result.flatMap;
        use FactIO/CsvFormat.{withFirstRecordAsHeader};
        let step = () -> {
            let path    = FlixSandbox/System/FilePath.new("e:/coding/flix/factio/data/compass.csv");
            let iter    = FactIO/CsvImport.newCsvCursor(withFirstRecordAsHeader(FactIO/CsvFormat.default()), FlixSandbox/Text/Charset.utf_8(), path);
            let* relns  = FactIO/CsvImport.importRows(csvDirection1(), iter);
            let arr = query relns select (x) from Direction(x);
            Ok(arr)
        };
        step() |> printResult
        
    def csvDirection1(): CsvRowEvaluator[#{Direction | r}] = 
        use FactIO/CsvRowEvaluator.{map, getStringAt};
        map(s1 -> #{ Direction(s1). }, getStringAt(0))

        
    pub def sqlite01(): Unit & Impure =
        use Result.flatMap;
        let step = () -> {
            let path    = FlixSandbox/System/FilePath.new("e:/coding/flix/factio/data/compass.sqlite");
            let sql     = "SELECT cardinal_name FROM cardinals";
            let iter    = FactIO/JdbcImport.newSQLiteCursor(sql = sql, path);
            let* relns  = FactIO/JdbcImport.importRows(sqliteDirection1(), iter);
            let arr     = query relns select (x) from Direction(x);        
            Ok(arr)
        };
        step() |> printResult

            
    def sqliteDirection1(): JdbcRowEvaluator[#{Direction | r}] = 
        use FactIO/JdbcRowEvaluator.{map, getStringNamed};
        map(s1 -> #{ Direction(s1). }, getStringNamed("cardinal_name"))




    pub def flatFile01(): Unit & Impure =
        use Result.flatMap;    
        let step = () -> {
            let path    = FlixSandbox/System/FilePath.new("e:/coding/flix/factio/data/compass.txt");
            let iter    = FactIO/FlatFileImport.newFlatFileCursor(FlixSandbox/Text/Charset.utf_8(), path);
            let* relns  = FactIO/FlatFileImport.importRows(flatfileDirection1(), iter);
            let arr = query relns select (x) from Direction(x);
            Ok(arr)
        };
        step() |> printResult
        

    def flatfileDirection1(): FlatFileLineEvaluator[#{ Direction | r}] = 
        use FactIO/FlatFileLineEvaluator.{flatMap, content, map};
        map(s1 -> #{ Direction(s1). }, content())

}