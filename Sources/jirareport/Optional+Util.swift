import Foundation

/*
 ref: https://stackoverflow.com/a/43081054/833197
 
 See ref for usage
 */
protocol OptionalMarkerProtocol {
  var orNil: String { get }
}

extension Optional: OptionalMarkerProtocol {
  var orNil: String {
    guard let me = self else {
      return "nil"
    }
    if me is String {
      return "\"\(me)\""
    }
    return "\(me)"
  }
}

extension Optional where Wrapped == String {
  var notEmpty: String? {
    if self?.isEmpty ?? true {
      return nil
    }
    return self
  }
}
