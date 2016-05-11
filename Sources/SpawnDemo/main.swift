import Spawn
import Darwin.C
// Is this really the best way to extend the lifetime of C-style strings? The lifetime
// of those passed to the String.withCString closure are only guaranteed valid during
// that call. Tried cheating this by returning the same C string from the closure but it
// gets dealloc'd almost immediately after the closure returns. This isn't terrible when
// dealing with a small number of constant C strings since you can nest closures. But
// this breaks down when it's dynamic, e.g. creating the char** argv array for an exec
// call.
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

// An array of C-style strings (e.g. char**) for easier interop.
class CStringArray {
    // Have to keep the owning CString's alive so that the pointers
    // in our buffer aren't dealloc'd out from under us.
    private let _strings: [CString]
    var pointers: [UnsafeMutablePointer<Int8>?]

    init(_ strings: [String]) {
        _strings = strings.map { CString($0) }
        pointers = _strings.map { $0.buffer }
        // NULL-terminate our string pointer buffer since things like
        // exec*() and posix_spawn() require this.
        pointers.append(nil)
    }
}

let process = "/bin/sh"
let theArgs = ["ls", "/"]
let args = CStringArray(["sh", "-c", theArgs.joined(separator: " ")])
var pid: pid_t = 0



var outputPipe: [Int32] = [-1, -1]
var child_fd: posix_spawn_file_actions_t? = nil

let ret = pipe(&outputPipe)
if ret < 0 {
    print("cant make pipe")
}

posix_spawn_file_actions_init(&child_fd)
posix_spawn_file_actions_adddup2(&child_fd, outputPipe[1], 1)
posix_spawn_file_actions_adddup2(&child_fd, outputPipe[1], 2)
let spawn = posix_spawn(&pid, process, &child_fd, nil, args.pointers, nil)
print("pid: \(pid)")

func foo(x: UnsafeMutablePointer<Void>?) -> UnsafeMutablePointer<Void>? {
close(outputPipe[1])
    print("PROCES: \(process)")

let currentAllocationSize: size_t = 1024 * 8
var dynamicBuffer: UnsafeMutablePointer<UInt8>? = nil
dynamicBuffer = UnsafeMutablePointer<UInt8>(malloc(currentAllocationSize))
 let amountToRead = 1024 * 8
 while true {
 let amtRead = read(outputPipe[0], dynamicBuffer!, amountToRead)
if amtRead == 0 {
    print("EXITING")
    break
}
 print("REad: \(amtRead)")
 let arrary = Array(UnsafeBufferPointer(start: dynamicBuffer, count: amtRead))
let tmp = arrary  + [UInt8(0)]
print("tmp: \(tmp)")
tmp.withUnsafeBufferPointer { ptr in
    let str = String(validatingUTF8: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
    print("STR: \(str!)")
}
 }
    return nil
}
var tid: pthread_t? = nil
pthread_create(&tid, nil, foo, nil)
print("tid: \(tid)")

var status:Int32 = 6
pthread_join(tid, nil)
waitpid(pid, &status, 0)

