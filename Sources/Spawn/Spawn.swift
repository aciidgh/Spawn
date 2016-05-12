import Darwin.C

public enum SpawnError: ErrorProtocol {
    case CouldNotOpenPipe
    case CouldNotSpawn
}

public final class Spawn {

    /// The arguments to be executed.
    let args: [String]

    /// Closure to be executed when there is
    /// some data on stdout/stderr streams.
    var output: ((String) -> Void)?

    /// The PID of the child process.
    private(set) var pid: pid_t = 0

    /// The TID of the thread which will read streams.
    private(set) var tid: pthread_t? = nil

    private let process = "/bin/sh"
    private var outputPipe: [Int32] = [-1, -1]
    private var childFDActions: posix_spawn_file_actions_t? = nil
    private var argv: CStringArray {
        return CStringArray(["sh", "-c", args.joined(separator: " ")])
    }

    public init(args: [String]) throws {
        self.args = args 
        if pipe(&outputPipe) < 0 {
            throw SpawnError.CouldNotOpenPipe
        }

        posix_spawn_file_actions_init(&childFDActions)
        posix_spawn_file_actions_adddup2(&childFDActions, outputPipe[1], 1)
        posix_spawn_file_actions_adddup2(&childFDActions, outputPipe[1], 2)
        
        if posix_spawn(&pid, process, &childFDActions, nil, argv.pointers, nil) < 0 {
            throw SpawnError.CouldNotSpawn
        }
        watchStreams()
    }

    func watchStreams() {
        func callback(x: UnsafeMutablePointer<Void>?) -> UnsafeMutablePointer<Void>? {
            guard let x = x else { return nil }
            let pipe: Int32 = UnsafeMutablePointer<Int32>(x).pointee
            print("PIPE: \(UnsafeMutablePointer<Int32>(x).pointee)")
            close(pipe)
            let currentAllocationSize: size_t = 1024 * 8
            var dynamicBuffer: UnsafeMutablePointer<UInt8>? = nil
            dynamicBuffer = UnsafeMutablePointer<UInt8>(malloc(currentAllocationSize))
            let amountToRead = 1024 * 8
            while true {
                let amtRead = read(pipe, dynamicBuffer!, amountToRead)
                if amtRead == 0 {
                    print("EXITING")
                    break
                }
                print("REad: \(amtRead)")
                let arrary = Array(UnsafeBufferPointer(start: dynamicBuffer, count: amtRead))
                let tmp = arrary  + [UInt8(0)]
                tmp.withUnsafeBufferPointer { ptr in
                    let str = String(validatingUTF8: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
                    print("STR: \(str!)")
                }
            }
            return nil
        }
        print("THE REAL PIPE: \(outputPipe[1])")
        pthread_create(&tid, nil, callback, &outputPipe[1])
    }

     func foobar(x: UnsafeMutablePointer<Void>?) -> UnsafeMutablePointer<Void>? {
        close(outputPipe[1])
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
            tmp.withUnsafeBufferPointer { ptr in
                let str = String(validatingUTF8: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
                print("STR: \(str!)")
            }
        }
        return nil
    }

    deinit {
        var status: Int32 = 6
        pthread_join(tid, nil)
        waitpid(pid, &status, 0)
    }
}
