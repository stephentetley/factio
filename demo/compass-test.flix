use FactIO/Csv/Import.{CsvRow, CsvResult};
use FactIO/Csv.CsvRowEvaluator;
use FactIO/SQLite/Import.{SQLiteRow, SQLiteResult};
use FactIO/SQLite.SQLiteRowEvaluator;
use FactIO/FlatFile.Parser;
use FactIO/FlatFile.LineEvaluator;

def runResult(r1: Result[reln, System.Error]): reln & Impure = match r1 {
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
    use FactIO/Csv/RowEvaluator.{map, getStringByIndex};
    map(makeDirection, getStringByIndex(0))

pub def csv01(): #{Direction} & Impure =
    use Result.flatMap;
    use FactIO/Csv/CsvFormat.{withFirstRecordAsHeader};
    let step = () -> {
        let path = "e:/coding/flix/factio/data/compass.csv";
        let* src = FactIO/Csv/Import.newCsvStream(path, FactIO/Csv/CsvFormat.default().withFirstRecordAsHeader(), Text/Charset.utf_8());
        let* relns = FactIO/Csv/Import.importRows(csvDirection1(), src);
        Ok(solve relns)
    };
    step() |> runResult
    
def sqliteDirection1(): SQLiteRowEvaluator[#{Direction}] = 
    use FactIO/SQLite/RowEvaluator.{map, getStringByLabel};
    map(makeDirection, getStringByLabel("cardinal_name"))
    

pub def sqlite01(): #{Direction} & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = "e:/coding/flix/factio/data/compass.sqlite";
        let query = "SELECT cardinal_name FROM cardinals";
        let* src = FactIO/SQLite/Import.newSQLiteStream(path, query);
        let* relns = FactIO/SQLite/Import.importRows(sqliteDirection1(), src);
        Ok(solve relns)
    };
    step() |> runResult

def lineDirection1(): LineEvaluator[#{ Direction }] = 
    use FactIO/FlatFile/LineEvaluator.{flatMap, content, map};
    map(makeDirection, content())

def linesImporter(): Parser[#{ Direction }, Unit] = 
    use FactIO/FlatFile/Parser.{lines};
    lines(lineDirection1())

pub def lines01(): #{ Direction } & Impure =
    use Result.flatMap;    
    let step = () -> {
        let path = "e:/coding/flix/factio/data/compass.txt";
        let* relns = FactIO/FlatFile/Parser.runParser(linesImporter(), (), path, Text/Charset.utf_8());
        Ok(solve relns)
    };
    step() |> runResult
    

def main(): #{ Direction } & Impure =
    lines01()