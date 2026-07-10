// RUN: %empty-directory(%t)
// RUN: %target-build-swift-dylib(%t/%target-library-name(keypath_case_library)) -enable-library-evolution -enable-experimental-feature CaseKeyPaths -disable-availability-checking %S/Inputs/keypath_case_library.swift -emit-module -emit-module-path %t/keypath_case_library.swiftmodule -module-name keypath_case_library
// RUN: %target-codesign %t/%target-library-name(keypath_case_library)
// RUN: %target-build-swift -enable-experimental-feature CaseKeyPaths -disable-availability-checking %s -lkeypath_case_library -I %t -L %t -o %t/main %target-rpath(%t)
// RUN: %target-codesign %t/main
// RUN: %target-run %t/main %t/%target-library-name(keypath_case_library)
//
// Rebuild the library with its cases reordered and a new one inserted, and
// run the same client binary against it.
// RUN: %target-build-swift-dylib(%t/%target-library-name(keypath_case_library)) -enable-library-evolution -enable-experimental-feature CaseKeyPaths -disable-availability-checking %S/Inputs/keypath_case_library_reordered.swift -emit-module -emit-module-path %t/keypath_case_library.swiftmodule -module-name keypath_case_library
// RUN: %target-codesign %t/%target-library-name(keypath_case_library)
// RUN: %target-run %t/main %t/%target-library-name(keypath_case_library)

// REQUIRES: executable_test
// REQUIRES: swift_feature_CaseKeyPaths

import keypath_case_library
import StdlibUnittest

var EvolutionTests = TestSuite("CaseKeyPathLibraryEvolution")

EvolutionTests.test("extraction and embedding") {
  let clientPath: CaseKeyPath<Status, (code: Int, message: String)> =
    \Status.failed
  let s = Status.failed(code: 7, message: "boom")
  let values = s[keyPath: clientPath]
  expectEqual(7, values?.code)
  expectEqual("boom", values?.message)
  expectNil(Status.idle[keyPath: clientPath])
  expectEqual(Status.failed(code: 1, message: "x"),
              clientPath((code: 1, message: "x")))
  expectEqual("j", libExtract(.running(job: "j")))
  expectEqual(Status.running(job: "j"), libEmbed("j"))
}

EvolutionTests.test("identity across image boundaries") {
  let clientPath: CaseKeyPath<Status, (code: Int, message: String)> =
    \Status.failed
  expectEqual(libFailedPath, clientPath)
  expectEqual(libFailedPath.hashValue, clientPath.hashValue)
}

runAllTests()
