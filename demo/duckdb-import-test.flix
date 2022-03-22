use FactIO.JdbcRowEvaluator;


def main(_args: Array[String]): Int32 & Impure = 
    test01();
    0

def printResult(rarr: Result[Array[a], String]): Unit & Impure with ToString[a] = match rarr {
    case Ok(arr) => {Console.printLine("Success:"); Array.foreach(x -> Console.printLine("${x}"), arr) }
    case Err(msg) => Console.printLine("Error: ${msg}")
}

def test01(): Unit & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = System/FilePath.new("e:/coding/flix/factio/data/langs.duckdb");
        let query = "SELECT name, year FROM langs";
        let src = FactIO/JdbcImport.newDuckDBCursor(path, query);
        let* relns = FactIO/JdbcImport.importRows!(getLang(), src);
        let arr = query relns select (x, y) from Lang(x, y);
        Ok(arr)
    };
    step() |> printResult


rel Lang(name: String, year: Int32)

def getLang (): JdbcRowEvaluator[#{Lang| r}] = 
    use FactIO/JdbcRowEvaluator.{flatMap, getStringNamed, getInt32Named, point};
    let* x = getStringNamed("name");
    let* y = getInt32Named("year");
    point({ Lang(x, y). })



