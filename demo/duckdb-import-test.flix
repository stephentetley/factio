use FactIO.JdbcRowEvaluator;


def main(_args: Array[String]): Int32 & Impure = 
    test01();
    0

def runResult(r1: Result[#{| reln}, String]): Unit & Impure = match r1 {
    case Ok(reln) => reln |> unsafeToString |> println
    case Err(msg) => Console.printLine(msg)
}

def test01(): Unit & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = System/FilePath.new("e:/coding/flix/factio/data/langs.duckdb");
        let query = "SELECT name, year FROM langs";
        let src = FactIO/JdbcImport.newDuckDBCursor(path, query);
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



