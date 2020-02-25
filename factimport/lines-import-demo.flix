def fail1(msg: String): reln = 
    Console.printLine(msg);
    #{ }


rel Colour(name: String)

def makeColour(name: String): #{ Colour } = 
    Colour(name).

def getColour(line: TextLine): LineResult[#{ Colour }] = 
    Validation.fmap(makeColour, LinesImport.nonempty(line))



pub def test01(): #{ Colour } =
    let path = "e:/coding/flix/flix-doodle/factimport/data/colours.txt";
    match LinesImport.newLinesSource(path, Charset.utf_8()) {
        case Err(msg) => fail1(msg)
        case Ok(linesSource) => 
            match LinesImport.collect(getColour, linesSource) {
                case Err(msg) => fail1(msg)
                case Ok(relns) => solve relns
            }
    }
    


pub def test02(): #{ Colour } =
    let path = "e:/coding/flix/flix-doodle/factimport/data/colours.utf16le.txt";
    match LinesImport.newLinesSource(path, Charset.utf_16le()) {
        case Err(msg) => fail1(msg)
        case Ok(linesSource) => 
            match LinesImport.collect(getColour, linesSource) {
                case Err(msg) => fail1(msg)
                case Ok(relns) => solve relns
            }
    }    

