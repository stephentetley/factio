use FactIO.CsvExport;
use FactIO.CsvRowSetter;


def main(_args: Array[String]): Int32 & Impure = 
    match test01() {
        case Ok() => 0
        case Err(msg) => {Console.printLine(msg); 1}
    }

def test01(): Result[Unit, String] & Impure = 
    use Result.flatMap;
    use FactIO/CsvExport.{exportCsv};
    let outpath = System/FilePath.new("e:/coding/flix/factio/data/output/dummy_export.csv");
    let headers = ["name", "intval"];
    let db = dummyRelations();
    let arr = query db select (n, v) from Dummy(n, v);
    let* _ = exportCsv(FactIO/CsvFormat.default(), Text/Charset.utf_8(), headers, writeRow, arr, outpath);
    let* _ = temp01();
    Ok()




rel Dummy(name: String, intval: Int32)

pub def dummyRelations(): #{Dummy | r} = solve #{
    Dummy("a", 0).
    Dummy("b", 0).
    Dummy("c", 1).
    Dummy("d", 1).
    Dummy("e", 2).
    Dummy("f", 2).
}

def temp01(): Result[Unit, String] & Impure = 
    let db = dummyRelations();
    let arr = query db select (n, v) from Dummy(n, v);
    Console.printLine("Length: ${Array.length(arr)}");
    Ok()

/// A RowWriter for the body of Dummy.
def writeRow(src: (String, Int)): CsvRowSetter[Unit] = 
    use FactIO/CsvRowSetter.{flatMap, point, putString!, putInt32!};
    let (name,i) = src;
    let* _ = putString!(0, name);
    let* _ = putInt32!(1, i);
    point()




