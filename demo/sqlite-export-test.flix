use FactIO.JdbcExport;
use FactIO.JdbcWriteList;
use FactIO.JdbcRowSetter;


def main(_args: Array[String]): Int32 & Impure =
    use Result.flatMap;
    use FactIO/JdbcExport.{runSQLiteExport};
    let step = () -> {
        let path = System/FilePath.new("e://coding/flix/factio/data/output/db1.sqlite");    
        let* _ = System/File.deleteIfExists(path) |> Result.mapErr(e -> "${e}");
        let* _ = runSQLiteExport(writeOutput(), path);
        Ok(true)
    };
    match step() {
        case Ok(_) => {Console.printLine("Ok"); 0}
        case Err(msg) => {Console.printLine(msg); 1}
    }


rel Dbms(name: String, year: Int32)

def databases(): #{Dbms} = #{
    Dbms("PostgreSQL", 1996).
    Dbms("SQLite", 2000).
    Dbms("MonetDB", 2002).
    Dbms("DuckDB", 2019).
}


def writeOutput(): JdbcExport[Unit] =
    use FactIO/JdbcExport.{flatMap, return, execute, liftAction, emptyJdbcWriteList, execWriteList, setAutoCommitOff, commit, close};
    let* _          = execute("CREATE TABLE IF NOT EXISTS dbms (name text PRIMARY KEY NOT NULL, year int);");
    let* _          = execute("DELETE FROM dbms;");
    let stmt        = "INSERT INTO dbms(name, year) VALUES(?,?)";
    let* _          = setAutoCommitOff();
    let writes      = fold Dbms emptyJdbcWriteList() writeStep() (solve databases());
    let* n          = execWriteList(stmt, writes);
    let* _          = commit();
    let* _          = close();
    let* _          = liftAction(_ -> { Console.printLine("Row count: " + Int32.toString(n)); Ok()});
    return()

/// Weird - making this a top level definition (with a type signature) seems 
/// to stop the program crashing.
def writeStep(): ((String, Int32), JdbcWriteList) -> JdbcWriteList = 
    FactIO/JdbcExport.makeJdbcWriteStep(writeCells)


/// A "cell printer" for the body of Dbms.
def writeCells(src: (String, Int32)): JdbcRowSetter[Unit] = 
    use FactIO/JdbcRowSetter.{flatMap, return, putString!, putInt32!};
    let (name,year) = src;
    let* _ = putString!(0, name);
    let* _ = putInt32!(1, year);
    return()


