import Spawn

do {
    let spawn = try Spawn(args: ["echo", "HELLOOOOO"])
    
} catch {
    print("error: \(error)")
}
