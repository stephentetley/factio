use FactIO.JdbcRowEvaluator;

def runResult(r1: Result[#{| reln}, String]): #{| reln} & Impure = match r1 {
    case Ok(reln) => reln
    case Err(msg) => {Console.printLine(msg); #{ }}
}

rel Lang(name: String, year: Int32)

def getLang (): JdbcRowEvaluator[#{Lang}] = 
    use FactIO/JdbcRowEvaluator.{flatMap, getStringNamed, getInt32Named, return};
    let* x = getStringNamed("name");
    let* y = getInt32Named("year");
    return({ Lang(x, y). })


pub def test01(): #{Lang} & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = System/FilePath.new("e:/coding/flix/factio/data/langs.sqlite");
        let query = "SELECT name, year FROM language";
        let* src = FactIO/JdbcImport.newSQLiteStream(path, query);
        let* relns = FactIO/JdbcImport.importRows(getLang(), src);
        Ok(solve relns)
    };
    step() |> runResult

def main(_args: Array[String]): Int32 & Impure = 
    let ans = test01();
    Console.printLine(unsafeToString(ans));
    0
