import Foundation

class StreamReader  {
    
    let encoding: String.Encoding
    let chunkSize: Int
    
    var fileHandle: FileHandle!
    var buffer: Data!
    let delimData: Data!
    var atEof: Bool = false
    
    init?(path: String, delimiter: String = "\n", encoding: String.Encoding = .utf8, chunkSize : Int = 4096) {
        self.chunkSize = chunkSize
        self.encoding = encoding
        
        if let fileHandle = FileHandle(forReadingAtPath: path),
            let delimData = delimiter.data(using: encoding) {
            self.fileHandle = fileHandle
            self.delimData = delimData
            self.buffer = Data(capacity: chunkSize)
        } else {
            self.fileHandle = nil
            self.delimData = nil
            self.buffer = nil
            return nil
        }
    }
    
    deinit {
        self.close()
    }
    
    /// Return next line, or nil on EOF.
    func nextLine() -> String? {
        precondition(fileHandle != nil, "Attempt to read from closed file")
        
        if atEof {
            return nil
        }
        
        // Read data chunks from file until a line delimiter is found:
        while let range = buffer.range(of: delimData, options: [], in: 0..<buffer.count) {
            let tmpData = fileHandle.readData(ofLength: chunkSize)
            if tmpData.isEmpty {
                // EOF or read error
                atEof = true
                if !buffer.isEmpty {
                    let line = String(data: buffer, encoding: encoding)
                    buffer.count = 0
                    return line
                }
                // No more lines.
                return nil
            }
            buffer.append(tmpData)

            // Convert complete line (excluding the delimiter) to a string:
            let line = String(data: buffer.subdata(in: range), encoding: .utf8)
            // Remove line (and the delimiter) from the buffer:
            var pointer: Int? = nil
            buffer.replaceSubrange(range, with: &pointer, count: 0)
            return line
        }
        return nil
    }
    
    /// Start reading from the beginning of file.
    func rewind() -> Void {
        fileHandle.seek(toFileOffset: 0)
        buffer.count = 0
        atEof = false
    }
    
    /// Close the underlying file. No reading must be done after calling this method.
    func close() -> Void {
        fileHandle?.closeFile()
        fileHandle = nil
    }
}
