import Spawn

do {
    let spawn = try Spawn(args: ["/bin/sh", "-c", ["ls", "/"].joined(separator: " ")]) { str in 
        print(str)
    }
} catch {
    print("error: \(error)")
}
