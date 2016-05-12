import PackageDescription

let package = Package(
    name: "Spawn",
    targets: [Target(name: "SpawnDemo", dependencies: ["Spawn"])]
)
