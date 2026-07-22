import Foundation

/// A sink the code generators append generated Swift to, then materialize with
/// `build()` into its backing handle (an in-memory `String` or a `FileHandle`).
protocol CodeWriter<Handle> {
    associatedtype Handle
    func append(_ content: String)
    func build() -> Handle
}

class StringCodeWriter: CodeWriter {
    typealias Handle = String
    private var contents: [String] = []

    func append(_ content: String) {
        contents.append(content)
    }

    func build() -> String {
        contents.joined(separator: "\n")
    }
}

class FileCodeWriter: CodeWriter {
    typealias Handle = FileHandle
    private let handle: FileHandle

    init(handle: FileHandle) {
        self.handle = handle
    }

    func append(_ content: String) {
        handle.write(content.data(using: .utf8)!)
    }

    func build() -> FileHandle {
        handle
    }
}
