use FactIO/CsvImport.{CsvRow, CsvResult};

def runResult(r: Result[reln, FactIO.Error]): reln & Impure = match r {
    case Ok(reln) => reln
    case Err(e) => { Console.printLine(FactIO/Error.toString(e)); #{ }}
}

    

rel Lang(name: String)

def getNewDatalog(row: CsvRow): CsvResult[#{Lang}] & Impure = 
    let wrap = s -> { Lang(s). };
    Result.map(wrap, FactIO/CsvImport.getStringByIndex(row, 0))


pub def test01(): #{Lang} & Impure =
    use Result.flatMap;
    let path = "e:/coding/flix/factio/data/new-datalogs-utf8-bom.csv";
    let step =  () -> {
        let* src = FactIO/CsvImport.newCsvStreamWithBOM(path, Text/Charset.utf_8(), false);
        let* relns = FactIO/CsvImport.importRows(getNewDatalog, src);
        Ok(solve relns)
    };
    step() |> runResult

pub def test02(): #{Lang} & Impure =
    use Result.flatMap;
    let path = "e:/coding/flix/factio/data/new-datalogs-utf8-bom.csv";
    let step =  () -> {
        let* src = FactIO/CsvImport.newCsvStream(path, FactIO/CsvFormat.Default, false);
        let* relns = FactIO/CsvImport.importRows(getNewDatalog, src);
        Ok(solve relns)
    };
    step() |> runResult


def getFunctionalLang(row: CsvRow): CsvResult[#{Lang}] & Impure = 
    let wrap = s -> { Lang(s). };
    Result.map(wrap, FactIO/CsvImport.getStringByLabel(row, "Lang Name"))

pub def test03(): #{Lang} & Impure =
    use Result.flatMap;
    let path = "e:/coding/flix/factio/data/functional-langs-utf8-bom.csv";
    let step =  () -> {
        let* src = FactIO/CsvImport.newCsvStreamWithBOM(path, Text/Charset.utf_8(), true);
        let* relns = FactIO/CsvImport.importRows(getFunctionalLang, src);
        Ok(solve relns)
    };
    step() |> runResult

pub def test04(): #{Lang} & Impure =
    use Result.flatMap;
    let path = "e:/coding/flix/factio/data/functional-langs-utf8-bom.csv";
    let step = () -> {
        let* src = FactIO/CsvImport.newCsvStream(path, FactIO/CsvFormat.Default, true);
        let* relns = FactIO/CsvImport.importRows(getFunctionalLang, src);
        Ok(solve relns)
    };
    step() |> runResult
    