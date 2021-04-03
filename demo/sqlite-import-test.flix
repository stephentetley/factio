use FactIO.JdbcRowEvaluator;


def main(_args: Array[String]): Int32 & Impure = 
    test01();
    0

def runResult(r: Result[#{| reln}, String]): Unit & Impure = match r {
    case Ok(reln) => reln |> unsafeToString |> println
    case Err(msg) => Console.printLine("Error: ${msg}")
}

def test01(): Unit & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = System/FilePath.new("e:/coding/flix/factio/data/langs.sqlite");
        let query = "SELECT name, year FROM language";
        let src = FactIO/JdbcImport.newSQLiteCursor(path, query);
        let* relns = FactIO/JdbcImport.importRows(getLang(), src);
        Ok(solve relns)
    };
    step() |> runResult

rel Lang(name: String, year: Int32)

def getLang (): JdbcRowEvaluator[#{Lang}] = 
    use FactIO/JdbcRowEvaluator.{flatMap, getStringNamed, getInt32Named, return};
    let* x = getStringNamed("name");
    let* y = getInt32Named("year");
    return({ Lang(x, y). })

