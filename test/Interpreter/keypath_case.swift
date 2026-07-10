// RUN: %target-run-simple-swift(-enable-experimental-feature CaseKeyPaths -disable-availability-checking)
// REQUIRES: executable_test
// REQUIRES: swift_feature_CaseKeyPaths

import StdlibUnittest

enum Destination: Equatable {
  case settings(Int)
  case profile(name: String)
  case search(query: String, page: Int)
  case home
}

indirect enum Tree: Equatable {
  case leaf(Int)
  case branch(Tree, Tree)
}

enum Loadable<Value: Equatable>: Equatable {
  case loading
  case loaded(Value)
}

var CaseKeyPathTests = TestSuite("CaseKeyPaths")

CaseKeyPathTests.test("read/single payload") {
  let kp: CaseKeyPath<Destination, Int> = \Destination.settings
  expectEqual(42, Destination.settings(42)[keyPath: kp])
  expectNil(Destination.home[keyPath: kp])
  expectNil(Destination.profile(name: "blob")[keyPath: kp])
}

CaseKeyPathTests.test("read/labeled single payload") {
  let kp: CaseKeyPath<Destination, String> = \Destination.profile
  expectEqual("blob", Destination.profile(name: "blob")[keyPath: kp])
  expectNil(Destination.settings(1)[keyPath: kp])
}

CaseKeyPathTests.test("read/multiple payloads") {
  let kp: CaseKeyPath<Destination, (query: String, page: Int)> =
    \Destination.search
  let values = Destination.search(query: "cats", page: 3)[keyPath: kp]
  expectEqual("cats", values?.query)
  expectEqual(3, values?.page)
  expectNil(Destination.home[keyPath: kp])
}

CaseKeyPathTests.test("read/no payload") {
  let kp: CaseKeyPath<Destination, Void> = \Destination.home
  expectNotNil(Destination.home[keyPath: kp])
  expectNil(Destination.settings(1)[keyPath: kp])
}

CaseKeyPathTests.test("read/as supertype key path") {
  let kp: KeyPath<Destination, Int?> = \Destination.settings
  expectEqual(42, Destination.settings(42)[keyPath: kp])
  expectNil(Destination.home[keyPath: kp])

  let partial: PartialKeyPath<Destination> = \Destination.settings
  expectEqual(42, Destination.settings(42)[keyPath: partial] as? Int)
}

CaseKeyPathTests.test("embed/single payload") {
  let kp: CaseKeyPath<Destination, Int> = \Destination.settings
  expectEqual(Destination.settings(42), kp(42))
}

CaseKeyPathTests.test("embed/labeled single payload") {
  let kp: CaseKeyPath<Destination, String> = \Destination.profile
  expectEqual(Destination.profile(name: "blob"), kp("blob"))
}

CaseKeyPathTests.test("embed/multiple payloads") {
  let kp: CaseKeyPath<Destination, (query: String, page: Int)> =
    \Destination.search
  expectEqual(Destination.search(query: "cats", page: 3),
              kp((query: "cats", page: 3)))
}

CaseKeyPathTests.test("embed/no payload") {
  let kp: CaseKeyPath<Destination, Void> = \Destination.home
  expectEqual(Destination.home, kp())
}

CaseKeyPathTests.test("indirect enum") {
  let kp: CaseKeyPath<Tree, Int> = \Tree.leaf
  expectEqual(1, Tree.leaf(1)[keyPath: kp])
  expectNil(Tree.branch(.leaf(1), .leaf(2))[keyPath: kp])
  expectEqual(Tree.leaf(9), kp(9))

  let branch: CaseKeyPath<Tree, (Tree, Tree)> = \Tree.branch
  let subtrees = Tree.branch(.leaf(1), .leaf(2))[keyPath: branch]
  expectEqual(Tree.leaf(1), subtrees?.0)
  expectEqual(Tree.leaf(2), subtrees?.1)
  expectEqual(
    Tree.branch(.leaf(1), .leaf(2)), branch((.leaf(1), .leaf(2))))
}

CaseKeyPathTests.test("generic enum") {
  let kp: CaseKeyPath<Loadable<Int>, Int> = \Loadable<Int>.loaded
  expectEqual(42, Loadable.loaded(42)[keyPath: kp])
  expectNil(Loadable<Int>.loading[keyPath: kp])
  expectEqual(Loadable.loaded(42), kp(42))
}

CaseKeyPathTests.test("chaining through a case") {
  let kp: KeyPath<Destination, Int?> = \Destination.profile?.count
  expectEqual(4, Destination.profile(name: "blob")[keyPath: kp])
  expectNil(Destination.home[keyPath: kp])
}

enum App: Equatable {
  case screen(Screen)
  case alert(String)
}
enum Screen: Equatable {
  case detail(Detail)
  case list
}
enum Detail: Equatable {
  case item(Int)
  case empty
}

CaseKeyPathTests.test("appending/read") {
  let screenDetail: CaseKeyPath<App, Detail> =
    (\App.screen).appending(path: \Screen.detail)
  expectEqual(.item(1), App.screen(.detail(.item(1)))[keyPath: screenDetail])
  expectNil(App.screen(.list)[keyPath: screenDetail])
  expectNil(App.alert("!")[keyPath: screenDetail])
}

CaseKeyPathTests.test("appending/embed") {
  let screenDetail: CaseKeyPath<App, Detail> =
    (\App.screen).appending(path: \Screen.detail)
  expectEqual(App.screen(.detail(.empty)), screenDetail(.empty))
}

CaseKeyPathTests.test("appending/three levels") {
  let deep: CaseKeyPath<App, Int> = (\App.screen)
    .appending(path: \Screen.detail)
    .appending(path: \Detail.item)
  expectEqual(42, App.screen(.detail(.item(42)))[keyPath: deep])
  expectNil(App.screen(.detail(.empty))[keyPath: deep])
  expectNil(App.screen(.list)[keyPath: deep])
  expectNil(App.alert("!")[keyPath: deep])
  expectEqual(App.screen(.detail(.item(7))), deep(7))
}

CaseKeyPathTests.test("appending/as supertype key path") {
  let deep: CaseKeyPath<App, Int> = (\App.screen)
    .appending(path: \Screen.detail)
    .appending(path: \Detail.item)
  let up: KeyPath<App, Int?> = deep
  expectEqual(9, App.screen(.detail(.item(9)))[keyPath: up])
}

CaseKeyPathTests.test("appending/identity") {
  let a: CaseKeyPath<App, Detail> =
    (\App.screen).appending(path: \Screen.detail)
  let b: CaseKeyPath<App, Detail> =
    (\App.screen).appending(path: \Screen.detail)
  expectEqual(a, b)
  expectEqual(a.hashValue, b.hashValue)
  let other: CaseKeyPath<App, Screen> = \App.screen
  expectNotEqual(other as AnyKeyPath, a as AnyKeyPath)
}

CaseKeyPathTests.test("composed literal/read and embed") {
  let deep: CaseKeyPath<App, Int> = \App.screen?.detail?.item
  expectEqual(42, App.screen(.detail(.item(42)))[keyPath: deep])
  expectNil(App.screen(.detail(.empty))[keyPath: deep])
  expectNil(App.screen(.list)[keyPath: deep])
  expectNil(App.alert("!")[keyPath: deep])
  expectEqual(App.screen(.detail(.item(7))), deep(7))
}

CaseKeyPathTests.test("composed literal/identity with appending") {
  let literal: CaseKeyPath<App, Int> = \App.screen?.detail?.item
  let appended: CaseKeyPath<App, Int> = (\App.screen)
    .appending(path: \Screen.detail)
    .appending(path: \Detail.item)
  expectEqual(literal as AnyKeyPath, appended as AnyKeyPath)
  expectEqual(literal.hashValue, appended.hashValue)
}

CaseKeyPathTests.test("composed literal/.some composes like appending") {
  let literal: CaseKeyPath<Detail?, Int> = \Detail?.some?.item
  let appended: CaseKeyPath<Detail?, Int> =
    (\Detail?.some).appending(path: \Detail.item)
  expectEqual(literal as AnyKeyPath, appended as AnyKeyPath)
  expectEqual(3, (Detail.item(3) as Detail?)[keyPath: literal])
  expectEqual(Detail.item(4), literal(4))
}

CaseKeyPathTests.test("appending a chained key path matches the literal") {
  let appended: KeyPath<Destination, Int?> =
    (\Destination.profile).appending(path: \.?.count)
  let literal: KeyPath<Destination, Int?> = \Destination.profile?.count
  expectEqual(literal, appended)
  expectEqual(literal.hashValue, appended.hashValue)
  expectEqual(4, Destination.profile(name: "blob")[keyPath: appended])
  expectNil(Destination.home[keyPath: appended])
}

// Assert which subscript runs, not just which type is inferred.
var lastSubscript = ""

@dynamicMemberLookup
struct Marked<Root> {
  let root: Root
  subscript(dynamicMember member: String) -> String {
    lastSubscript = "string"
    return member
  }
  subscript<V>(dynamicMember keyPath: KeyPath<Root, V>) -> V {
    lastSubscript = "keyPath"
    return root[keyPath: keyPath]
  }
  subscript<V>(dynamicMember keyPath: CaseKeyPath<Root, V>) -> V? {
    lastSubscript = "caseKeyPath"
    return root[keyPath: keyPath]
  }
}

enum Ranked: Equatable {
  case only(Int)
  case picked(Int)

  var name: String { "ranked" }
  var picked: Bool {
    if case .picked = self { return true }
    return false
  }
}

CaseKeyPathTests.test("ranking markers") {
  let m = Marked(root: Ranked.only(7))

  // A case with no same-named member resolves through the CaseKeyPath
  // subscript.
  expectEqual(7, m.only)
  expectEqual("caseKeyPath", lastSubscript)

  // A member resolves through the key-path subscript, not the string
  // fallback, even though both produce a String.
  let name = m.name
  expectEqual("ranked", name)
  expectEqual("keyPath", lastSubscript)

  // A name that is neither a case nor a member falls back to the string
  // subscript.
  let missing: String = m.missing
  expectEqual("missing", missing)
  expectEqual("string", lastSubscript)

  // A colliding name resolves to the case through the more specialized
  // CaseKeyPath subscript; context selects the member or the string form.
  expectNil(m.picked)
  expectEqual("caseKeyPath", lastSubscript)
  let asMember: Bool = m.picked
  expectFalse(asMember)
  expectEqual("keyPath", lastSubscript)
  let asString: String = m.picked
  expectEqual("picked", asString)
  expectEqual("string", lastSubscript)
}

enum Wrapped: Equatable {
  case labeledTuple(payload: (Int, String))
  case unlabeledTuple((Int, String))
  case none

  static func == (lhs: Wrapped, rhs: Wrapped) -> Bool {
    switch (lhs, rhs) {
    case let (.labeledTuple(l), .labeledTuple(r)): return l == r
    case let (.unlabeledTuple(l), .unlabeledTuple(r)): return l == r
    case (.none, .none): return true
    default: return false
    }
  }
}

CaseKeyPathTests.test("labeled tuple payload") {
  let kp: CaseKeyPath<Wrapped, (Int, String)> = \Wrapped.labeledTuple
  let values = Wrapped.labeledTuple(payload: (1, "x"))[keyPath: kp]
  expectEqual(1, values?.0)
  expectEqual("x", values?.1)
  expectNil(Wrapped.none[keyPath: kp])
  expectEqual(Wrapped.labeledTuple(payload: (2, "y")), kp((2, "y")))
}

CaseKeyPathTests.test("unlabeled tuple payload") {
  let kp: CaseKeyPath<Wrapped, (Int, String)> = \Wrapped.unlabeledTuple
  let values = Wrapped.unlabeledTuple((1, "x"))[keyPath: kp]
  expectEqual(1, values?.0)
  expectEqual("x", values?.1)
  expectNil(Wrapped.none[keyPath: kp])
  expectEqual(Wrapped.unlabeledTuple((2, "y")), kp((2, "y")))
}

CaseKeyPathTests.test("identity and hashing") {
  let kp1: CaseKeyPath<Destination, Int> = \Destination.settings
  let kp2: CaseKeyPath<Destination, Int> = \Destination.settings
  expectEqual(kp1, kp2)
  expectEqual(kp1.hashValue, kp2.hashValue)
  let other: AnyKeyPath = \Destination.profile
  expectNotEqual(other, kp1 as AnyKeyPath)
}

enum Pair: Equatable {
  case first(Int)
  case second(Int)
}

CaseKeyPathTests.test("identity distinguishes same-typed cases") {
  // Both paths are `CaseKeyPath<Pair, Int>`; only the tag tells them apart.
  let first: CaseKeyPath<Pair, Int> = \Pair.first
  let second: CaseKeyPath<Pair, Int> = \Pair.second
  expectNotEqual(first, second)
}

enum Box<T>: Equatable where T: Equatable {
  case value(T)
  case empty
}

func genericValuePath<T: Equatable>(_: T.Type) -> CaseKeyPath<Box<T>, T> {
  \Box<T>.value
}

CaseKeyPathTests.test("identity of generic enum cases") {
  // A concrete literal and a generic instantiation come from distinct
  // patterns, so this compares structurally rather than by object identity.
  let concrete: CaseKeyPath<Box<Int>, Int> = \Box<Int>.value
  let generic = genericValuePath(Int.self)
  expectFalse(concrete === generic)
  expectEqual(concrete, generic)
  expectEqual(concrete.hashValue, generic.hashValue)

  // Substitutions are part of identity.
  expectNotEqual(genericValuePath(String.self) as AnyKeyPath,
                 concrete as AnyKeyPath)
  expectEqual(42, Box<Int>.value(42)[keyPath: concrete])
  expectEqual(Box<Int>.value(1), generic(1))
}

@dynamicMemberLookup
struct Cases<Root> {
  subscript<Value>(
    dynamicMember keyPath: CaseKeyPath<Root, Value>
  ) -> CaseKeyPath<Root, Value> {
    keyPath
  }
}

CaseKeyPathTests.test("dynamic member lookup/read") {
  let paths = Cases<Destination>()
  expectEqual(42, Destination.settings(42)[keyPath: paths.settings])
  expectNil(Destination.home[keyPath: paths.settings])
  expectEqual("blob", Destination.profile(name: "blob")[keyPath: paths.profile])
  let values = Destination.search(query: "cats", page: 3)[keyPath: paths.search]
  expectEqual("cats", values?.query)
  expectEqual(3, values?.page)
  expectNotNil(Destination.home[keyPath: paths.home])
}

CaseKeyPathTests.test("dynamic member lookup/embed") {
  let paths = Cases<Destination>()
  expectEqual(Destination.settings(1), paths.settings(1))
  expectEqual(Destination.profile(name: "blob"), paths.profile("blob"))
  expectEqual(Destination.search(query: "q", page: 2),
              paths.search((query: "q", page: 2)))
  expectEqual(Destination.home, paths.home())
}

CaseKeyPathTests.test("dynamic member lookup/identity") {
  let paths = Cases<Destination>()
  let direct: CaseKeyPath<Destination, Int> = \Destination.settings
  expectEqual(direct, paths.settings)
  expectEqual(direct.hashValue, paths.settings.hashValue)
}

@dynamicMemberLookup
enum SelfLookup: Equatable {
  case about
  case counter(Int)

  subscript<Value>(
    dynamicMember keyPath: CaseKeyPath<Self, Value>
  ) -> Value? {
    self[keyPath: keyPath]
  }
}

@dynamicMemberLookup
struct Projected<Root> {
  var root: Root
  subscript<Value>(dynamicMember keyPath: KeyPath<Root, Value>) -> Value {
    root[keyPath: keyPath]
  }
}

CaseKeyPathTests.test("dynamic member lookup/plain key path") {
  // Cases travel through a plain `KeyPath` subscript as `Payload?`.
  let p = Projected(root: Destination.settings(42))
  expectEqual(42, p.settings)
  expectNil(p.profile)
  expectEqual(42, p[dynamicMember: \Destination.settings])
}

CaseKeyPathTests.test("dynamic member lookup/self") {
  let e = SelfLookup.counter(42)
  expectEqual(42, e.counter)
  expectNil(e.about)
  expectNotNil(SelfLookup.about.about)
}

struct Payload {
  var value: Int
}

CaseKeyPathTests.test("Optional.some canonicalizes when chained") {
  let viaCase: KeyPath<Payload?, Int?> = \Payload?.some?.value
  let viaChain: KeyPath<Payload?, Int?> = \Payload?.?.value
  expectEqual(viaChain, viaCase)
  expectEqual(viaChain.hashValue, viaCase.hashValue)
  expectEqual(3, Payload(value: 3)[keyPath: viaCase])

  let forcedCase: KeyPath<Payload?, Int> = \Payload?.some!.value
  let forcedChain: KeyPath<Payload?, Int> = \Payload?.!.value
  expectEqual(forcedChain, forcedCase)
}

CaseKeyPathTests.test("debugDescription names the case") {
  expectEqual("\\Destination.settings",
              String(reflecting: \Destination.settings))
  expectEqual("\\Destination.home", String(reflecting: \Destination.home))
  expectEqual("\\Optional<String>.some", String(reflecting: \String?.some))
}

struct Zero: Equatable {}

enum LayoutEmpty: Equatable {
  case empty(Zero)
  case integer(Int)
  case none
}

CaseKeyPathTests.test("tags of layout-empty payload cases") {
  // Layout classifies a zero-sized payload as no-payload; tags and names
  // must agree with the runtime's ordering regardless.
  expectEqual("\\LayoutEmpty.empty", String(reflecting: \LayoutEmpty.empty))
  expectEqual("\\LayoutEmpty.integer",
              String(reflecting: \LayoutEmpty.integer))
  expectEqual("\\LayoutEmpty.none", String(reflecting: \LayoutEmpty.none))
  expectEqual(7, LayoutEmpty.integer(7)[keyPath: \LayoutEmpty.integer])
  expectNotNil(LayoutEmpty.empty(Zero())[keyPath: \LayoutEmpty.empty])
  expectNotEqual(\LayoutEmpty.empty as AnyKeyPath,
                 \LayoutEmpty.none as AnyKeyPath)
}

runAllTests()
