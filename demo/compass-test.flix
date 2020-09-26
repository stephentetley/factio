use FactIO/CsvImport.{CsvRow, CsvResult};
use FactIO.CsvRowEvaluator;
use FactIO/JdbcImport.{JdbcRow, JdbcResult};
use FactIO.JdbcRowEvaluator;
use FactIO.FlatFileLineEvaluator;

def runResult(r1: Result[#{| reln}, System.Error]): #{| reln} & Impure = match r1 {
    case Ok(reln) => reln
    case Err(e) => {
        Console.printLine(System/Error.toString(e));
        #{ }
    }
}

rel Direction(name: String)

def makeDirection(name: String): #{ Direction } = 
    Direction(name).
    
def csvDirection1(): CsvRowEvaluator[#{Direction}] = 
    use FactIO/CsvRowEvaluator.{map, getStringAt};
    map(makeDirection, getStringAt(0))

pub def csv01(): #{Direction} & Impure =
    use Result.flatMap;
    use FactIO/CsvFormat.{withFirstRecordAsHeader};
    let step = () -> {
        let path = System/FilePath.new("e:/coding/flix/factio/data/compass.csv");
        let* src = FactIO/CsvImport.newCsvStream(path, FactIO/CsvFormat.default().withFirstRecordAsHeader(), Text/Charset.utf_8());
        let* relns = FactIO/CsvImport.importRows(csvDirection1(), src);
        Ok(solve relns)
    };
    step() |> runResult
    
def sqliteDirection1(): JdbcRowEvaluator[#{Direction}] = 
    use FactIO/JdbcRowEvaluator.{map, getStringNamed};
    map(makeDirection, getStringNamed("cardinal_name"))
    

pub def sqlite01(): #{Direction} & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = System/FilePath.new("e:/coding/flix/factio/data/compass.sqlite");
        let query = "SELECT cardinal_name FROM cardinals";
        let* src = FactIO/JdbcImport.newSQLiteStream(path, query);
        let* relns = FactIO/JdbcImport.importRows(sqliteDirection1(), src);
        Ok(solve relns)
    };
    step() |> runResult

def flatfileDirection1(): FlatFileLineEvaluator[#{ Direction }] = 
    use FactIO/FlatFileLineEvaluator.{flatMap, content, map};
    map(makeDirection, content())


pub def lines01(): #{ Direction } & Impure =
    use Result.flatMap;    
    let step = () -> {
        let path = System/FilePath.new("e:/coding/flix/factio/data/compass.txt");
        let* src = FactIO/FlatFileImport.newFlatFileStream(path, Text/Charset.utf_8());
        let* relns = FactIO/FlatFileImport.importRows(flatfileDirection1(), src);
        Ok(solve relns)
    };
    step() |> runResult
    

def main(): #{ Direction } & Impure =
    lines01()
