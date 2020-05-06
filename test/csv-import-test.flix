use FactIO/CsvImport.{CsvRow, CsvResult};

def runResult(r1: Result[reln, FactIO.Error]): reln & Impure = match r1 {
    case Ok(reln) => reln
    case Err(e) => {
        Console.printLine(FactIO/Error.toString(e));
        #{ }
    }
}

    
rel Name(name: String)

def makeName(name: String): #{ Name } = 
    Name(name).

def getName(row: CsvRow): CsvResult[#{Name}] & Impure = 
    Result.map(makeName, FactIO/CsvImport.getStringByLabel(row, "Name"))


pub def test01(): #{Name} & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = "e:/coding/flix/factio/data/stations.csv";
        let* src = FactIO/CsvImport.newCsvStream(path, FactIO/CsvFormat.Default, true);
        let* ans = FactIO/CsvImport.importRows(getName, src);
        Ok(solve ans)        
    };
    step() |> runResult
    

rel Station(name: String, gridref: String)


def getStation(row: CsvRow): CsvResult[#{Station}] & Impure = 
    use Result.flatMap;
    let* x = FactIO/CsvImport.getStringByLabel(row, "Name");
    let* y = FactIO/CsvImport.getStringByLabel(row, "Grid_Ref");
    Ok({ Station(x, y). })
    

pub def test02(): #{Station} & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = "e:/coding/flix/factio/data/stations.csv";
        let* src = FactIO/CsvImport.newCsvStream(path, FactIO/CsvFormat.Default, true);
        let* relns = FactIO/CsvImport.importRows(getStation, src);
        Ok(solve relns)
    };
    step() |> runResult



