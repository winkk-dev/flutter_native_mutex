// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_native_mutex",
    platforms: [.iOS("15.0")],
    products: [
        .library(name: "flutter-native-mutex", targets: ["flutter_native_mutex"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_native_mutex",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
