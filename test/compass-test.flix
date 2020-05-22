use FactIO/CsvImport.{CsvRow, CsvResult};
use FactIO/SQLiteImport.{SQLiteRow, SQLiteResult};
use FactIO.LineEvaluator;

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
    
def csvDirection1(row: CsvRow): CsvResult[#{Direction}] & e = 
    Result.map(makeDirection, FactIO/CsvImport.getStringByIndex(row, 0))

pub def csv01(): #{Direction} & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = "e:/coding/flix/factio/data/compass.csv";
        let* src = FactIO/CsvImport.newCsvStream(path, FactIO/CsvFormat.Default, true);
        let* relns = FactIO/CsvImport.importRows(csvDirection1, src);
        Ok(solve relns)
    };
    step() |> runResult
    
def sqliteDirection1(row: SQLiteRow): SQLiteResult[#{Direction}] & e = 
    Result.map(makeDirection, FactIO/SQLiteImport.getStringByLabel(row, "cardinal_name"))
    

pub def sqlite01(): #{Direction} & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = "e:/coding/flix/factio/data/compass.sqlite";
        let query = "SELECT cardinal_name FROM cardinals";
        let* src = FactIO/SQLiteImport.newSQLiteStream(path, query);
        let* relns = FactIO/SQLiteImport.importRows(sqliteDirection1, src);
        Ok(solve relns)
    };
    step() |> runResult

def lineDirection1(): LineEvaluator[#{ Direction }] = 
    use FactIO/LineEvaluator.{flatMap, content, map};
    map(makeDirection, content())



pub def lines01(): #{ Direction } & Impure =
    use Result.flatMap;
    use FactIO/LinesImporter.{lines};
    let step = () -> {
        let path = "e:/coding/flix/factio/data/compass.txt";
        let* relns = FactIO/LinesImporter.runLinesImporter(lines(lineDirection1()), path, Text/Charset.utf_8());
        Ok(solve relns)
    };
    step() |> runResult
    

