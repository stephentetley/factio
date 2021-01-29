use FactIO.FlatFileLineEvaluator;

def runResult(r1: Result[#{| reln}, String]): #{| reln} & Impure = match r1 {
    case Ok(reln) => reln
    case Err(msg) => {Console.printLine(msg); #{ } }
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


def main(_args: Array[String]): Int32 & Impure = 
    let ans = test01();
    Console.printLine(unsafeToString(ans));
    0


