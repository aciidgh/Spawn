# Spawn

* Note: Works on macOS and Linux.

* Spawn runs new processes using `posix_spawn` and reads output (and stderr stream) on a different thread so the calling thread is never blocked.

# How to use?

Just pass the arguments to execute. For example:

```swift
import Spawn

do {
    let spawn = try Spawn(args: ["/bin/sh", "-c", "ls", "."]) { str in
        print(str)
    }
} catch {
    print("error: \(error)")
}
```

# How to install?

### Swift Package Manager:
* Add dependency in `Package.swift`

```swift
import PackageDescription

let package = Package(
    name: "MyPackage",

    dependencies: [
        .Package(url: "https://github.com/aciidb0mb3r/Spawn", majorVersion: 0)
    ]
)
```

# License
MIT
