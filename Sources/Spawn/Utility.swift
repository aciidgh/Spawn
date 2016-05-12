import Darwin.C

class CString {
    private let _len: Int
    let buffer: UnsafeMutablePointer<Int8>
    init(_ string: String) {
        (_len, buffer) = string.withCString {
            let len = Int(strlen($0) + 1)
            let dst = strcpy(UnsafeMutablePointer<Int8>(allocatingCapacity: len), $0)
            return (len, dst!)
        }
    }
    deinit {
        buffer.deallocateCapacity(_len)
    }
}

class CStringArray {
    private let _strings: [CString]
    var pointers: [UnsafeMutablePointer<Int8>?]
    init(_ strings: [String]) {
        _strings = strings.map { CString($0) }
        pointers = _strings.map { $0.buffer }
        pointers.append(nil)
    }
}
