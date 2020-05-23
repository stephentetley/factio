use FactIO.CsvRowEvaluator;

def runResult(r: Result[reln, System.Error]): reln & Impure = match r {
    case Ok(reln) => reln
    case Err(e) => { Console.printLine(System/Error.toString(e)); #{ }}
}

    

rel Lang(name: String)

def getNewDatalog(): CsvRowEvaluator[#{Lang}] =
    use FactIO/CsvRowEvaluator.{map, getStringByLabel}; 
    map(s -> { Lang(s). }, getStringByLabel("Lang"))

/// Should fail
pub def test01(): #{Lang} & Impure =
    use Result.flatMap;
    let path = "e:/coding/flix/factio/data/new-datalogs-utf8-bom.csv";
    let step =  () -> {
        let* src = FactIO/CsvImport.newCsvStream(path, FactIO/CsvFormat.Default, true);
        let* relns = FactIO/CsvImport.importRows(getNewDatalog(), src);
        Ok(solve relns)
    };
    Console.printLine("Should fail...");
    step() |> runResult

pub def test02(): #{Lang} & Impure =
    use Result.flatMap;
    let path = "e:/coding/flix/factio/data/new-datalogs-utf8-bom.csv";
    let step =  () -> {
        let* src = FactIO/CsvImport.newCsvStreamWithBOM(path, Text/Charset.utf_8(), true);
        let* relns = FactIO/CsvImport.importRows(getNewDatalog(), src);
        Ok(solve relns)
    };
    Console.printLine("Should run...");
    step() |> runResult


def getFunctionalLang(): CsvRowEvaluator[#{Lang}] = 
    use FactIO/CsvRowEvaluator.{map, getStringByLabel}; 
    map(s -> { Lang(s). }, getStringByLabel("Lang Name"))

pub def test03(): #{Lang} & Impure =
    use Result.flatMap;
    let path = "e:/coding/flix/factio/data/functional-langs-utf8-bom.csv";
    let step =  () -> {
        let* src = FactIO/CsvImport.newCsvStream(path, FactIO/CsvFormat.Default, true); 
        let* relns = FactIO/CsvImport.importRows(getFunctionalLang(), src);
        Ok(solve relns)
    };
    Console.printLine("Should fail...");
    step() |> runResult

pub def test04(): #{Lang} & Impure =
    use Result.flatMap;
    let path = "e:/coding/flix/factio/data/functional-langs-utf8-bom.csv";
    let step = () -> {
        let* src = FactIO/CsvImport.newCsvStreamWithBOM(path, Text/Charset.utf_8(), true);
        let* relns = FactIO/CsvImport.importRows(getFunctionalLang(), src);
        Ok(solve relns)
    };
    Console.printLine("Should run...");
    step() |> runResult
    