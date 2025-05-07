//
//  ResponseInterceptor.swift
//  
//
//  Created by Dmytro Holovko on 12.12.2023.
//

import Foundation

public protocol ResponseInterceptor {
    func intercept(response: NetworkResponse)
}

public class InlineResponseInterceptor: ResponseInterceptor {
    private let callback: (NetworkResponse) -> Void

    public init(_ callback: @escaping (NetworkResponse) -> Void) {
        self.callback = callback
    }

    public func intercept(response: NetworkResponse) {
        callback(response)
    }
}

public extension Data {
    func prettyJSONString() -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
            let jsonData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
            let prettyPrintedString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)
        else { return nil }
        return "\(prettyPrintedString)"
    }
}
    
public extension JSONDecoder {
    static let `default`: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .customISO8601OrEpochTime
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

public extension JSONDecoder.DateDecodingStrategy {
    static let customISO8601OrEpochTime = custom {
        let container = try $0.singleValueContainer()
        let string = try? container.decode(String.self)

        if let dateString = string,
            let date = Date.fromISOString(dateString) {
            return date
        }
        // try parse from epoch time in milliseconds
        let timeInterval = try container.decode(TimeInterval.self) / 1000
        let date = Date(timeIntervalSince1970: timeInterval)

        return date
    }
}


public extension JSONEncoder {
    static let pretty: JSONEncoder = {
        let encoder = JSONEncoder.default.copy()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()

    static let `default`: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .customISO8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
}

public extension JSONEncoder.DateEncodingStrategy {
    static let customISO8601 = custom { date, encoder in
        let stringData = date.ISOFormatted
        var container = encoder.singleValueContainer()
        try container.encode(stringData)
    }
}

public extension JSONEncoder {
    func copy() -> JSONEncoder {
        let new = JSONEncoder()
        new.dataEncodingStrategy = dataEncodingStrategy
        new.dateEncodingStrategy = dateEncodingStrategy
        new.keyEncodingStrategy = keyEncodingStrategy
        new.nonConformingFloatEncodingStrategy = nonConformingFloatEncodingStrategy
        new.outputFormatting = outputFormatting
        new.userInfo = userInfo
        return new
    }
}

public extension Date {
    func adding(
        _ component: Calendar.Component,
        value: Int = 1,
        using calendar: Calendar = .current
    ) -> Date {
        calendar.date(
            byAdding: component,
            value: value,
            to: self
        ) ?? self
    }
}

public extension Date {
    var ISOFormatted: String {
        return ISO8601DateFormatter.internetDateFormatterWithFractionalSeconds.string(from: self)
    }

    static func fromISOString(_ string: String) -> Date? {
        return ISO8601DateFormatter.internetDateFormatter.date(from: string)
            ?? ISO8601DateFormatter.internetDateFormatterWithFractionalSeconds.date(from: string)
    }
}

public extension ISO8601DateFormatter {
    static var internetDateFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }

    static var internetDateFormatterWithFractionalSeconds: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    static var currentDateString: String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }
}
