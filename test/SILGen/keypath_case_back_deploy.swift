// RUN: %target-swift-emit-silgen -enable-experimental-feature CaseKeyPaths %s | %FileCheck %s
// REQUIRES: swift_feature_CaseKeyPaths
// REQUIRES: OS=macosx

// Deployment targets without runtime support encode case components as
// get-only computed components that older runtimes can instantiate.

enum Destination {
  case settings(Int)
  case home
}

// CHECK-LABEL: sil {{.*}} @$s{{.*}}9extracted
// CHECK: keypath $KeyPath<Destination, Optional<Int>>, (root $Destination; gettable_property $Optional<Int>, id #Destination.settings!enumelt : {{.*}}, getter @{{.*}}TK : {{.*}})
// CHECK-NOT: enum_case
func extracted() -> KeyPath<Destination, Int?> {
  \Destination.settings
}
