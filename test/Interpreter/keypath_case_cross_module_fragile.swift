// RUN: %empty-directory(%t)
// RUN: %target-build-swift-dylib(%t/%target-library-name(keypath_case_library)) -enable-experimental-feature CaseKeyPaths -disable-availability-checking %S/Inputs/keypath_case_library.swift -emit-module -emit-module-path %t/keypath_case_library.swiftmodule -module-name keypath_case_library
// RUN: %target-codesign %t/%target-library-name(keypath_case_library)
// RUN: %target-build-swift -enable-experimental-feature CaseKeyPaths -disable-availability-checking %s -lkeypath_case_library -I %t -L %t -o %t/main %target-rpath(%t)
// RUN: %target-codesign %t/main
// RUN: %target-run %t/main %t/%target-library-name(keypath_case_library)

// REQUIRES: executable_test
// REQUIRES: swift_feature_CaseKeyPaths

// Same as keypath_case_cross_module.swift, but the library is built without
// library evolution: case tags are encoded inline rather than resolved from
// the enum case tag global.

import keypath_case_library
import StdlibUnittest

var FragileCrossModuleTests = TestSuite("CaseKeyPathCrossModuleFragile")

FragileCrossModuleTests.test("extraction and embedding") {
  let clientPath: CaseKeyPath<Status, (code: Int, message: String)> =
    \Status.failed
  let s = Status.failed(code: 7, message: "boom")
  expectEqual(7, s[keyPath: clientPath]?.code)
  expectNil(Status.idle[keyPath: clientPath])
  expectEqual(Status.running(job: "j"), libEmbed("j"))
}

FragileCrossModuleTests.test("identity across image boundaries") {
  let clientPath: CaseKeyPath<Status, (code: Int, message: String)> =
    \Status.failed
  expectEqual(libFailedPath, clientPath)
  expectEqual(libFailedPath.hashValue, clientPath.hashValue)
}

runAllTests()
