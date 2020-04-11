def fail1(msg: String): reln & Impure = 
    Console.printLine(msg);
    #{ }

rel Lang(name: String, year: Int32)

def getLang (row: FactIO.SQLiteRow): FactIO.SQLiteResult[#{Lang}] & e = 
    Validation.lift2(
        (x,y) -> { Lang(x, y). } ,
        FactIO/SQLiteImport.getStringByLabel(row, "name"), 
        FactIO/SQLiteImport.getInt32ByLabel(row, "year")
    )


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
