use FactIO.JdbcRowEvaluator;

def runResult(r1: Result[#{| reln}, System.Error]): #{| reln} & Impure = match r1 {
    case Ok(reln) => reln
    case Err(e) => {
        Console.printLine(System/Error.toString(e));
        #{ }
    }
}

rel Lang(name: String, year: Int32)

def getLang (): JdbcRowEvaluator[#{Lang}] = 
    use FactIO/JdbcRowEvaluator.{flatMap, getStringByLabel, getInt32ByLabel, return};
    let* x = getStringByLabel("name");
    let* y = getInt32ByLabel("year");
    return({ Lang(x, y). })


pub def test01(): #{Lang} & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = System/FilePath.new("e:/coding/flix/factio/data/langs.sqlite");
        let query = "SELECT name, year FROM language";
        let* src = FactIO/JdbcImport.newJdbcStream(path, query);
        let* relns = FactIO/JdbcImport.importRows(getLang(), src);
        Ok(solve relns)
    };
    step() |> runResult

def main(): #{Lang} & Impure = test01()
