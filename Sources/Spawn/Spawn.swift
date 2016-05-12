#if os(OSX)
import Darwin.C
#else
import Glibc
#endif

public enum SpawnError: ErrorProtocol {
    case CouldNotOpenPipe
    case CouldNotSpawn
}

public typealias OutputClosure = (String) -> Void

public final class Spawn {

    /// The arguments to be executed.
    let args: [String]

    /// Closure to be executed when there is
    /// some data on stdout/stderr streams.
    private var output: OutputClosure?

    /// The PID of the child process.
    private(set) var pid: pid_t = 0

    /// The TID of the thread which will read streams.
    #if os(OSX)
    private(set) var tid: pthread_t? = nil
    #else
    private(set) var tid = pthread_t()
    #endif

    private let process = "/bin/sh"
    private var outputPipe: [Int32] = [-1, -1]
    #if os(OSX)
    private var childFDActions: posix_spawn_file_actions_t? = nil
    #else
    private var childFDActions = posix_spawn_file_actions_t()
    #endif

    public init(args: [String], output: OutputClosure? = nil) throws {
        self.args = args 
        self.output = output
        if pipe(&outputPipe) < 0 {
            throw SpawnError.CouldNotOpenPipe
        }

        posix_spawn_file_actions_init(&childFDActions)
        posix_spawn_file_actions_adddup2(&childFDActions, outputPipe[1], 1)
        posix_spawn_file_actions_adddup2(&childFDActions, outputPipe[1], 2)
        posix_spawn_file_actions_addclose(&childFDActions, outputPipe[0])
        posix_spawn_file_actions_addclose(&childFDActions, outputPipe[1])
        let argv: [UnsafeMutablePointer<CChar>?] = args.map{ $0.withCString(strdup) }
        defer { for case let arg? in argv { free(arg) } }
        if posix_spawn(&pid, argv[0], &childFDActions, nil, argv + [nil], nil) < 0 {
            throw SpawnError.CouldNotSpawn
        }
        watchStreams()
    }

    struct ThreadInfo {
        let outputPipe: UnsafeMutablePointer<Int32>
        let output: OutputClosure?
    }
    var threadInfo: ThreadInfo!

    func watchStreams() {
        func callback(x: UnsafeMutablePointer<Void>?) -> UnsafeMutablePointer<Void>? {
            guard let x = x else { return nil }
            let threadInfo = UnsafeMutablePointer<ThreadInfo>(x).pointee
            let outputPipe = threadInfo.outputPipe
            close(outputPipe[1])
            let bufferSize: size_t = 1024 * 8
            var dynamicBuffer: UnsafeMutablePointer<UInt8>? = nil
            dynamicBuffer = UnsafeMutablePointer<UInt8>(malloc(bufferSize))
            while true {
                let amtRead = read(outputPipe[0], dynamicBuffer!, bufferSize)
                if amtRead <= 0 { break }
                let arrary = Array(UnsafeBufferPointer(start: dynamicBuffer, count: amtRead))
                let tmp = arrary  + [UInt8(0)]
                tmp.withUnsafeBufferPointer { ptr in
                    let str = String(cString: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
                    threadInfo.output?(str)
                }
            }
           return nil
        }
        threadInfo = ThreadInfo(outputPipe: &outputPipe, output: output)
        pthread_create(&tid, nil, callback, &threadInfo)
    }

    deinit {
        var status: Int32 = 0
        pthread_join(tid, nil)
        waitpid(pid, &status, 0)
    }
}
