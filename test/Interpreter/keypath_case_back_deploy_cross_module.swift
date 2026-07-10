// RUN: %empty-directory(%t)
// RUN: %target-build-swift-dylib(%t/%target-library-name(keypath_case_back_deploy_library)) -enable-library-evolution -enable-experimental-feature CaseKeyPaths %S/Inputs/keypath_case_back_deploy_library.swift -emit-module -emit-module-path %t/keypath_case_back_deploy_library.swiftmodule -module-name keypath_case_back_deploy_library
// RUN: %target-codesign %t/%target-library-name(keypath_case_back_deploy_library)
// RUN: %target-build-swift -enable-experimental-feature CaseKeyPaths %s -lkeypath_case_back_deploy_library -I %t -L %t -o %t/main %target-rpath(%t)
// RUN: %target-codesign %t/main
// RUN: %target-run %t/main %t/%target-library-name(keypath_case_back_deploy_library)

// REQUIRES: executable_test
// REQUIRES: swift_feature_CaseKeyPaths
// REQUIRES: OS=macosx

// Both modules deploy to targets without `CaseKeyPath` runtime support, so
// their case components use the back-deployed computed encoding. Identity
// is keyed on the case's tag and holds across image boundaries.

import keypath_case_back_deploy_library
import StdlibUnittest

var BackDeployCrossModuleTests = TestSuite("CaseKeyPathBackDeployCrossModule")

BackDeployCrossModuleTests.test("extraction through a resilient enum") {
  let clientPath: KeyPath<Status, (code: Int, message: String)?> =
    \Status.failed
  let s = Status.failed(code: 7, message: "boom")
  expectEqual(7, s[keyPath: clientPath]?.code)
  expectNil(Status.idle[keyPath: clientPath])
  expectEqual("j", libExtract(.running(job: "j")))
}

BackDeployCrossModuleTests.test("identity across image boundaries") {
  let clientPath: KeyPath<Status, (code: Int, message: String)?> =
    \Status.failed
  expectEqual(libFailedPath, clientPath)
  expectEqual(libFailedPath.hashValue, clientPath.hashValue)
}

runAllTests()
