use FactIO/CsvImport.{CsvRow, CsvResult};
use FactIO.CsvRowEvaluator;
use FactIO/JdbcImport.{JdbcRow, JdbcResult};
use FactIO.JdbcRowEvaluator;
use FactIO.FlatFileLineEvaluator;

def main(_args: Array[String]): Int32 & Impure =
    csv01();
    sqlite01();
    flatFile01();
    0


def printResult(rarr: Result[Array[a], String]): Unit & Impure with ToString[a] = match rarr {
    case Ok(arr) => {Console.printLine("Success:"); Array.foreach(x -> Console.printLine("${x}"), arr) }
    case Err(msg) => Console.printLine("Error: ${msg}")
}


rel Direction(name: String)

def makeDirection(name: String): #{Direction | r} =
    Direction(name).


def csv01(): Unit & Impure =
    use Result.flatMap;
    use FactIO/CsvFormat.{withFirstRecordAsHeader};
    let step = () -> {
        let path    = System/FilePath.new("e:/coding/flix/factio/data/compass.csv");
        let* hdl    = FactIO/CsvImport.newCsvReadHandle(FactIO/CsvFormat.default().withFirstRecordAsHeader(), Text/Charset.utf_8(), path);
        let iter    = FactIO/CsvImport.getIterator(hdl);
        let* relns  = FactIO/CsvImport.importRows(csvDirection1(), iter);
        let* _      = FactIO/CsvImport.close(hdl);
        let arr = query relns select (x) from Direction(x);
        Ok(arr)
    };
    step() |> printResult
    
def csvDirection1(): CsvRowEvaluator[#{Direction | r}] = 
    use FactIO/CsvRowEvaluator.{map, getStringAt};
    map(makeDirection, getStringAt(0))

    
pub def sqlite01(): Unit & Impure =
    use Result.flatMap;
    let step = () -> {
        let path    = System/FilePath.new("e:/coding/flix/factio/data/compass.sqlite");
        let query   = "SELECT cardinal_name FROM cardinals";
        let* hdl    = FactIO/JdbcImport.newSQLiteReadHandle(path, query);
        let iter    = FactIO/JdbcImport.getIterator(hdl);
        let* relns  = FactIO/JdbcImport.importRows(sqliteDirection1(), iter);
        let* _      = FactIO/JdbcImport.close(hdl);
        let arr     = query relns select (x) from Direction(x);        
        Ok(arr)
    };
    step() |> printResult

        
def sqliteDirection1(): JdbcRowEvaluator[#{Direction | r}] = 
    use FactIO/JdbcRowEvaluator.{map, getStringNamed};
    map(makeDirection, getStringNamed("cardinal_name"))




pub def flatFile01(): Unit & Impure =
    use Result.flatMap;    
    let step = () -> {
        let path    = System/FilePath.new("e:/coding/flix/factio/data/compass.txt");
        let* hdl    = FactIO/FlatFileImport.newFlatFileReadHandle(path, Text/Charset.utf_8());
        let iter    = FactIO/FlatFileImport.getIterator(hdl);
        let* relns  = FactIO/FlatFileImport.importRows(flatfileDirection1(), iter);
        let* _      = FactIO/FlatFileImport.close(hdl);
        let arr = query relns select (x) from Direction(x);
        Ok(arr)
    };
    step() |> printResult
    

def flatfileDirection1(): FlatFileLineEvaluator[#{ Direction | r}] = 
    use FactIO/FlatFileLineEvaluator.{flatMap, content, map};
    map(makeDirection, content())
