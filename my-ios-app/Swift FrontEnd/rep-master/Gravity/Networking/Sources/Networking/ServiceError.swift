//
//  ServiceError.swift
//  
//
//  Created by Dmytro Holovko on 12.12.2023.
//

import Foundation

public enum ServiceError: Error, Hashable {
    /// A data connection is not currently allowed.
    case noInternetConnection

    /// Connection was lost during execution
    case connectionLost

    /// Request timeout
    case timeout

    /// Invalid token
    case invalidUrl

    /// Invalid token
    case invalidToken

    /// Input data could not be formed.
    case inputDataError

    /// URL error.
    case urlError(URLError)

    /// The server response was invalid (unexpected format).
    case invalidResponse(URLResponse)

    /// The request was rejected: 400-499
    case clientError(Int, ErrorDescription?)

    /// Server error 500...599
    case serverError(Int, ErrorDescription?)

    /// Unexpected status code error.
    case http(Int, ErrorDescription?)

    /// Parsing error.
    case parseError(String)

    /// Old Auth flow API error from server with 200 status and response body with String error code ¯\_(ツ)_/¯
    case errorResponse(String)

    /// Unexpected error.
    case error(NSError)
}

public extension ServiceError {
    var debugDescription: String {
        switch self {
        case .noInternetConnection:
            return "No Internet connection"
        case .connectionLost:
            return "Connection was lost"
        case .timeout:
            return "Timeout"
        case .invalidUrl:
            return "Invalid URL"
        case .invalidToken:
            return "Invalid token"
        case .inputDataError:
            return "Input data error"
        case .urlError(let error):
            return "URL error \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response type"
        case .clientError:
            // TODO: Check if it's appropriate description
            return "Something went wrong"
        case .serverError(let code, let description):
            return "Server error with code: \(code), desc: \(description?.message ?? "none")"
        case .http(let code, let description):
            return "Unexpected HTTP code: \(code), desc: \(description?.message ?? "none")"
        case .parseError(let description):
            return "Parse error \(description)"
        case .errorResponse(let error):
            return "Error response: \(error)"
        case .error(let nsError):
            return "Undefined error \(nsError.localizedDescription)"
        }
    }
}

public extension ServiceError {
    var isRetriable: Bool {
        return self == .connectionLost
    }
}


public struct ErrorDescription: Decodable, Equatable, Hashable {
    public let message: String
    public let code: Int?
}

extension Error {
    /// -1005 - URLError networkConnectionLost
    /// 53 - POSIXError Software caused connection abort;
    var isConnectionLostError: Bool {
        let code = (self as NSError).code
        return [-1005, 53].contains(code)
    }
}
