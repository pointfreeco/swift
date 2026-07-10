// RUN: %target-run-simple-swift(   -enable-experimental-feature Embedded -enable-experimental-feature EmbeddedKeyPaths -enable-experimental-feature CaseKeyPaths -disable-availability-checking -wmo -runtime-compatibility-version none %target-embedded-posix-shim) | %FileCheck %s
// RUN: %target-run-simple-swift(-O -enable-experimental-feature Embedded -enable-experimental-feature EmbeddedKeyPaths -enable-experimental-feature CaseKeyPaths -disable-availability-checking -wmo -runtime-compatibility-version none %target-embedded-posix-shim) | %FileCheck %s

// REQUIRES: executable_test
// REQUIRES: optimized_stdlib
// REQUIRES: swift_feature_Embedded
// REQUIRES: swift_feature_EmbeddedKeyPaths
// REQUIRES: swift_feature_CaseKeyPaths

enum Destination {
  case settings(Int)
  case profile(name: Int)
  case home
}

// Extraction through a statically instantiated case key path.
func extract(_ d: Destination) -> Int? {
  d[keyPath: \Destination.settings]
}

print(extract(.settings(42)) == 42 ? "OK!" : "FAIL") // CHECK: OK!
print(extract(.home) == nil ? "OK!" : "FAIL") // CHECK: OK!

// Embedding.
func embed(_ x: Int) -> Destination {
  (\Destination.settings)(x)
}

print(extract(embed(7)) == 7 ? "OK!" : "FAIL") // CHECK: OK!

// Identity is keyed on the case's tag.
func samePathsEqual() -> Bool {
  let a: CaseKeyPath<Destination, Int> = \Destination.settings
  let b: CaseKeyPath<Destination, Int> = \Destination.settings
  return a == b && a.hashValue == b.hashValue
}

print(samePathsEqual() ? "OK!" : "FAIL") // CHECK: OK!

func differentCasesDiffer() -> Bool {
  let a: CaseKeyPath<Destination, Int> = \Destination.settings
  let b: CaseKeyPath<Destination, Int> = \Destination.profile
  return a != b
}

print(differentCasesDiffer() ? "OK!" : "FAIL") // CHECK: OK!

// Payloadless cases project `Void?` and embed with no arguments.
func payloadless() -> Bool {
  let kp: CaseKeyPath<Destination, Void> = \Destination.home
  guard case .home = kp() else { return false }
  return Destination.home[keyPath: kp] != nil
    && Destination.settings(1)[keyPath: kp] == nil
}

print(payloadless() ? "OK!" : "FAIL") // CHECK: OK!

// Chaining past a case into a property decays to a plain read-only key
// path; a directly applied literal folds to direct projections.
struct Profile { var age: Int }
enum User {
  case member(Profile)
  case guest
}

func extractChained(_ u: User) -> Int? {
  u[keyPath: \User.member?.age]
}

print(extractChained(.member(Profile(age: 29))) == 29 ? "OK!" : "FAIL") // CHECK: OK!
print(extractChained(.guest) == nil ? "OK!" : "FAIL") // CHECK: OK!

// A composed case literal is a CaseKeyPath; its direct application folds
// the same way. (Materializing one is a compile-time error in Embedded,
// like any chained key path.)
enum Session {
  case user(User)
  case anonymous
}

func extractComposed(_ s: Session) -> Profile? {
  s[keyPath: \Session.user?.member]
}

func embedComposed() -> Bool {
  let session = (\Session.user?.member)(Profile(age: 3))
  guard case .user(.member(let profile)) = session else { return false }
  return profile.age == 3
}

print(extractComposed(.user(.member(Profile(age: 1))))?.age == 1 ? "OK!" : "FAIL") // CHECK: OK!
print(extractComposed(.user(.guest)) == nil ? "OK!" : "FAIL") // CHECK: OK!
print(extractComposed(.anonymous) == nil ? "OK!" : "FAIL") // CHECK: OK!
print(embedComposed() ? "OK!" : "FAIL") // CHECK: OK!
