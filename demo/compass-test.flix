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


def runResult(r: Result[#{| reln}, String]): Unit & Impure = match r {
    case Ok(reln) => reln |> unsafeToString |> println
    case Err(msg) => Console.printLine("Error: ${msg}")
}

rel Direction(name: String)

def makeDirection(name: String): #{ Direction } = 
    Direction(name).


def csv01(): Unit & Impure =
    use Result.flatMap;
    use FactIO/CsvFormat.{withFirstRecordAsHeader};
    let step = () -> {
        let path = System/FilePath.new("e:/coding/flix/factio/data/compass.csv");
        let src = FactIO/CsvImport.newCsvCursor(path, FactIO/CsvFormat.default().withFirstRecordAsHeader(), Text/Charset.utf_8());
        let* relns = FactIO/CsvImport.importRows(csvDirection1(), src);
        Ok(solve relns)
    };
    step() |> runResult
    
def csvDirection1(): CsvRowEvaluator[#{Direction}] = 
    use FactIO/CsvRowEvaluator.{map, getStringAt};
    map(makeDirection, getStringAt(0))

    
pub def sqlite01(): Unit & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = System/FilePath.new("e:/coding/flix/factio/data/compass.sqlite");
        let query = "SELECT cardinal_name FROM cardinals";
        let src = FactIO/JdbcImport.newSQLiteCursor(path, query);
        let* relns = FactIO/JdbcImport.importRows(sqliteDirection1(), src);
        Ok(solve relns)
    };
    step() |> runResult

        
def sqliteDirection1(): JdbcRowEvaluator[#{Direction}] = 
    use FactIO/JdbcRowEvaluator.{map, getStringNamed};
    map(makeDirection, getStringNamed("cardinal_name"))




pub def flatFile01(): Unit & Impure =
    use Result.flatMap;    
    let step = () -> {
        let path = System/FilePath.new("e:/coding/flix/factio/data/compass.txt");
        let src = FactIO/FlatFileImport.newFlatFileCursor(path, Text/Charset.utf_8());
        let* relns = FactIO/FlatFileImport.importRows(flatfileDirection1(), src);
        Ok(solve relns)
    };
    step() |> runResult
    

def flatfileDirection1(): FlatFileLineEvaluator[#{ Direction }] = 
    use FactIO/FlatFileLineEvaluator.{flatMap, content, map};
    map(makeDirection, content())
