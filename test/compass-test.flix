def logFail(msg: String): reln & Impure= 
    Console.printLine(msg);
    #{ }

rel Direction(name: String)

def makeDirection(name: String): #{ Direction } = 
    Direction(name).
    
def csvDirection1(row: FactIO.CsvRow): FactIO.CsvResult[#{Direction}] & e = 
    Validation.map(makeDirection, FactIO/CsvImport.getStringByIndex(row, 0))

pub def csv01(): #{Direction} & Impure =
    let path = "e:/coding/flix/factio/data/compass.csv";
    match FactIO/CsvImport.newCsvSource(path, FactIO/CsvImport/CsvFormat.Default, true) {
        case Err(msg) => logFail(msg)
        case Ok(csvSource) => 
            match FactIO/CsvImport.iterate(csvDirection1, csvSource) {
                case Err(msg) => logFail(msg)
                case Ok(relns) => solve relns
            }
    }
    
def sqliteDirection1(row: FactIO.SQLiteRow): FactIO.SQLiteResult[#{Direction}] & e = 
    Validation.map(makeDirection, FactIO/SQLiteImport.getStringByLabel(row, "cardinal_name"))
    

pub def sqlite01(): #{Direction} & Impure =
    let path = "e:/coding/flix/factio/data/compass.sqlite";
    let query = "SELECT cardinal_name FROM cardinals";
    match FactIO/SQLiteImport.newSQLiteSource(path, query) {
        case Err(msg) => logFail(msg)
        case Ok(src) => {
            match FactIO/SQLiteImport.iterate(sqliteDirection1, src) {
                case Err(msg) => logFail(msg)
                case Ok(relns) => solve relns
            }
        }
    }

def lineDirection1(line: FactIO.TextLine): FactIO.LineResult[#{Direction}] & Pure = 
    Validation.map(makeDirection, FactIO/LinesImport.nonempty(line))



pub def lines01(): #{ Direction } & Impure =
    let path = "e:/coding/flix/factio/data/compass.txt";
    match FactIO/LinesImport.newLinesSource(path, System/Charset.utf_8()) {
        case Err(msg) => logFail(msg)
        case Ok(src) => 
            match FactIO/LinesImport.iterate(lineDirection1, src) {
                case Err(msg) => logFail(msg)
                case Ok(relns) => solve relns
            }
    }

