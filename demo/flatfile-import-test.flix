use FactIO.FlatFileLineEvaluator;


def main(_args: Array[String]): Int32 & Impure = 
    test01();
    0

def runResult(r: Result[#{| reln}, String]): Unit & Impure = match r {
    case Ok(reln) => reln |> unsafeToString |> println
    case Err(msg) => Console.printLine("Error: ${msg}")
}


pub def test01(): Unit & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = System/FilePath.new("e:/coding/flix/factio/data/colours.txt");
        let src = FactIO/FlatFileImport.newFlatFileCursor(path, Text/Charset.utf_8());
        let* relns = FactIO/FlatFileImport.importRows(getColour(), src);
        Ok(solve relns)
    };
    step() |> runResult

rel Colour(name: String)

def makeColour(name: String): #{ Colour } = Colour(name).

def getColour(): FlatFileLineEvaluator[#{ Colour }] = 
    use FactIO/FlatFileLineEvaluator.{flatMap, content, return};
    let* str = content();
    let ans = makeColour(str);
    return(ans)
    
