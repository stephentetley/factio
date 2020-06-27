use FactIO/SQLite.SQLiteRowEvaluator;

def runResult(r1: Result[reln, System.Error]): reln & Impure = match r1 {
    case Ok(reln) => reln
    case Err(e) => {
        Console.printLine(System/Error.toString(e));
        #{ }
    }
}

rel Lang(name: String, year: Int32)

def getLang (): SQLiteRowEvaluator[#{Lang}] = 
    use FactIO/SQLite/RowEvaluator.{flatMap, getStringByLabel, getInt32ByLabel, return};
    let* x = getStringByLabel("name");
    let* y = getInt32ByLabel("year");
    return({ Lang(x, y). })


pub def test01(): #{Lang} & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = "e:/coding/flix/factio/data/langs.sqlite";
        let query = "SELECT name, year FROM language";
        let* src = FactIO/SQLite/Import.newSQLiteStream(path, query);
        let* relns = FactIO/SQLite/Import.importRows(getLang(), src);
        Ok(solve relns)
    };
    step() |> runResult

def main(): #{Lang} & Impure = test01()
