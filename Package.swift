// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "FeatureMovies",
  platforms: [.iOS(.v17)],
  products: [
    .library(
      name: "FeatureMovies",
      targets: ["FeatureMovies"]),
  ],
  dependencies: [
    .package(name: "SharedDomainPkg",
        url: "https://github.com/zeekands/Modularization-Domain-Module-IOS.git",
        branch: "main"),
    .package(path: "../SharedUI"),     // Bergantung pada SharedUI
  ],
  targets: [
    .target(
      name: "FeatureMovies",
      dependencies: [
        .product(name: "SharedDomain", package: "SharedDomainPkg"),
        .product(name: "SharedUI", package: "SharedUI"),
      ]),
    .testTarget(
      name: "FeatureMoviesTests",
      dependencies: ["FeatureMovies"]),
  ]
)
