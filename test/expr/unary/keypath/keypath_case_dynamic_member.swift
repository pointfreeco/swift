// RUN: %target-typecheck-verify-swift -enable-experimental-feature CaseKeyPaths -disable-availability-checking
// REQUIRES: swift_feature_CaseKeyPaths

enum Destination {
  case settings(Int)
  case profile(name: String)
  case search(query: String, page: Int)
  case home
}

@dynamicMemberLookup
struct Cases<Root> {
  subscript<Value>(
    dynamicMember keyPath: CaseKeyPath<Root, Value>
  ) -> CaseKeyPath<Root, Value> {
    keyPath
  }
}

let paths = Cases<Destination>()

let kp1: CaseKeyPath<Destination, Int> = paths.settings
let kp2: CaseKeyPath<Destination, String> = paths.profile
let kp3: CaseKeyPath<Destination, (query: String, page: Int)> = paths.search
let kp4: CaseKeyPath<Destination, Void> = paths.home

func embeds() {
  let _: Destination = paths.settings(1)
  let _: Destination = paths.home()
}

// A dynamic member lookup with a `CaseKeyPath` parameter only resolves
// enum cases.
struct User { var name: String }
let userPaths = Cases<User>()
let bad1 = userPaths.name // expected-error {{case key path cannot refer to property 'name'}}

// Enum cases travel through a plain key path dynamic member lookup as the
// generalized `KeyPath<Root, Payload?>`.
@dynamicMemberLookup
struct Props<Root> {
  subscript<Value>(dynamicMember keyPath: KeyPath<Root, Value>) -> Value {
    fatalError()
  }
}
let props = Props<Destination>()
let generalized: Int? = props.settings
let explicitly: Int? = props[dynamicMember: \Destination.settings]

// A same-named member still wins an unannotated dynamic member.
enum Colliding {
  case value(Int)
  var value: Bool { true }
}
func collidingDML(_ p: Props<Colliding>) {
  let inferred = p.value
  let _: Bool = inferred
}

// Both subscript flavors can coexist; the `CaseKeyPath` subscript is more
// specialized and wins an unannotated case reference.
@dynamicMemberLookup
struct Both<Root> {
  subscript<Value>(dynamicMember keyPath: KeyPath<Root, Value>) -> Value {
    fatalError()
  }
  subscript<Value>(
    dynamicMember keyPath: CaseKeyPath<Root, Value>
  ) -> CaseKeyPath<Root, Value> {
    keyPath
  }
}
enum State {
  case count(Int)
}
let both = Both<State>()
let viaCase = both.count
let inferredAsCase: CaseKeyPath<State, Int> = viaCase

// When a string-based subscript coexists with a key-path subscript, a case
// resolves through the key-path subscript just like a property would; the
// string overload remains reachable with a contextual type.
@dynamicMemberLookup
struct Hybrid<Root> {
  subscript(dynamicMember member: String) -> String { member }
  subscript<Value>(dynamicMember keyPath: KeyPath<Root, Value>) -> Value {
    fatalError()
  }
}

func hybridDML(_ h: Hybrid<State>) {
  let inferred = h.count
  let _: Int? = inferred
  let _: String = h.count
}

@dynamicMemberLookup
struct HybridCase<Root> {
  subscript(dynamicMember member: String) -> String { member }
  subscript<Value>(
    dynamicMember keyPath: CaseKeyPath<Root, Value>
  ) -> Value? {
    nil
  }
}

func hybridCaseDML(_ h: HybridCase<State>) {
  let inferred = h.count
  let _: Int? = inferred
  let _: String = h.count
}

// A same-named member still wins the collision through a hybrid lookup.
enum CollidingState {
  case flag(Int)
  var flag: Bool { true }
}

func hybridCollisionDML(_ h: Hybrid<CollidingState>) {
  let inferred = h.flag
  let _: Bool = inferred
}

// Only a member that could form the competing key path counts as a
// collision; static members and inapplicable conditional extensions do not.
enum Boxed<T> {
  case value(T)
}

extension Boxed {
  static var value: Bool { true }
}

extension Boxed where T == Int {
  var value: Bool { true }
}

func viability(_ s: Hybrid<Boxed<String>>, _ i: Hybrid<Boxed<Int>>) {
  let viaCase = s.value
  let _: String? = viaCase
  let viaMember = i.value
  let _: Bool = viaMember
}

// Through a wrapper that also declares a `CaseKeyPath` subscript, the more
// specialized subscript wins the collision; context selects the member.
enum CollidingValue {
  case value(Int)
  var value: Bool { true }
}

func bothCollision(_ b: Both<CollidingValue>) {
  let viaCase = b.value
  let _: CaseKeyPath<CollidingValue, Int> = viaCase
  let _: Bool = b.value
}

// An enum can look up its own cases through a `CaseKeyPath`-based dynamic
// member lookup.
@dynamicMemberLookup
enum SelfLookup {
  case about
  case counter(Int)

  subscript<Value>(
    dynamicMember keyPath: CaseKeyPath<Self, Value>
  ) -> Value? {
    self[keyPath: keyPath]
  }
}

func selfLookup(_ e: SelfLookup) {
  let _: Int? = e.counter
  let _: Void? = e.about
  _ = e.missing // expected-error {{value of type 'SelfLookup' has no dynamic member 'missing' using key path from root type 'SelfLookup'}}
}
