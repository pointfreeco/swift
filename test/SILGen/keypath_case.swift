// RUN: %target-swift-emit-silgen -enable-experimental-feature CaseKeyPaths -disable-availability-checking %s | %FileCheck %s
// REQUIRES: swift_feature_CaseKeyPaths

enum E {
  case one(Int)
  case two(Int, String)
  case wrapped(payload: (Int, String))
  case zero
}

// A single labeled associated value of tuple type is stored wrapped in a
// one-element labeled tuple, and the extract thunk projects it back out.
// CHECK-LABEL: sil hidden [ossa] @$s12keypath_case9wrappedKPs11CaseKeyPathCyAA1EOSi_SStGyF
func wrappedKP() -> CaseKeyPath<E, (Int, String)> {
  // CHECK: keypath $CaseKeyPath<E, (Int, String)>, (root $E; enum_case $Optional<(Int, String)>, id #E.wrapped!enumelt : {{.*}}, extract @{{.*}} embed @{{.*}})
  return \E.wrapped
}

// CHECK-LABEL: sil hidden [ossa] @$s12keypath_case8singleKPs11CaseKeyPathCyAA1EOSiGyF
func singleKP() -> CaseKeyPath<E, Int> {
  // CHECK: keypath $CaseKeyPath<E, Int>, (root $E; enum_case $Optional<Int>, id #E.one!enumelt : {{.*}}, extract @$s12keypath_case1EO3oneyACSicACmFACTK : $@convention(keypath_accessor_getter) (@in_guaranteed E) -> @out Optional<Int>, embed @$s12keypath_case1EO3oneyACSicACmFACTk : $@convention(keypath_accessor_getter) (@in_guaranteed Int) -> @out E)
  return \E.one
}

// The extract thunk switches over the enum.
// CHECK-LABEL: sil shared [thunk] [ossa] @$s12keypath_case1EO3oneyACSicACmFACTK
// CHECK: switch_enum {{%[0-9]+}}, case #E.one!enumelt: {{bb[0-9]+}}, default {{bb[0-9]+}}

// The embed thunk constructs the enum from the payload.
// CHECK-LABEL: sil shared [thunk] [ossa] @$s12keypath_case1EO3oneyACSicACmFACTk
// CHECK: enum $E, #E.one!enumelt, {{%[0-9]+}}

// CHECK-LABEL: sil hidden [ossa] @$s12keypath_case7tupleKPs11CaseKeyPathCyAA1EOSi_SStGyF
func tupleKP() -> CaseKeyPath<E, (Int, String)> {
  // CHECK: keypath $CaseKeyPath<E, (Int, String)>, (root $E; enum_case $Optional<(Int, String)>, id #E.two!enumelt : {{.*}}, extract @{{.*}} (@in_guaranteed E) -> @out Optional<(Int, String)>, embed @{{.*}} (@in_guaranteed (Int, String)) -> @out E)
  return \E.two
}

// CHECK-LABEL: sil hidden [ossa] @$s12keypath_case6voidKPs11CaseKeyPathCyAA1EOytGyF
func voidKP() -> CaseKeyPath<E, Void> {
  // CHECK: keypath $CaseKeyPath<E, ()>, (root $E; enum_case $Optional<()>, id #E.zero!enumelt : {{.*}}, extract @{{.*}} (@in_guaranteed E) -> @out Optional<()>, embed @{{.*}} (@in_guaranteed ()) -> @out E)
  return \E.zero
}

// Reading through a case key path upcasts to KeyPath and projects a read.
// CHECK-LABEL: sil hidden [ossa] @$s12keypath_case4readySiSgAA1EOF
func read(_ e: E) -> Int? {
  // CHECK: upcast {{%[0-9]+}} to $KeyPath<E, Optional<Int>>
  // CHECK: function_ref @swift_getAtKeyPath
  return e[keyPath: \E.one]
}

// A literal composed entirely of cases emits case components alternating
// with optional chains, with no trailing optional wrap — the same shape
// `appending(path:)` builds.
enum Outer {
  case inner(E)
}

// CHECK-LABEL: sil hidden [ossa] @$s12keypath_case10composedKPs11CaseKeyPathCyAA5OuterOSiGyF
func composedKP() -> CaseKeyPath<Outer, Int> {
  // CHECK: keypath $CaseKeyPath<Outer, Int>, (root $Outer; enum_case $Optional<E>, id #Outer.inner!enumelt : {{.*}}; optional_chain : $E; enum_case $Optional<Int>, id #E.one!enumelt : {{.*}})
  return \Outer.inner?.one
}

// A `.some` component is preserved in a CaseKeyPath, matching the
// components `appending(path:)` builds.
// CHECK-LABEL: sil hidden [ossa] @$s12keypath_case6someKPs11CaseKeyPathCyAA1EOSgSiGyF
func someKP() -> CaseKeyPath<E?, Int> {
  // CHECK: keypath $CaseKeyPath<Optional<E>, Int>, (root $Optional<E>; enum_case $Optional<E>, id #Optional.some!enumelt : {{.*}}; optional_chain : $E; enum_case $Optional<Int>, id #E.one!enumelt : {{.*}})
  return \E?.some?.one
}

// Chaining into a non-case member decays to a plain key path, and the
// `.some` component canonicalizes away.
// CHECK-LABEL: sil hidden [ossa] @$s12keypath_case9decayedKPs7KeyPathCyAA1EOSgSiSgGyF
func decayedKP() -> KeyPath<E?, Int?> {
  // CHECK: keypath $KeyPath<Optional<E>, Optional<Int>>, (root $Optional<E>; optional_chain : $E; enum_case $Optional<Int>, id #E.one!enumelt : {{.*}})
  return \E?.some?.one?.hashValue as KeyPath<E?, Int?>
}
