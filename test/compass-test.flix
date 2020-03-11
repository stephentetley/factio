def logFail(msg: String): reln & Impure= 
    Console.printLine(msg);
    #{ }

rel Direction(name: String)

def makeDirection(name: String): #{ Direction } = 
    Direction(name).
    
def csvDirection1(row: CsvRow): CsvResult[#{Direction}] & e = 
    Validation.fmap(makeDirection, CsvImport.getStringByIndex(row, 0))

pub def csv01(): #{Direction} & Impure =
    let path = "d:/coding/flix/factio/data/compass.csv";
    match CsvImport.newCsvSource(path, CsvFormat.Default, true) {
        case Err(msg) => logFail(msg)
        case Ok(csvSource) => 
            match CsvImport.eachrow(csvDirection1, csvSource) {
                case Err(msg) => logFail(msg)
                case Ok(relns) => solve relns
            }
    }
    
def sqliteDirection1(row: SQLiteRow): SQLiteResult[#{Direction}] & e = 
    Validation.fmap(makeDirection, SQLiteImport.getStringByLabel(row, "cardinal_name"))
    

pub def sqlite01(): #{Direction} & Impure =
    let path = "d:/coding/flix/factio/data/compass.sqlite";
    let query = "SELECT cardinal_name FROM cardinals";
    match SQLiteImport.newSQLiteSource(path, query) {
        case Err(msg) => logFail(msg)
        case Ok(src) => {
            match SQLiteImport.eachrow(sqliteDirection1, src) {
                case Err(msg) => logFail(msg)
                case Ok(relns) => solve relns
            }
        }
    }

def lineDirection1(line: TextLine): LineResult[#{Direction}] & Pure = 
    Validation.fmap(makeDirection, LinesImport.nonempty(line))



pub def lines01(): #{ Direction } & Impure =
    let path = "d:/coding/flix/factio/data/compass.txt";
    match LinesImport.newLinesSource(path, Charset.utf_8()) {
        case Err(msg) => logFail(msg)
        case Ok(src) => 
            match LinesImport.eachrow(lineDirection1, src) {
                case Err(msg) => logFail(msg)
                case Ok(relns) => solve relns
            }
    }

