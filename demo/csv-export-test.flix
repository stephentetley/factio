use FactIO.CsvExport;
use FactIO.CsvWriteList;
use FactIO.CsvRowWriter;

/// TODO - work out how to use CsvExport for "non-relations"...

// @test
// def stations01(): Result[Unit, System.Error] & Impure =
//     use Result.flatMap;
//     let dest    = "e:/coding/flix/factio/data/output/stations_export.csv";
//     let* writer = FactIO/CsvExport.new(dest, Text/Charset.utf_8(), ["Name", "Grid_Ref"]);
//     let* _      = FactIO/CsvExport.writeRow(writer, ["Bradford Interchange", "SE1657832808"]);
//     let* _      = FactIO/CsvExport.writeRow(writer, ["Halifax", "SE0973324980"]);
//     let* _      = FactIO/CsvExport.writeRow(writer, ["Low Moor", "SE1633428224"]);
//     let* _      = FactIO/CsvExport.writeRow(writer, ["Mytholmroyd", "SE0127125846"]);
//     let* _      = FactIO/CsvExport.writeRow(writer, ["Sowerby Bridge", "SE0624023505"]);
//     let* _      = FactIO/CsvExport.close(writer);
//     Ok()


rel Dummy(name: String, intval: Int32)

pub def dummyRelations(): #{ Dummy } = solve #{
    Dummy("a", 0).
    Dummy("b", 0).
    Dummy("c", 1).
    Dummy("d", 1).
}


/// A RowWriter for the body of Dummy.
def writeRow(src: (String,Int)): CsvRowWriter[Unit] = 
    use FactIO/CsvRowWriter.{flatMap, return, putString!, putInt32!};
    let (name,i) = src;
    let* _ = putString!(0, name);
    let* _ = putInt32!(1, i);
    return()


def writeStep(): ((String, Int32), CsvWriteList) -> CsvWriteList = 
    FactIO/CsvExport.makeCsvWriteStep(writeRow)

def writeOutput(): CsvExport[Unit] =
    use FactIO/CsvExport.{flatMap, return, emptyCsvWriteList, execWriteList};
    let writes      = fold Dummy emptyCsvWriteList() writeStep() (solve dummyRelations());
    let* _          = execWriteList(writes);
    return()



def test01(): Result[Unit, System.Error] & Impure = 
    use Result.flatMap;
    use FactIO/CsvExport.{runCsvExport};
    let path = System/FilePath.new("e:/coding/flix/factio/data/output/dummy_export.csv");
    let headers = ["name", "intval"];
    let* _ = runCsvExport(writeOutput(), path, FactIO/CsvFormat.default(), headers, Text/Charset.utf_8());
    Ok()


def main(): Result[Unit, System.Error] & Impure = test01()


