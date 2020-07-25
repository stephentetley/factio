use FactIO.FlatFileLineEvaluator;

def runResult(r1: Result[reln, System.Error]): reln & Impure = match r1 {
    case Ok(reln) => reln
    case Err(e) => {
        Console.printLine(System/Error.toString(e));
        #{ }
    }
}

rel Colour(name: String)

def makeColour(name: String): #{ Colour } = Colour(name).

def getColour(): FlatFileLineEvaluator[#{ Colour }] = 
    use FactIO/FlatFileLineEvaluator.{flatMap, content, return};
    let* str = content();
    let ans = makeColour(str);
    return(ans)
    

pub def test01(): #{ Colour } & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = System/FilePath.new("e:/coding/flix/factio/data/colours.txt");
        let* src = FactIO/FlatFileImport.newFlatFileStream(path, Text/Charset.utf_8());
        let* relns = FactIO/FlatFileImport.importRows(getColour(), src);
        Ok(solve relns)
    };
    step() |> runResult


def main(): #{ Colour } & Impure = test01()


