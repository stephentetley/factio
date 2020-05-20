use FactIO/SQLiteImport.{SQLiteRow, SQLiteResult};

def runResult(r1: Result[reln, System.Error]): reln & Impure = match r1 {
    case Ok(reln) => reln
    case Err(e) => {
        Console.printLine(System/Error.toString(e));
        #{ }
    }
}

rel Lang(name: String, year: Int32)

def getLang (row: SQLiteRow): SQLiteResult[#{Lang}] & Impure = 
    use Result.flatMap;
    let* x = FactIO/SQLiteImport.getStringByLabel(row, "name");
    let* y = FactIO/SQLiteImport.getInt32ByLabel(row, "year");
    Ok({ Lang(x, y). })


pub def test01(): #{Lang} & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = "e:/coding/flix/factio/data/langs.sqlite";
        let query = "SELECT name, year FROM language";
        let* src = FactIO/SQLiteImport.newSQLiteStream(path, query);
        let* relns = FactIO/SQLiteImport.importRows(getLang, src);
        Ok(solve relns)
    };
    step() |> runResult

