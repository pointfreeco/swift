// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -primary-file %s -O -sil-verify-all -emit-sil -enable-experimental-feature CaseKeyPaths -disable-availability-checking >%t/output.sil
// RUN: %FileCheck %s < %t/output.sil

// RUN: %target-build-swift -O -Xfrontend -disable-availability-checking -enable-experimental-feature CaseKeyPaths %s -o %t/a.out
// RUN: %target-run %t/a.out | %FileCheck %s -check-prefix=CHECK-OUTPUT

// REQUIRES: executable_test
// REQUIRES: swift_feature_CaseKeyPaths

// A `keypath.caseEmbed` annotation whose shape does not match the real
// `callAsFunction` is left untouched.

enum E {
  case one(Int)
}

@_semantics("keypath.caseEmbed")
@inline(never)
func fakeEmbed(_ keyPath: CaseKeyPath<E, Int>) -> E {
  .one(99)
}

// CHECK-LABEL: sil {{.*}}testFakeEmbed
// CHECK: function_ref @{{.*}}fakeEmbed
// CHECK: apply
// CHECK: return
@inline(never)
func testFakeEmbed() -> E {
  fakeEmbed(\E.one)
}

// CHECK-OUTPUT: one(99)
print(testFakeEmbed())
