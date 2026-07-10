// RUN: %target-typecheck-verify-swift -enable-experimental-feature CaseKeyPaths -disable-availability-checking -verify-ignore-unrelated
// REQUIRES: swift_feature_CaseKeyPaths

enum Destination {
  case settings(Int)
  case profile(name: String)
  case search(query: String, page: Int)
  case home
}

indirect enum Tree {
  case leaf(Int)
  case branch(Tree, Tree)
}

// Single unlabeled associated value.
let kp1: CaseKeyPath<Destination, Int> = \Destination.settings

// Single labeled associated value: the label is dropped.
let kp2: CaseKeyPath<Destination, String> = \Destination.profile

// Multiple associated values project as a labeled tuple.
let kp3: CaseKeyPath<Destination, (query: String, page: Int)> =
  \Destination.search

// No associated values project as Void.
let kp4: CaseKeyPath<Destination, Void> = \Destination.home

// Indirect enums work too.
let kp5: CaseKeyPath<Tree, Int> = \Tree.leaf

// A CaseKeyPath is a KeyPath<Root, Value?>.
let up1: KeyPath<Destination, Int?> = \Destination.settings
let up2: PartialKeyPath<Destination> = \Destination.settings
let up3: AnyKeyPath = \Destination.settings

func reads(_ d: Destination) {
  let _: Int? = d[keyPath: kp1]
  let _: Int? = d[keyPath: \Destination.settings]
  let _: String? = d[keyPath: kp2]
  let _: (query: String, page: Int)? = d[keyPath: kp3]
  let _: Void? = d[keyPath: kp4]
}

func embeds() {
  let _: Destination = kp1(1)
  let _: Destination = kp2("blob")
  let _: Destination = kp3((query: "q", page: 2))
  let _: Destination = kp4()
}

// Chaining through a case requires optional chaining and produces a plain
// read-only key path.
let chained: KeyPath<Destination, Int?> = \Destination.profile?.count

// A literal composed entirely of cases stays a CaseKeyPath.
enum Outer {
  case inner(Destination)
  case none
}

let composed1: CaseKeyPath<Outer, Int> = \Outer.inner?.settings
let composed2: CaseKeyPath<Outer, Void> = \Outer.inner?.home
let composed3: CaseKeyPath<Outer?, Int> = \Outer?.some?.inner?.settings

// ...and upcasts like any other case key path.
let composedUp: KeyPath<Outer, Int?> = \Outer.inner?.settings

// Mixing in a property or force-unwrapping a payload decays to read-only.
let viaProperty: KeyPath<Outer, Int?> = \Outer.inner?.profile?.count
let viaForce: KeyPath<Outer, Int?> = \Outer.inner!.settings

let composedBad: CaseKeyPath<Outer, String> = \Outer.inner?.settings
// expected-error@-1 {{cannot assign value of type 'CaseKeyPath<Outer, Int>' to type 'CaseKeyPath<Outer, String>'}}
// expected-note@-2 {{arguments to generic parameter 'Value' ('Int' and 'String') are expected to be equal}}

// Case key paths are not writable.
func write(_ d: inout Destination) {
  d[keyPath: kp1] = 42 // expected-error {{cannot assign through subscript: 'd' is immutable}}
}

// Wrong payload types are rejected.
let bad1: CaseKeyPath<Destination, String> = \Destination.settings
// expected-error@-1 {{cannot assign value of type 'CaseKeyPath<Destination, Int>' to type 'CaseKeyPath<Destination, String>'}}
// expected-note@-2 {{arguments to generic parameter 'Value' ('Int' and 'String') are expected to be equal}}

func badEmbed() {
  _ = kp1("nope") // expected-error {{cannot convert value of type 'String' to expected argument type 'Int'}}

  // The payload is passed as a whole, not splatted.
  _ = kp3("q", 2) // expected-error {{instance method 'callAsFunction' expects a single parameter of type '(query: String, page: Int)'}}
}

// Compound names are unapplied references and are fine.
let compound1: CaseKeyPath<Destination, Int> = \Destination.settings(_:)
let compound2: CaseKeyPath<Destination, (query: String, page: Int)> =
  \Destination.search(query:page:)

// ...and disambiguate cases sharing a base name.
enum Overloaded {
  case foo(Int) // expected-note {{found this candidate}}
  case foo(label: String) // expected-note {{found this candidate}}
  case foo(a: Int, b: Int) // expected-note {{found this candidate}}
}

let overload1: CaseKeyPath<Overloaded, Int> = \Overloaded.foo(_:)
let overload2: CaseKeyPath<Overloaded, String> = \Overloaded.foo(label:)
let overload3: CaseKeyPath<Overloaded, (a: Int, b: Int)> =
  \Overloaded.foo(a:b:)

// A contextual type also selects among the bare-name candidates.
let overload4: CaseKeyPath<Overloaded, String> = \Overloaded.foo

let overload5 = \Overloaded.foo // expected-error {{ambiguous use of 'foo'}}

// Cases cannot be applied to arguments within a key path.
enum Defaulted {
  case about
  case counter(Int = 0)
}

let applied1 = \Defaulted.counter(1) // expected-error {{case key path cannot apply arguments to enum case 'counter'}} {{34-37=}}
let applied2 = \Defaulted.counter() // expected-error {{case key path cannot apply arguments to enum case 'counter'}} {{34-36=}}
let applied3 = \Defaulted.about() // expected-error {{case key path cannot apply arguments to enum case 'about'}} {{32-34=}}
let applied4 = \Destination.search(query: "q", page: 1) // expected-error {{case key path cannot apply arguments to enum case 'search(query:page:)'}} {{35-56=}}

func appliedInFunction() {
  let _ = \Defaulted.counter(1) // expected-error {{case key path cannot apply arguments to enum case 'counter'}} {{29-32=}}
}

// ...including mid-chain.
enum Wrapper {
  case inner(Defaulted)
}
let applied5 = \Wrapper.inner?.counter(1) // expected-error {{case key path cannot apply arguments to enum case 'counter'}} {{39-42=}}

// Extraction operates on enum values, so metatype roots are rejected.
let meta1 = \Destination.Type.settings // expected-error {{key path cannot refer to enum case 'settings' on metatype 'Destination.Type'}}
let meta2 = \Destination.Type.home // expected-error {{key path cannot refer to enum case 'home' on metatype 'Destination.Type'}}

// A same-named member wins an unannotated reference; the contextual type
// selects the case.
enum Colliding {
  case value(Int)
  var value: Bool { true }
}

let inferred = \Colliding.value
let asProperty: KeyPath<Colliding, Bool> = inferred
let asCase: CaseKeyPath<Colliding, Int> = \Colliding.value
