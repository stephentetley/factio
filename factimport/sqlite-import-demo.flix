def fail1(msg: String): reln = 
    Console.printLine(msg);
    #{ }

rel Lang(name: String, year: Int32)

def getLang (row: SQLiteRow): SQLiteResult[#{Lang}] = 
    Validation.pipeV2(
        SQLiteImport.getStringByLabel(row, "name"), 
        SQLiteImport.getInt32ByLabel(row, "year"), 
        (x,y) -> Lang(x, y).)


pub def test01(): #{Lang} =
    let path = "e:/coding/flix/flix-doodle/factimport/data/langs.sqlite";
    let query = "SELECT name, year FROM language";
    match SQLiteImport.newSQLiteSource(path, query) {
        case Err(msg) => fail1(msg)
        case Ok(src) => {
            match SQLiteImport.collect(getLang, src) {
                case Err(msg) => fail1(msg)
                case Ok(relns) => solve relns
            }
        }
    }
