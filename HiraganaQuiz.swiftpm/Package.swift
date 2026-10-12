// swift-tools-version: 5.9

// WARNING:
// This is a Swift Playgrounds app package. Open it with Xcode or Swift Playgrounds.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "HiraganaQuiz",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "HiraganaQuiz",
            targets: ["AppModule"],
            bundleIdentifier: "local.characterstudy.HiraganaQuiz",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .openBook),
            accentColor: .presetColor(.orange),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            capabilities: [
                .microphone(purposeString: "こどもの はつおんを きくために マイクを つかいます。"),
                .speechRecognition(purposeString: "はつおんが あっているか しらべるために おんせいにんしきを つかいます。")
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)
