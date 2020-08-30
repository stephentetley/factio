use FactIO.JdbcExport;
use FactIO.JdbcWriteList;
use FactIO.JdbcRowWriter;


rel Dbms(name: String, year: Int32)

def databases(): #{Dbms} = #{
    Dbms("PostgreSQL", 1996).
    Dbms("SQLite", 2000).
    Dbms("MonetDB", 2002).
    Dbms("DuckDB", 2019).
}


def writeOutput(): JdbcExport[Unit] =
    use FactIO/JdbcExport.{flatMap, return, execute, liftAction, emptyJdbcWriteList, execWriteList, setAutoCommit, commit, close};
    let* _          = execute("CREATE TABLE IF NOT EXISTS dbms (name text PRIMARY KEY NOT NULL, year int);");
    let* _          = execute("DELETE FROM dbms;");
    let stmt        = "INSERT INTO dbms(name, year) VALUES(?,?)";
    let* _          = setAutoCommit(false);
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
def writeCells(src: (String, Int32)): JdbcRowWriter[Unit] = 
    use FactIO/JdbcRowWriter.{flatMap, return, putString!, putInt32!};
    let (name,year) = src;
    let* _ = putString!(0, name);
    let* _ = putInt32!(1, year);
    return()


def main(): Result[Bool, System.Error] & Impure =
    use Result.flatMap;
    use FactIO/JdbcExport.{runJdbcExport};
    let str = "e:/coding/flix/factio/data/output/db1.sqlite";
    let path = System/FilePath.new(str);    
    let* _ = System/File.deleteIfExists(path);
    let* _ = runJdbcExport(writeOutput(), path);
    Ok(true)

// def main(): Int32 = fold Dbms 0 mkWriteStep() (solve databases())