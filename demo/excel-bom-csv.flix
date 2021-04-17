use FactIO.CsvRowEvaluator;
use FactIO/CsvFormat.{withFirstRecordAsHeader};

    
def main(_args: Array[String]): Int32 & Impure = 
    test01();
    test02();
    test03();
    test04();
    0


def printResult(rarr: Result[Array[a], String]): Unit & Impure with ToString[a] = match rarr {
    case Ok(arr) => {Console.printLine("Success:"); Array.foreach(x -> Console.printLine("${x}"), arr) }
    case Err(msg) => Console.printLine("Error: ${msg}")
}

    

rel Lang(name: String)

def getNewDatalog(): CsvRowEvaluator[#{Lang | r}] =
    use FactIO/CsvRowEvaluator.{map, getStringNamed}; 
    map(s -> { Lang(s). }, getStringNamed("Lang"))

/// Should fail
pub def test01(): Unit & Impure =
    use Result.flatMap;
    let path = System/FilePath.new("e:/coding/flix/factio/data/new-datalogs-utf8-bom.csv");
    let step =  () -> {
        let src = FactIO/CsvImport.newCsvCursor(path, FactIO/CsvFormat.excel().withFirstRecordAsHeader(), Text/Charset.utf_8());
        let* relns = FactIO/CsvImport.importRows!(getNewDatalog(), src);
        let arr = query relns select (x) from Lang(x);
        Ok(arr)
    };
    Console.printLine("Should fail...");
    step() |> printResult

pub def test02(): Unit & Impure =
    use Result.flatMap;
    let path = System/FilePath.new("e:/coding/flix/factio/data/new-datalogs-utf8-bom.csv");
    let step =  () -> {
        let src = FactIO/CsvImport.newCsvCursorWithBOM(path, FactIO/CsvFormat.excel().withFirstRecordAsHeader());
        let* relns = FactIO/CsvImport.importRows!(getNewDatalog(), src);
        let arr = query relns select (x) from Lang(x);
        Ok(arr)
    };
    Console.printLine("Should succeed...");
    step() |> printResult


def getFunctionalLang(): CsvRowEvaluator[#{Lang | r}] = 
    use FactIO/CsvRowEvaluator.{map, getStringNamed}; 
    map(s -> { Lang(s). }, getStringNamed("Lang Name"))

pub def test03(): Unit & Impure =
    use Result.flatMap;
    let path = System/FilePath.new("e:/coding/flix/factio/data/functional-langs-utf8-bom.csv");
    let step =  () -> {
        let src = FactIO/CsvImport.newCsvCursor(path, FactIO/CsvFormat.excel().withFirstRecordAsHeader(), Text/Charset.utf_8());
        let* relns = FactIO/CsvImport.importRows!(getFunctionalLang(), src);
        let arr = query relns select (x) from Lang(x);
        Ok(arr)
    };
    Console.printLine("Should fail...");
    step() |> printResult

pub def test04(): Unit & Impure =
    use Result.flatMap;
    let path = System/FilePath.new("e:/coding/flix/factio/data/functional-langs-utf8-bom.csv");
    let step = () -> {
        let src = FactIO/CsvImport.newCsvCursorWithBOM(path, FactIO/CsvFormat.excel().withFirstRecordAsHeader());
        let* relns = FactIO/CsvImport.importRows!(getFunctionalLang(), src);
        let arr = query relns select (x) from Lang(x);
        Ok(arr)
    };
    Console.printLine("Should succeed...");
    step() |> printResult

