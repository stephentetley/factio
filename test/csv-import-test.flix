use FactIO.CsvRowEvaluator;

def runResult(r1: Result[reln, System.Error]): reln & Impure = match r1 {
    case Ok(reln) => reln
    case Err(e) => {
        Console.printLine(System/Error.toString(e));
        #{ }
    }
}

    
rel Name(name: String)

def makeName(name: String): #{ Name } = 
    Name(name).

def getName(): CsvRowEvaluator[#{Name}] = 
    use FactIO/CsvRowEvaluator.{map, getStringByLabel};
    map(makeName, getStringByLabel("Name"))


pub def test01(): #{Name} & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = "e:/coding/flix/factio/data/stations.csv";
        let* src = FactIO/CsvImport.newCsvStream(path, FactIO/CsvFormat.Default, true);
        let* ans = FactIO/CsvImport.importRows(getName(), src);
        Ok(solve ans)        
    };
    step() |> runResult
    

rel Station(name: String, gridref: String)


def getStation(): CsvRowEvaluator[#{Station}] = 
    use FactIO/CsvRowEvaluator.{flatMap, getStringByLabel, return};
    let* x = getStringByLabel("Name");
    let* y = getStringByLabel("Grid_Ref");
    return({ Station(x, y). })
    

pub def test02(): #{Station} & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = "e:/coding/flix/factio/data/stations.csv";
        let* src = FactIO/CsvImport.newCsvStream(path, FactIO/CsvFormat.Default, true);
        let* relns = FactIO/CsvImport.importRows(getStation(), src);
        Ok(solve relns)
    };
    step() |> runResult



