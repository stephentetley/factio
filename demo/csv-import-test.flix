use FactIO.CsvRowEvaluator;


def main(_args: Array[String]): Int32 & Impure = 
    test01();
    test02();
    0


def printResult(rarr: Result[Array[a], String]): Unit & Impure with ToString[a] = match rarr {
    case Ok(arr) => {Console.printLine("Success:"); Array.foreach(x -> Console.printLine("${x}"), arr) }
    case Err(msg) => Console.printLine("Error: ${msg}")
}

pub def test01(): Unit & Impure =
    use Result.flatMap;
    use FactIO/CsvFormat.{withFirstRecordAsHeader};
    let step = () -> {
        let path = System/FilePath.new("e:/coding/flix/factio/data/stations.csv");
        let src = FactIO/CsvImport.newCsvCursor(path, FactIO/CsvFormat.default().withFirstRecordAsHeader(), Text/Charset.utf_8());
        let* relns = FactIO/CsvImport.importRows!(getName(), src);
        let arr = query relns select (x) from Name(x);
        Ok(arr)
    };
    step() |> printResult

rel Name(name: String)

def makeName(name: String): #{Name  | r} = 
    Name(name).

def getName(): CsvRowEvaluator[#{Name | r}] = 
    use FactIO/CsvRowEvaluator.{map, getStringNamed};
    map(makeName, getStringNamed("Name")) 

    

pub def test02(): Unit & Impure =
    use Result.flatMap;
    use FactIO/CsvFormat.{withFirstRecordAsHeader};
    let step = () -> {
        let path = System/FilePath.new("e:/coding/flix/factio/data/stations.csv");
        let src = FactIO/CsvImport.newCsvCursor(path, FactIO/CsvFormat.default().withFirstRecordAsHeader(), Text/Charset.utf_8());
        let* relns = FactIO/CsvImport.importRows!(getStation(), src);
        Ok(query relns select (x,y) from Station(x, y))
    };
    step() |> printResult


rel Station(name: String, gridref: String)


def getStation(): CsvRowEvaluator[#{Station | r}] = 
    use FactIO/CsvRowEvaluator.{flatMap, getStringNamed, point};
    let* x = getStringNamed("Name");
    let* y = getStringNamed("Grid_Ref");
    point({ Station(x, y). })

