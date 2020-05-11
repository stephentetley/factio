use FactIO/CsvImport.{CsvRow, CsvResult};
use FactIO/LinesImport.{TextLine, LineResult};
use FactIO/SQLiteImport.{SQLiteRow, SQLiteResult};

def runResult(r1: Result[reln, FactIO.Error]): reln & Impure = match r1 {
    case Ok(reln) => reln
    case Err(e) => {
        Console.printLine(FactIO/Error.toString(e));
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

def lineDirection1(line: TextLine): LineResult[#{Direction}] & Impure = 
    Result.map(makeDirection, FactIO/LinesImport.nonempty(line)) as & Impure



pub def lines01(): #{ Direction } & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = "e:/coding/flix/factio/data/compass.txt";
        let* src = FactIO/LinesImport.newLinesStream(path, Text/Charset.utf_8());
        let* relns =  FactIO/LinesImport.importRows(lineDirection1, src);
        Ok(solve relns)
    };
    step() |> runResult
    

