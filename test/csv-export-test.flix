
@test
def stations01(): Unit & Impure =     
    let dest = "e:/coding/flix/factio/data/output/stations_export.csv";
    match FactIO/CsvExport.new(dest, System/Charset.utf_8(), ["Name", "Grid_Ref"]) {
        case Err(msg) => Console.printLine(msg)
        case Ok(writer) => {
            FactIO/CsvExport.writeRow(writer, ["Bradford Interchange", "SE1657832808"]);
            FactIO/CsvExport.writeRow(writer, ["Halifax", "SE0973324980"]);
            FactIO/CsvExport.writeRow(writer, ["Low Moor", "SE1633428224"]);
            FactIO/CsvExport.writeRow(writer, ["Mytholmroyd", "SE0127125846"]);
            FactIO/CsvExport.writeRow(writer, ["Sowerby Bridge", "SE0624023505"]);
            FactIO/CsvExport.close(writer)
        }
    }

rel Dummy(name: String, intval: Int32)

pub def dummyRelations(): #{ Dummy } = solve #{
    Dummy("a", 0).
    Dummy("b", 0).
    Dummy("c", 1).
    Dummy("d", 1).
}


/// A "cell printer" for the body of Dummy.
def dummyCells(src: (String,Int)): Array[String] & Impure = 
    let (name,i) = src;
    [name, Int32.toString(i)]



@test
def test01(): Result[Unit, String] & Impure = 
    let dest = "e:/coding/flix/factio/data/output/dummy_export.csv";
    let headers = ["name", "intval"];
    let buildStep = FactIO/CsvExport.makeBuildStep(dummyCells); 
    let builder: FactIO.CsvBuilder = fold Dummy FactIO/CsvExport.emptyCsvBuilder() buildStep dummyRelations();
    FactIO/CsvExport.outputCsv(dest, System/Charset.utf_8(), headers, builder)

///
/// Because fixpoint fold is not first class we cannot abstract over Dummy
/// and make our own strategies, this is about the neatest I think we can get.
///
/// Of course `writer` is in scope after the fold so we could "directly" close it
/// by name.
///
@test
def test02(): Result[Unit, String] & Impure = 
    let dest = "e:/coding/flix/factio/data/output/dummy_export2.csv";
    let headers = ["name", "intval"];
    let buildStep = FactIO/CsvExport.makeBuildStep(dummyCells); 
    { fold Dummy FactIO/CsvExport.emptyCsvBuilder() buildStep dummyRelations() } 
        |> FactIO/CsvExport.outputCsv(dest, System/Charset.utf_8(), headers)




