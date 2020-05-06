use FactIO/CsvImport.{CsvRow, CsvResult};

def fail1(msg: String): reln & Impure = 
    Console.printLine(msg);
    #{ }


rel Name(name: String)

def makeName(name: String): #{ Name } = 
    Name(name).

def getName(row: CsvRow): CsvResult[#{Name}] & Impure = 
    Result.map(makeName, FactIO/CsvImport.getStringByLabel(row, "Name"))


pub def test01(): #{Name} & Impure =
    let path = "e:/coding/flix/factio/data/stations.csv";
    match FactIO/CsvImport.newCsvSource(path, FactIO/CsvFormat.Default, true) {
        case Err(msg) => fail1(msg)
        case Ok(csvSource) => 
            match FactIO/CsvImport.iterate(getName, csvSource) {
                case Err(msg) => fail1(msg)
                case Ok(relns) => solve relns
            }
    }
    

rel Station(name: String, gridref: String)


def getStation(row: CsvRow): CsvResult[#{Station}] & Impure = 
    use Result.flatMap;
    let* x = FactIO/CsvImport.getStringByLabel(row, "Name");
    let* y = FactIO/CsvImport.getStringByLabel(row, "Grid_Ref");
    Ok({ Station(x, y). })
    

pub def test02(): #{Station} & Impure =
    let path = "e:/coding/flix/factio/data/stations.csv";
    match FactIO/CsvImport.newCsvSource(path, FactIO/CsvFormat.Default, true) {
        case Err(msg) => fail1(msg)
        case Ok(csvSource) => 
            match FactIO/CsvImport.iterate(getStation, csvSource) {
                case Err(msg) => fail1(msg)
                case Ok(relns) => solve relns            
            }
    }


