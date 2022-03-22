use FactIO.JdbcExport;
use FactIO.JdbcWriteList;
use FactIO.JdbcRowSetter;


def main(_args: Array[String]): Int32 & Impure =
    use Result.flatMap;
    use FactIO/JdbcExport.{exportSQLite};
    let setupStmts = 
        "CREATE TABLE IF NOT EXISTS dbms (name text PRIMARY KEY NOT NULL, year int);" :: "DELETE FROM dbms;" :: Nil;
    let pstmt = "INSERT INTO dbms(name, year) VALUES(?,?)";
    let step = () -> {
        let path = System/FilePath.new("e://coding/flix/factio/data/output/db1.sqlite");    
        let* _ = System/File.deleteIfExists(path) |> Result.mapErr(e -> "${e}");
        let db = databaseSystems();
        let arr = query db select (n, v) from Dbms(n, v);
        let* _ = exportSQLite(setupStmts, pstmt, writeCells, arr, path);
        Ok(true)
    };
    match step() {
        case Ok(_) => {Console.printLine("Ok"); 0}
        case Err(msg) => {Console.printLine(msg); 1}
    }


rel Dbms(name: String, year: Int32)

def databaseSystems(): #{Dbms | r} = #{
    Dbms("PostgreSQL", 1996).
    Dbms("SQLite", 2000).
    Dbms("MonetDB", 2002).
    Dbms("DuckDB", 2019).
}



/// A "cell printer" for the body of Dbms.
def writeCells(src: (String, Int32)): JdbcRowSetter[Unit] = 
    use FactIO/JdbcRowSetter.{flatMap, point, putString!, putInt32!};
    let (name,year) = src;
    let* _ = putString!(0, name);
    let* _ = putInt32!(1, year);
    point()


