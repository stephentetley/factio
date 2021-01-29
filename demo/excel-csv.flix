use FactIO.CsvRowEvaluator;
use FactIO/CsvFormat.{withFirstRecordAsHeader};

def runResult(r: Result[#{| reln}, String]): #{| reln} & Impure = match r {
    case Ok(reln) => reln
    case Err(msg) => { Console.printLine(msg); #{ }}
}

    

rel Lang(name: String)

def getNewDatalog(): CsvRowEvaluator[#{Lang}] =
    use FactIO/CsvRowEvaluator.{map, getStringNamed}; 
    map(s -> { Lang(s). }, getStringNamed("Lang"))

/// Should fail
pub def test01(): #{Lang} & Impure =
    use Result.flatMap;
    let path = System/FilePath.new("e:/coding/flix/factio/data/new-datalogs-utf8-bom.csv");
    let step =  () -> {
        let* src = FactIO/CsvImport.newCsvStream(path, FactIO/CsvFormat.excel().withFirstRecordAsHeader(), Text/Charset.utf_8());
        let* relns = FactIO/CsvImport.importRows(getNewDatalog(), src);
        Ok(solve relns)
    };
    Console.printLine("Should fail...");
    step() |> runResult

pub def test02(): #{Lang} & Impure =
    use Result.flatMap;
    let path = System/FilePath.new("e:/coding/flix/factio/data/new-datalogs-utf8-bom.csv");
    let step =  () -> {
        let* src = FactIO/CsvImport.newCsvStreamWithBOM(path, FactIO/CsvFormat.excel().withFirstRecordAsHeader(), Text/Charset.utf_8());
        let* relns = FactIO/CsvImport.importRows(getNewDatalog(), src);
        Ok(solve relns)
    };
    Console.printLine("Should run...");
    step() |> runResult


def getFunctionalLang(): CsvRowEvaluator[#{Lang}] = 
    use FactIO/CsvRowEvaluator.{map, getStringNamed}; 
    map(s -> { Lang(s). }, getStringNamed("Lang Name"))

pub def test03(): #{Lang} & Impure =
    use Result.flatMap;
    let path = System/FilePath.new("e:/coding/flix/factio/data/functional-langs-utf8-bom.csv");
    let step =  () -> {
        let* src = FactIO/CsvImport.newCsvStream(path, FactIO/CsvFormat.excel().withFirstRecordAsHeader(), Text/Charset.utf_8());
        let* relns = FactIO/CsvImport.importRows(getFunctionalLang(), src);
        Ok(solve relns)
    };
    Console.printLine("Should fail...");
    step() |> runResult

pub def test04(): #{Lang} & Impure =
    use Result.flatMap;
    let path = System/FilePath.new("e:/coding/flix/factio/data/functional-langs-utf8-bom.csv");
    let step = () -> {
        let* src = FactIO/CsvImport.newCsvStreamWithBOM(path, FactIO/CsvFormat.excel().withFirstRecordAsHeader(), Text/Charset.utf_8());
        let* relns = FactIO/CsvImport.importRows(getFunctionalLang(), src);
        Ok(solve relns)
    };
    Console.printLine("Should run...");
    step() |> runResult
    
def main(_args: Array[String]): Int32 & Impure = 
    let ans = test04();
    Console.printLine(unsafeToString(ans));
    0
