use FactIO/LinesImport.{TextLine, LineResult};

def runResult(r1: Result[reln, FactIO.Error]): reln & Impure = match r1 {
    case Ok(reln) => reln
    case Err(e) => {
        Console.printLine(FactIO/Error.toString(e));
        #{ }
    }
}

rel Colour(name: String)

def makeColour(name: String): #{ Colour } = 
    Colour(name).

def getColour(line: TextLine): LineResult[#{ Colour }] & e = 
    Result.map(makeColour, FactIO/LinesImport.nonempty(line))
    
pub def test01(): #{ Colour } & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = "e:/coding/flix/factio/data/colours.txt";
        let* src = FactIO/LinesImport.newLinesStream(path, System/Charset.utf_8());
        let* relns = FactIO/LinesImport.importRows(getColour, src);
        Ok(solve relns)
    };
    step() |> runResult

pub def test02(): #{ Colour } & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = "e:/coding/flix/factio/data/colours.utf16le.txt";
        let* src = FactIO/LinesImport.newLinesStream(path, System/Charset.utf_16le());
        let* relns = FactIO/LinesImport.importRows(getColour, src);
        Ok (solve relns)
    };
    step() |> runResult   

