// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -primary-file %s -O -sil-verify-all -emit-sil -enable-experimental-feature CaseKeyPaths -disable-availability-checking >%t/output.sil
// RUN: %FileCheck %s < %t/output.sil
// RUN: %FileCheck %s -check-prefix=CHECK-ALL < %t/output.sil

// RUN: %target-build-swift -O -Xfrontend -disable-availability-checking -enable-experimental-feature CaseKeyPaths %s -o %t/a.out
// RUN: %target-run %t/a.out | %FileCheck %s -check-prefix=CHECK-OUTPUT

// REQUIRES: executable_test
// REQUIRES: swift_feature_CaseKeyPaths

// Check that case key path applications are folded to direct enum
// projections, and embeddings to direct enum constructions.

// CHECK-ALL-NOT: = keypath

enum E {
  case one(Int)
  case two(a: Int, b: Int)
  case three
}

enum Gen<T> {
  case value(T)
  case empty
}

enum Outer {
  case inner(E)
  case alone
}

enum GenOuter<T> {
  case inner(Gen<T>)
}

enum Text {
  case string(String)
}

// CHECK-LABEL: sil {{.*}}testSinglePayload
// CHECK: switch_enum %0, case #E.one!enumelt
// CHECK: return
@inline(never)
func testSinglePayload(_ e: E) -> Int? {
  e[keyPath: \E.one]
}

// CHECK-LABEL: sil {{.*}}testMultiPayload
// CHECK: switch_enum %0, case #E.two!enumelt
// CHECK: return
@inline(never)
func testMultiPayload(_ e: E) -> (a: Int, b: Int)? {
  e[keyPath: \E.two]
}

// CHECK-LABEL: sil {{.*}}testNoPayload
// CHECK: switch_enum %0, case #E.three!enumelt
// CHECK: return
@inline(never)
func testNoPayload(_ e: E) -> ()? {
  e[keyPath: \E.three]
}

// CHECK-LABEL: sil {{.*}}testOffset
// CHECK: enum $Optional<Int>, #Optional.none
// CHECK: return
@inline(never)
func testOffset() -> Int? {
  MemoryLayout<E>.offset(of: \E.one)
}

// CHECK-LABEL: sil {{.*}}testEmbed
// CHECK: enum $E, #E.one!enumelt
// CHECK: return
@inline(never)
func testEmbed(_ x: Int) -> E {
  (\E.one)(x)
}

// CHECK-LABEL: sil {{.*}}testEmbedNoPayload
// CHECK: enum $E, #E.three!enumelt
// CHECK: return
@inline(never)
func testEmbedNoPayload() -> E {
  (\E.three)()
}

// CHECK-LABEL: sil {{.*}}testComposedEmbed
// CHECK: enum $E, #E.one!enumelt
// CHECK: enum $Outer, #Outer.inner!enumelt
// CHECK: return
@inline(never)
func testComposedEmbed(_ x: Int) -> Outer {
  (\Outer.inner?.one)(x)
}

// CHECK-LABEL: sil {{.*}}testComposedRead
// CHECK: switch_enum %0, case #Outer.inner!enumelt
// CHECK: switch_enum {{%[0-9]+}}, case #E.one!enumelt
// CHECK: return
@inline(never)
func testComposedRead(_ o: Outer) -> Int? {
  o[keyPath: \Outer.inner?.one]
}

// CHECK-LABEL: sil {{.*}}testGenericRead
// CHECK-NOT: swift_getAtKeyPath
// CHECK: } // end sil function
@inline(never)
@_semantics("optimize.sil.specialize.generic.never")
func testGenericRead<T>(_ g: Gen<T>) -> T? {
  g[keyPath: \Gen<T>.value]
}

// CHECK-LABEL: sil {{.*}}testGenericEmbed
// CHECK-NOT: callAsFunction
// CHECK: } // end sil function
@inline(never)
@_semantics("optimize.sil.specialize.generic.never")
func testGenericEmbed<T>(_ x: T) -> GenOuter<T> {
  (\GenOuter<T>.inner?.value)(x)
}

// CHECK-LABEL: sil {{.*}}testEmbedNontrivial
// CHECK: enum $Text, #Text.string!enumelt
// CHECK: return
@inline(never)
func testEmbedNontrivial(_ s: String) -> Text {
  (\Text.string)(s)
}

// CHECK-OUTPUT: 1
print(testSinglePayload(.one(1))!)
// CHECK-OUTPUT-NEXT: nil
print(testSinglePayload(.three) as Any)
// CHECK-OUTPUT-NEXT: (a: 2, b: 3)
print(testMultiPayload(.two(a: 2, b: 3))!)
// CHECK-OUTPUT-NEXT: ()
print(testNoPayload(.three)!)
// CHECK-OUTPUT-NEXT: nil
print(testOffset() as Any)
// CHECK-OUTPUT-NEXT: one(6)
print(testEmbed(6))
// CHECK-OUTPUT-NEXT: three
print(testEmbedNoPayload())
// CHECK-OUTPUT-NEXT: inner({{.*}}E.one(7))
print(testComposedEmbed(7))
// CHECK-OUTPUT-NEXT: 5
print(testComposedRead(.inner(.one(5)))!)
// CHECK-OUTPUT-NEXT: nil
print(testComposedRead(.alone) as Any)
// CHECK-OUTPUT-NEXT: 4
print(testGenericRead(Gen.value(4))!)
// CHECK-OUTPUT-NEXT: nil
print(testGenericRead(Gen<Int>.empty) as Any)
// CHECK-OUTPUT-NEXT: inner({{.*}}value(9))
print(testGenericEmbed(9))
// CHECK-OUTPUT-NEXT: string("hi")
print(testEmbedNontrivial("hi"))
