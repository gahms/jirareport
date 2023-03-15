import Foundation

struct FlexibleJSONDateDecoder {
    // ref: https://stackoverflow.com/a/46458771/833197
    // ref: https://stackoverflow.com/a/46246880/833197
    
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withDashSeparatorInDate,
            .withColonSeparatorInTime,
            .withTimeZone,
        ]
        return formatter
    }()
    
    static let iso8601fractionals: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withDashSeparatorInDate,
            .withColonSeparatorInTime,
            .withTimeZone,
            .withFractionalSeconds
        ]
        return formatter
    }()
    
    static func decode(_ decoder: Decoder) throws -> Date {
        /*
         * We want to use ISO 8601 but we want to use fractionals on the seconds.
         * We also want to be robust and handle if we do get some data without
         * the fraction.
         *
         * Lastly we also want to handle the default JSONEncoder date format
         * because old model store files use this obscure and iOS/macOS
         * specific format. (number of decimal seconds since 1 January 2001).
         */
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            if let date = iso8601fractionals.date(from: string) {
                return date
            }
            if let date = iso8601.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid date: \(string)")
        }
        
        // This is the default JSONDecoder behaviour (.deferredToDate)
        return try Date(from: decoder)
    }
    
    static func encode(_ date: Date, _ encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(iso8601fractionals.string(from: date))
    }
    
}
