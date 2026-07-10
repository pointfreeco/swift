// RUN: %empty-directory(%t)
// RUN: %target-build-swift -enable-experimental-feature CaseKeyPaths %s -o %t/main
// RUN: %target-codesign %t/main
// RUN: %target-run %t/main

// REQUIRES: executable_test
// REQUIRES: swift_feature_CaseKeyPaths
// REQUIRES: OS=macosx

// Compiled without `CaseKeyPath` runtime support at the deployment target,
// case components use the back-deployed computed encoding. The projected
// values must match the native encoding's.

import StdlibUnittest

enum Destination: Equatable {
  case settings(Int)
  case profile(name: String)
  case search(query: String, page: Int)
  case home
}

var BackDeployTests = TestSuite("CaseKeyPathBackDeploy")

BackDeployTests.test("extraction") {
  let kp: KeyPath<Destination, Int?> = \Destination.settings
  expectEqual(42, Destination.settings(42)[keyPath: kp])
  expectNil(Destination.home[keyPath: kp])

  let labeled: KeyPath<Destination, String?> = \Destination.profile
  expectEqual("blob", Destination.profile(name: "blob")[keyPath: labeled])

  let tuple: KeyPath<Destination, (query: String, page: Int)?> =
    \Destination.search
  let values = Destination.search(query: "cats", page: 3)[keyPath: tuple]
  expectEqual("cats", values?.query)
  expectEqual(3, values?.page)

  let void: KeyPath<Destination, Void?> = \Destination.home
  expectNotNil(Destination.home[keyPath: void])
  expectNil(Destination.settings(1)[keyPath: void])
}

BackDeployTests.test("chaining") {
  let chained: KeyPath<Destination, Int?> = \Destination.profile?.count
  expectEqual(4, Destination.profile(name: "blob")[keyPath: chained])
  expectNil(Destination.home[keyPath: chained])
}

enum Outer: Equatable {
  case inner(Destination)
}

BackDeployTests.test("composed literal") {
  let deep: KeyPath<Outer, Int?> = \Outer.inner?.settings
  expectEqual(42, Outer.inner(.settings(42))[keyPath: deep])
  expectNil(Outer.inner(.home)[keyPath: deep])
}

@dynamicMemberLookup
struct Props<Root> {
  let root: Root
  subscript<Value>(dynamicMember keyPath: KeyPath<Root, Value>) -> Value {
    root[keyPath: keyPath]
  }
}

BackDeployTests.test("plain dynamic member lookup") {
  let props = Props(root: Destination.settings(42))
  expectEqual(42, props.settings)
  expectNil(Props(root: Destination.home).settings)
}

BackDeployTests.test("identity within a module") {
  let kp1: KeyPath<Destination, Int?> = \Destination.settings
  let kp2: KeyPath<Destination, Int?> = \Destination.settings
  expectEqual(kp1, kp2)
  expectEqual(kp1.hashValue, kp2.hashValue)
}

runAllTests()
