def fail1(msg: String): reln = 
    Console.printLine(msg);
    #{ }


rel Name(name: String)

def makeName(name: String): #{ Name } = 
    Name(name).

def getName(row: CsvRow): CsvResult[#{Name}] = 
    Validation.fmap(makeName, CsvImport.getStringByLabel(row, "Name"))


pub def test01(): #{Name} =
    let path = "e:/coding/flix/flix-doodle/factimport/data/stations.csv";
    match CsvImport.newCsvSource(path, CsvFormat.Default, true) {
        case Err(msg) => fail1(msg)
        case Ok(csvSource) => 
            match CsvImport.collect(getName, csvSource) {
                case Err(msg) => fail1(msg)
                case Ok(relns) => solve relns
            }
    }
    

rel Station(name: String, gridref: String)


def getStation(row: CsvRow): CsvResult[#{Station}] = 
    Validation.pipeV2(CsvImport.getStringByLabel(row, "Name"), 
                        CsvImport.getStringByLabel(row, "Grid_Ref"), 
                        (x,y) -> Station(x, y).)


pub def test02(): #{Station} =
    let path = "e:/coding/flix/flix-doodle/factimport/data/stations.csv";
    match CsvImport.newCsvSource(path, CsvFormat.Default, true) {
        case Err(msg) => fail1(msg)
        case Ok(csvSource) => 
            match CsvImport.collect(getStation, csvSource) {
                case Err(msg) => fail1(msg)
                case Ok(relns) => solve relns            
            }
    }


