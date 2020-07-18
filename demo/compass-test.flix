use FactIO/CsvImport.{CsvRow, CsvResult};
use FactIO.CsvRowEvaluator;
use FactIO/SQLiteImport.{SQLiteRow, SQLiteResult};
use FactIO.SQLiteRowEvaluator;
use FactIO/FlatFile.SimpleParser;
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
    use FactIO/CsvRowEvaluator.{map, getStringByIndex};
    map(makeDirection, getStringByIndex(0))

pub def csv01(): #{Direction} & Impure =
    use Result.flatMap;
    use FactIO/CsvFormat.{withFirstRecordAsHeader};
    let step = () -> {
        let path = "e:/coding/flix/factio/data/compass.csv";
        let* src = FactIO/CsvImport.newCsvStream(path, FactIO/CsvFormat.default().withFirstRecordAsHeader(), Text/Charset.utf_8());
        let* relns = FactIO/CsvImport.importRows(csvDirection1(), src);
        Ok(solve relns)
    };
    step() |> runResult
    
def sqliteDirection1(): SQLiteRowEvaluator[#{Direction}] = 
    use FactIO/SQLiteRowEvaluator.{map, getStringByLabel};
    map(makeDirection, getStringByLabel("cardinal_name"))
    

pub def sqlite01(): #{Direction} & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = "e:/coding/flix/factio/data/compass.sqlite";
        let query = "SELECT cardinal_name FROM cardinals";
        let* src = FactIO/SQLiteImport.newSQLiteStream(path, query);
        let* relns = FactIO/SQLiteImport.importRows(sqliteDirection1(), src);
        Ok(solve relns)
    };
    step() |> runResult

def lineDirection1(): LineEvaluator[#{ Direction }] = 
    use FactIO/FlatFile/LineEvaluator.{flatMap, content, map};
    map(makeDirection, content())

def linesImporter(): SimpleParser[#{ Direction }] = 
    use FactIO/FlatFile/SimpleParser.{linesTillEnd};
    linesTillEnd(lineDirection1())

pub def lines01(): #{ Direction } & Impure =
    use Result.flatMap;    
    let step = () -> {
        let path = "e:/coding/flix/factio/data/compass.txt";
        let* relns = FactIO/FlatFile/SimpleParser.runSimpleParser(linesImporter(), path, Text/Charset.utf_8());
        Ok(solve relns)
    };
    step() |> runResult
    

def main(): #{ Direction } & Impure =
    lines01()
