use FactIO/Csv.CsvRowEvaluator;
use FactIO/Csv/CsvFormat.{withFirstRecordAsHeader};

def runResult(r: Result[reln, System.Error]): reln & Impure = match r {
    case Ok(reln) => reln
    case Err(e) => { Console.printLine(System/Error.toString(e)); #{ }}
}

    

rel Lang(name: String)

def getNewDatalog(): CsvRowEvaluator[#{Lang}] =
    use FactIO/Csv/RowEvaluator.{map, getStringByLabel}; 
    map(s -> { Lang(s). }, getStringByLabel("Lang"))

/// Should fail
pub def test01(): #{Lang} & Impure =
    use Result.flatMap;
    let path = "e:/coding/flix/factio/data/new-datalogs-utf8-bom.csv";
    let step =  () -> {
        let* src = FactIO/Csv/Import.newCsvStream(path, FactIO/Csv/CsvFormat.excel().withFirstRecordAsHeader(), Text/Charset.utf_8());
        let* relns = FactIO/Csv/Import.importRows(getNewDatalog(), src);
        Ok(solve relns)
    };
    Console.printLine("Should fail...");
    step() |> runResult

pub def test02(): #{Lang} & Impure =
    use Result.flatMap;
    let path = "e:/coding/flix/factio/data/new-datalogs-utf8-bom.csv";
    let step =  () -> {
        let* src = FactIO/Csv/Import.newCsvStreamWithBOM(path, FactIO/Csv/CsvFormat.excel().withFirstRecordAsHeader(), Text/Charset.utf_8());
        let* relns = FactIO/Csv/Import.importRows(getNewDatalog(), src);
        Ok(solve relns)
    };
    Console.printLine("Should run...");
    step() |> runResult


def getFunctionalLang(): CsvRowEvaluator[#{Lang}] = 
    use FactIO/Csv/RowEvaluator.{map, getStringByLabel}; 
    map(s -> { Lang(s). }, getStringByLabel("Lang Name"))

pub def test03(): #{Lang} & Impure =
    use Result.flatMap;
    let path = "e:/coding/flix/factio/data/functional-langs-utf8-bom.csv";
    let step =  () -> {
        let* src = FactIO/Csv/Import.newCsvStream(path, FactIO/Csv/CsvFormat.excel().withFirstRecordAsHeader(), Text/Charset.utf_8());
        let* relns = FactIO/Csv/Import.importRows(getFunctionalLang(), src);
        Ok(solve relns)
    };
    Console.printLine("Should fail...");
    step() |> runResult

pub def test04(): #{Lang} & Impure =
    use Result.flatMap;
    let path = "e:/coding/flix/factio/data/functional-langs-utf8-bom.csv";
    let step = () -> {
        let* src = FactIO/Csv/Import.newCsvStreamWithBOM(path, FactIO/Csv/CsvFormat.excel().withFirstRecordAsHeader(), Text/Charset.utf_8());
        let* relns = FactIO/Csv/Import.importRows(getFunctionalLang(), src);
        Ok(solve relns)
    };
    Console.printLine("Should run...");
    step() |> runResult
    
def main(): #{Lang} & Impure = test04()
