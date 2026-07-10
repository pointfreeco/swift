// RUN: %empty-directory(%t)
// RUN: %target-build-swift-dylib(%t/%target-library-name(keypath_case_library)) -enable-library-evolution -enable-experimental-feature CaseKeyPaths -disable-availability-checking %S/Inputs/keypath_case_library.swift -emit-module -emit-module-path %t/keypath_case_library.swiftmodule -module-name keypath_case_library
// RUN: %target-codesign %t/%target-library-name(keypath_case_library)
// RUN: %target-build-swift -enable-experimental-feature CaseKeyPaths -disable-availability-checking %s -lkeypath_case_library -I %t -L %t -o %t/main %target-rpath(%t)
// RUN: %target-codesign %t/main
// RUN: %target-run %t/main %t/%target-library-name(keypath_case_library)

// REQUIRES: executable_test
// REQUIRES: swift_feature_CaseKeyPaths

import keypath_case_library
import StdlibUnittest

var CrossModuleTests = TestSuite("CaseKeyPathCrossModule")

CrossModuleTests.test("extraction through a resilient enum") {
  let clientPath: CaseKeyPath<Status, (code: Int, message: String)> =
    \Status.failed
  let s = Status.failed(code: 7, message: "boom")
  let values = s[keyPath: clientPath]
  expectEqual(7, values?.code)
  expectEqual("boom", values?.message)
  expectNil(Status.idle[keyPath: clientPath])
}

CrossModuleTests.test("embedding into a resilient enum") {
  let clientPath: CaseKeyPath<Status, (code: Int, message: String)> =
    \Status.failed
  expectEqual(Status.failed(code: 1, message: "x"),
              clientPath((code: 1, message: "x")))
  expectEqual(Status.running(job: "j"), libEmbed("j"))
}

CrossModuleTests.test("library-formed paths") {
  expectEqual("j", libExtract(.running(job: "j")))
  expectNil(libExtract(.idle))
  let s = Status.failed(code: 2, message: "y")
  expectEqual(2, s[keyPath: libFailedPath]?.code)
}

CrossModuleTests.test("identity across image boundaries") {
  let clientPath: CaseKeyPath<Status, (code: Int, message: String)> =
    \Status.failed
  expectEqual(libFailedPath, clientPath)
  expectEqual(libFailedPath.hashValue, clientPath.hashValue)
  expectNotEqual(libFailedPath as AnyKeyPath, \Status.running as AnyKeyPath)
}

runAllTests()
