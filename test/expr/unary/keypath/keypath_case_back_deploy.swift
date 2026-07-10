// RUN: %target-typecheck-verify-swift -enable-experimental-feature CaseKeyPaths
// REQUIRES: swift_feature_CaseKeyPaths
// REQUIRES: OS=macosx

// Without runtime support at the deployment target, a case literal is a
// plain read-only key path and `CaseKeyPath` itself is unavailable.

enum Destination {
  case settings(Int)
  case profile(name: String)
  case home
}

let kp1: KeyPath<Destination, Int?> = \Destination.settings
let kp2: PartialKeyPath<Destination> = \Destination.settings
let kp3: AnyKeyPath = \Destination.home
let chained: KeyPath<Destination, Int?> = \Destination.profile?.count

// A composed case literal decays to the back-deployed form as well.
enum Outer {
  case inner(Destination)
}
let composed: KeyPath<Outer, Int?> = \Outer.inner?.settings

// Cases resolve through a plain key path dynamic member lookup as the
// back-deployed `KeyPath<Enum, Payload?>`.
@dynamicMemberLookup
struct Props<Root> {
  subscript<Value>(dynamicMember keyPath: KeyPath<Root, Value>) -> Value {
    fatalError()
  }
}

func plainDML(_ p: Props<Destination>) {
  let inferred = p.settings
  let _: Int? = inferred
}

// The inferred type is the plain key path as well.
let inferred = \Destination.settings
let reannotated: KeyPath<Destination, Int?> = inferred

// Embedding requires the `CaseKeyPath` runtime support.
func embeds() {
  let kp = \Destination.settings
  _ = kp(1) // expected-error {{cannot call value of non-function type 'KeyPath<Destination, Int?>'}}
}

let annotated: CaseKeyPath<Destination, Int> = \Destination.settings
// expected-error@-1 {{'CaseKeyPath' is only available in macOS 9999 or newer}}
// expected-error@-2 {{cannot convert key path type 'KeyPath<Destination, Int?>' to contextual type 'CaseKeyPath<Destination, Int>'}}
// expected-note@-3 {{add 'if #available' version check}}
