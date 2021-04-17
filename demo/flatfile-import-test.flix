use FactIO.FlatFileLineEvaluator;


def main(_args: Array[String]): Int32 & Impure = 
    test01();
    0

def printResult(rarr: Result[Array[a], String]): Unit & Impure with ToString[a] = match rarr {
    case Ok(arr) => {Console.printLine("Success:"); Array.foreach(x -> Console.printLine("${x}"), arr) }
    case Err(msg) => Console.printLine("Error: ${msg}")
}


pub def test01(): Unit & Impure =
    use Result.flatMap;
    let step = () -> {
        let path = System/FilePath.new("e:/coding/flix/factio/data/colours.txt");
        let src = FactIO/FlatFileImport.newFlatFileCursor(path, Text/Charset.utf_8());
        let* relns = FactIO/FlatFileImport.importRows!(getColour(), src);
        let arr = query relns select (x) from Colour(x);
        Ok(arr)
    };
    step() |> printResult

rel Colour(name: String)

def makeColour(name: String): #{Colour | r} = Colour(name).

def getColour(): FlatFileLineEvaluator[#{Colour | r}] = 
    use FactIO/FlatFileLineEvaluator.{flatMap, content, return};
    let* str = content();
    let ans = makeColour(str);
    return(ans)
    
