import Spawn

do {
    let spawn = try Spawn(args: ["/bin/sh", "-c", "ls", "."]) { str in 
        print(str)
    }
} catch {
    print("error: \(error)")
}
