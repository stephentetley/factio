use FactIO.CsvRowEvaluator;


def main(_args: Array[String]): Int32 & Impure = 
    test01();
    test02();
    0


def runResult(r1: Result[#{| reln}, String]): Unit & Impure = match r1 {
    case Ok(reln) => reln |> unsafeToString |> println
    case Err(msg) => Console.printLine("Error: ${msg}")
}

pub def test01(): Unit & Impure =
    use Result.flatMap;
    use FactIO/CsvFormat.{withFirstRecordAsHeader};
    let step = () -> {
        let path = System/FilePath.new("e:/coding/flix/factio/data/stations.csv");
        let src = FactIO/CsvImport.newCsvCursor(path, FactIO/CsvFormat.default().withFirstRecordAsHeader(), Text/Charset.utf_8());
        let* ans = FactIO/CsvImport.importRows(getName(), src);
        Ok(solve ans)        
    };
    step() |> runResult

rel Name(name: String)

def makeName(name: String): #{ Name } = 
    Name(name).

def getName(): CsvRowEvaluator[#{Name}] = 
    use FactIO/CsvRowEvaluator.{map, getStringNamed};
    map(makeName, getStringNamed("Name")) 

    

pub def test02(): Unit & Impure =
    use Result.flatMap;
    use FactIO/CsvFormat.{withFirstRecordAsHeader};
    let step = () -> {
        let path = System/FilePath.new("e:/coding/flix/factio/data/stations.csv");
        let src = FactIO/CsvImport.newCsvCursor(path, FactIO/CsvFormat.default().withFirstRecordAsHeader(), Text/Charset.utf_8());
        let* relns = FactIO/CsvImport.importRows(getStation(), src);
        Ok(solve relns)
    };
    step() |> runResult


rel Station(name: String, gridref: String)


def getStation(): CsvRowEvaluator[#{Station}] = 
    use FactIO/CsvRowEvaluator.{flatMap, getStringNamed, return};
    let* x = getStringNamed("Name");
    let* y = getStringNamed("Grid_Ref");
    return({ Station(x, y). })

