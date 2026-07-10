// RUN: %batch-code-completion -enable-experimental-feature CaseKeyPaths
// REQUIRES: swift_feature_CaseKeyPaths

enum Destination {
  case about
  case counter(Int)
  case search(query: String, page: Int)
}

@dynamicMemberLookup
struct Cases<Root> {
  subscript<V>(dynamicMember keyPath: CaseKeyPath<Root, V>) -> V? { nil }
}

func caseDML(_ c: Cases<Destination>) {
  c.#^CASE_DML^#
}
// CASE_DML: Decl[EnumElement]/CurrNominal: about[#()?#]; name=about
// CASE_DML: Decl[EnumElement]/CurrNominal: counter[#Int?#]; name=counter
// CASE_DML: Decl[EnumElement]/CurrNominal: search[#(query: String, page: Int)?#]; name=search

@dynamicMemberLookup
enum SelfLookup {
  case about
  case counter(Int)

  subscript<V>(dynamicMember keyPath: CaseKeyPath<Self, V>) -> V? {
    self[keyPath: keyPath]
  }
}

func selfDML(_ e: SelfLookup) {
  e.#^SELF_DML^#
}
// SELF_DML: Decl[EnumElement]/CurrNominal: about[#()?#]; name=about
// SELF_DML: Decl[EnumElement]/CurrNominal: counter[#Int?#]; name=counter

func embed(_ kp: CaseKeyPath<Destination, Int>) {
  kp#^EMBED^#
}
// EMBED: Decl[InstanceMethod]/CurrNominal{{.*}}: .callAsFunction({#(value): Int#})[#Destination#]; name=callAsFunction(:)

// A plain key path dynamic member lookup surfaces the root's storage.
struct User { var name: String }
@dynamicMemberLookup
struct Props<Root> {
  subscript<V>(dynamicMember keyPath: KeyPath<Root, V>) -> V { fatalError() }
}

func propDML(_ p: Props<User>) {
  p.#^PROP_DML^#
}
// PROP_DML: Decl[InstanceVar]/CurrNominal: name[#String#]; name=name

// Cases also travel through a plain key path lookup, `Optional`-wrapped.
func plainDML(_ p: Props<Destination>) {
  p.#^PLAIN_ENUM_DML^#
}
// PLAIN_ENUM_DML: Decl[EnumElement]/CurrNominal: about[#()?#]; name=about
// PLAIN_ENUM_DML: Decl[EnumElement]/CurrNominal: counter[#Int?#]; name=counter

// When both subscript flavors coexist, results match overload ranking
// regardless of declaration order: cases resolve through the `CaseKeyPath`
// subscript, winning collisions; members win names that are not cases.
enum Mixed {
  case label(Int)
  case counter(Int)
  var label: String { "" }
}

@dynamicMemberLookup
struct Both1<Root> {
  subscript<V>(dynamicMember keyPath: KeyPath<Root, V>) -> V { fatalError() }
  subscript<V>(dynamicMember keyPath: CaseKeyPath<Root, V>) -> CaseKeyPath<Root, V> { keyPath }
}

@dynamicMemberLookup
struct Both2<Root> {
  subscript<V>(dynamicMember keyPath: CaseKeyPath<Root, V>) -> CaseKeyPath<Root, V> { keyPath }
  subscript<V>(dynamicMember keyPath: KeyPath<Root, V>) -> V { fatalError() }
}

func bothDML1(_ b: Both1<Mixed>) {
  b.#^BOTH1^#
}
// BOTH1-DAG: Decl[EnumElement]/CurrNominal: label[#CaseKeyPath<Mixed, Int>#]; name=label
// BOTH1-DAG: Decl[EnumElement]/CurrNominal: counter[#CaseKeyPath<Mixed, Int>#]; name=counter

func bothDML2(_ b: Both2<Mixed>) {
  b.#^BOTH2^#
}
// BOTH2-DAG: Decl[EnumElement]/CurrNominal: label[#CaseKeyPath<Mixed, Int>#]; name=label
// BOTH2-DAG: Decl[EnumElement]/CurrNominal: counter[#CaseKeyPath<Mixed, Int>#]; name=counter
