use FactIO/SQLiteImport.{SQLiteRow, SQLiteResult};

def fail1(msg: String): reln & Impure = 
    Console.printLine(msg);
    #{ }

rel Lang(name: String, year: Int32)

def getLang (row: SQLiteRow): SQLiteResult[#{Lang}] & Impure = 
    use Result.flatMap;
    let* x = FactIO/SQLiteImport.getStringByLabel(row, "name");
    let* y = FactIO/SQLiteImport.getInt32ByLabel(row, "year");
    Ok({ Lang(x, y). })


pub def test01(): #{Lang} & Impure =
    let path = "e:/coding/flix/factio/data/langs.sqlite";
    let query = "SELECT name, year FROM language";
    match FactIO/SQLiteImport.newSQLiteSource(path, query) {
        case Err(msg) => fail1(msg)
        case Ok(src) => {
            match FactIO/SQLiteImport.iterate(getLang, src) {
                case Err(msg) => fail1(msg)
                case Ok(relns) => solve relns
            }
        }
    }
