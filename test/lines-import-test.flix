use FactIO/LinesImport.{TextLine, LineResult};

def fail1(msg: String): reln & Impure= 
    Console.printLine(msg);
    #{ }

rel Colour(name: String)

def makeColour(name: String): #{ Colour } = 
    Colour(name).

def getColour(line: TextLine): LineResult[#{ Colour }] & e = 
    Result.map(makeColour, FactIO/LinesImport.nonempty(line))
    
pub def test01(): #{ Colour } & Impure =
    let path = "e:/coding/flix/factio/data/colours.txt";
    match FactIO/LinesImport.newLinesSource(path, System/Charset.utf_8()) {
        case Err(msg) => fail1(msg)
        case Ok(linesSource) => 
            match FactIO/LinesImport.iterate(getColour, linesSource) {
                case Err(msg) => fail1(msg)
                case Ok(relns) => solve relns
            }
    }

pub def test02(): #{ Colour } & Impure=
    let path = "e:/coding/flix/factio/data/colours.utf16le.txt";
    match FactIO/LinesImport.newLinesSource(path, System/Charset.utf_16le()) {
        case Err(msg) => fail1(msg)
        case Ok(linesSource) => 
            match FactIO/LinesImport.iterate(getColour, linesSource) {
                case Err(msg) => fail1(msg)
                case Ok(relns) => solve relns
            }
    }    

