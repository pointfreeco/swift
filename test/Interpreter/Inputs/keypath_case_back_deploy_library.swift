public enum Status: Equatable {
  case idle
  case running(job: String)
  case failed(code: Int, message: String)
}

public let libFailedPath: KeyPath<Status, (code: Int, message: String)?> =
  \Status.failed

public func libExtract(_ s: Status) -> String? {
  s[keyPath: \Status.running]
}
