import Foundation

protocol CodeKeeper<Handle> {
    associatedtype Handle
    func append(_ content: String)
    func build() -> Handle
}

class StringKeeper: CodeKeeper {
    typealias Handle = String
    private var contents: [String] = []

    func append(_ content: String) {
        contents.append(content)
    }

    func build() -> String {
        contents.joined(separator: "\n")
    }
}

class FileHandleKeeper: CodeKeeper {
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
