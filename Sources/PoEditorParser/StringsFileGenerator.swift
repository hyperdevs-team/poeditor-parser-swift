import Foundation

public class StringsFileGenerator {
    let fileHandle: FileHandle

    public init(fileHandle: FileHandle) {
        self.fileHandle = fileHandle
    }

    public func generateCode(translations: [Translation]) {
        for translation in translations {
            fileHandle += "\"\(translation.key)\" = \"\(translation.value)\";\n"
        }
    }
}
