use FactIO/CsvImport.{CsvRow, CsvResult};

def fail1(msg: String): reln & Impure = 
    Console.printLine(msg);
    #{ }


rel Name(name: String)

def makeName(name: String): #{ Name } = 
    Name(name).

def getName(row: CsvRow): CsvResult[#{Name}] = 
    Validation.map(makeName, FactIO/CsvImport.getStringByLabel(row, "Name"))


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


def getStation(row: CsvRow): CsvResult[#{Station}] = 
    Validation.lift2(
        (x,y) -> { Station(x, y). },
        FactIO/CsvImport.getStringByLabel(row, "Name"), 
        FactIO/CsvImport.getStringByLabel(row, "Grid_Ref")
    )


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


