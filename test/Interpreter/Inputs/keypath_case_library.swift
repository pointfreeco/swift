public enum Status: Equatable {
  case idle
  case running(job: String)
  case failed(code: Int, message: String)
}

public let libFailedPath: CaseKeyPath<Status, (code: Int, message: String)> =
  \Status.failed

public func libExtract(_ s: Status) -> String? {
  s[keyPath: \Status.running]
}

public func libEmbed(_ job: String) -> Status {
  (\Status.running)(job)
}
