
@test
def stations01(): Result[Unit, System.Error] & Impure =
    use Result.flatMap;
    let dest    = "e:/coding/flix/factio/data/output/stations_export.csv";
    let* writer = FactIO/CsvExport.new(dest, Text/Charset.utf_8(), ["Name", "Grid_Ref"]);
    let* _      = FactIO/CsvExport.writeRow(writer, ["Bradford Interchange", "SE1657832808"]);
    let* _      = FactIO/CsvExport.writeRow(writer, ["Halifax", "SE0973324980"]);
    let* _      = FactIO/CsvExport.writeRow(writer, ["Low Moor", "SE1633428224"]);
    let* _      = FactIO/CsvExport.writeRow(writer, ["Mytholmroyd", "SE0127125846"]);
    let* _      = FactIO/CsvExport.writeRow(writer, ["Sowerby Bridge", "SE0624023505"]);
    let* _      = FactIO/CsvExport.close(writer);
    Ok()


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
def test01(): Result[Unit, System.Error] & Impure = 
    let dest = "e:/coding/flix/factio/data/output/dummy_export.csv";
    let headers = ["name", "intval"];
    let writeStep = FactIO/CsvExport.makeCsvWriteStep(dummyCells); 
    let writes: FactIO.CsvWriteList = fold Dummy FactIO/CsvExport.emptyCsvWriteList() writeStep dummyRelations();
    FactIO/CsvExport.outputCsv(dest, Text/Charset.utf_8(), headers, writes)

///
/// Because fixpoint fold is not first class we cannot abstract over Dummy
/// and make our own strategies, this is about the neatest I think we can get.
///
/// Of course `writer` is in scope after the fold so we could "directly" close it
/// by name.
///
@test
def test02(): Result[Unit, System.Error] & Impure = 
    let dest = "e:/coding/flix/factio/data/output/dummy_export2.csv";
    let headers = ["name", "intval"];
    let writeStep = FactIO/CsvExport.makeCsvWriteStep(dummyCells); 
    { fold Dummy FactIO/CsvExport.emptyCsvWriteList() writeStep dummyRelations() } 
        |> FactIO/CsvExport.outputCsv(dest, Text/Charset.utf_8(), headers)

def main(): Result[Unit, System.Error] & Impure = stations01()


