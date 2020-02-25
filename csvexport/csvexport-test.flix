
@test
def stations01(): Unit = 
    let dest = "d:/coding/flix/flix-doodle/csvexport/data/stations_export.csv";
    let writer = CsvExport.new(dest, ["Name", "Grid_Ref"]);
    CsvExport.writeRow(writer, ["Bradford Interchange", "SE1657832808"]);
    CsvExport.writeRow(writer, ["Halifax", "SE0973324980"]);
    CsvExport.writeRow(writer, ["Low Moor", "SE1633428224"]);
    CsvExport.writeRow(writer, ["Mytholmroyd", "SE0127125846"]);
    CsvExport.writeRow(writer, ["Sowerby Bridge", "SE0624023505"]);
    CsvExport.close(writer)


rel Dummy(name: String, intval: Int32)

pub def dummyRelations(): #{ Dummy } = solve #{
    Dummy("a", 0).
    Dummy("b", 0).
    Dummy("c", 1).
    Dummy("d", 1).
}


/// A "cell printer" for the body of Dummy.
def dummyCells(src: (String,Int)): Array[String] = 
    let (name,i) = src;
    [name, Int32.toString(i)]



@test
def test01(): Unit = 
    let dest = "d:/coding/flix/flix-doodle/csvexport/data/dummy_export.csv";
    let writer = CsvExport.new(dest, ["Name", "Grid_Ref"]);
    let writeRow = (x, _) -> { let cells = dummyCells(x); CsvExport.writeRow(writer, cells) };
    fold Dummy () writeRow dummyRelations();
    CsvExport.close(writer)

///
/// Because fixpoint fold is not first class we cannot abstract over Dummy
/// and make our own strategies, this is about the neatest I think we can get.
///
/// Of course `writer` is in scope after the fold so we could "directly" close it
/// by name.
///
@test
def test02(): Unit = 
    let dest = "d:/coding/flix/flix-doodle/csvexport/data/dummy_export2.csv";
    let writer = CsvExport.new(dest, ["Name", "Grid_Ref"]);
    let step = CsvExport.wrapCellPrinterForFixpointFold(dummyCells);
    { fold Dummy writer step dummyRelations() } |> CsvExport.close



