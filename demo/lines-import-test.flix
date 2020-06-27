use FactIO.LineEvaluator;
use FactIO.LinesParser;

def runResult(r1: Result[reln, System.Error]): reln & Impure = match r1 {
    case Ok(reln) => reln
    case Err(e) => {
        Console.printLine(System/Error.toString(e));
        #{ }
    }
}

rel Colour(name: String)

def makeColour(name: String): #{ Colour } = Colour(name).

def getColour1(): LineEvaluator[#{ Colour }] = 
    use FactIO/LineEvaluator.{flatMap, content, return};
    let* str = content();
    let ans = makeColour(str);
    return(ans)
    
def getColours(): LinesParser[#{ Colour }, Unit] = 
    use FactIO/LinesParser.{lines};
    lines(getColour1())

pub def test01(): #{ Colour } & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = "e:/coding/flix/factio/data/colours.txt";
        let* relns = FactIO/LinesParser.runLinesParser(getColours(), (), path, Text/Charset.utf_8());
        Ok(solve relns)
    };
    step() |> runResult

// pub def test02(): #{ Colour } & Impure =
//     use Result.flatMap;
//     let step = () -> {
//         let path = "e:/coding/flix/factio/data/colours.utf16le.txt";
//         let* relns = FactIO/LinesParser.runLinesParser(getColours(), path, Text/Charset.utf_16le());
//         Ok (solve relns)
//     };
//     step() |> runResult   

def main(): #{ Colour } & Impure = test01()


