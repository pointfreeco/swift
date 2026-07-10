// The second version of keypath_case_library.swift: cases are reordered
// and a new one is inserted.
public enum Status: Equatable {
  case failed(code: Int, message: String)
  case starting(delay: Int)
  case idle
  case running(job: String)
}

public let libFailedPath: CaseKeyPath<Status, (code: Int, message: String)> =
  \Status.failed

public func libExtract(_ s: Status) -> String? {
  s[keyPath: \Status.running]
}

public func libEmbed(_ job: String) -> Status {
  (\Status.running)(job)
}
