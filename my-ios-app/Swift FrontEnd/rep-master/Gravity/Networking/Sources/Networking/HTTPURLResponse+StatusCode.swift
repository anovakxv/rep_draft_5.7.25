//
//  HTTPURLResponse.swift
//
//
//  Created by Dmytro Holovko on 12.12.2023.
//

import Foundation

extension HTTPURLResponse {
    typealias StatusCode = Int
}

extension HTTPURLResponse.StatusCode {
    /// Informational responses.
    static let informational = 100 ... 199

    /// Successful responses.
    static let successful = 200 ... 299

    /// Redirect responses.
    static let redirect = 300 ... 399

    /// Client error responses.
    static let clientError = 400 ... 499

    /// Server error responses.
    static let serverError = 500 ... 599
}

extension HTTPURLResponse.StatusCode {
    /// Defines an error type according the status code.
    func mapError(errorDescription: ErrorDescription?) -> ServiceError? {
        switch self {
        case Self.successful: return nil
        case Self.clientError: return ServiceError.clientError(self, errorDescription)
        case Self.serverError: return ServiceError.serverError(self, errorDescription)
        default: return ServiceError.http(self, errorDescription)
        }
    }
}

public struct NetworkResponse {
    public let request: URLRequest
    public let response: HTTPURLResponse
    public let responseData: Data
}

import Combine



import Combine

public protocol NetworkServicing {
    associatedtype Decoder: TopLevelDecoder where Decoder.Input == Data
    associatedtype Encoder: TopLevelEncoder where Encoder.Output == Data

    var token: String? { get set }
    var decoder: Decoder { get }
    var encoder: Encoder { get }
    var baseURL: String { get }
    var urlSession: URLSession { get }
    var responseInterceptors: [ResponseInterceptor] { get }

    func execute<Output: Decodable>(_ request: Request) -> AnyPublisher<Output, ServiceError>
    func execute<Input: Encodable, Output: Decodable>(_ request: Request, with body: Input) -> AnyPublisher<Output, ServiceError>
}

public extension NetworkServicing {
    func execute<Output: Decodable>(_ request: Request) -> AnyPublisher<Output, ServiceError> {
        perform(request)
            .decode(with: decoder)
            .mapServiceError()
            .eraseToAnyPublisher()
    }

    func execute<Input: Encodable, Output: Decodable>(_ request: Request, with body: Input) -> AnyPublisher<Output, ServiceError> {
        perform(request, with: body)
            .decode(with: decoder)
            .mapServiceError()
            .eraseToAnyPublisher()
    }
}


extension Publisher where Output == Data {
    /// Decodes the output from the upstream using a specified decoder
    func decode<T, D>(with decoder: D) -> AnyPublisher<T, Error> where T: Decodable, D: TopLevelDecoder, Output == D.Input {
        decode(type: T.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
}

import Combine

extension Publisher {
    /// Converts any failure from the upstream publisher into a new ``ServiceError``.
    func mapServiceError() -> AnyPublisher<Output, ServiceError> {
        mapError { error -> ServiceError in
            guard let definedError = error as? ServiceError else {
                switch error {
                case is Swift.DecodingError:
                    return .parseError(error.localizedDescription)
                case let err where err.isConnectionLostError:
                    return .connectionLost
                case let urlError as URLError:
                    switch urlError.code {
                    case .notConnectedToInternet, .dataNotAllowed:
                        return .noInternetConnection
                    case .timedOut:
                        return .timeout
                    default:
                        return .urlError(urlError)
                    }
                default:
                    return .error(error as NSError)
                }
            }
            return definedError
        }.eraseToAnyPublisher()
    }
}

extension Publisher where Output == Data {
    /// For old Auth flow API
    func tryOldAPIErrorResponse<D>(with decoder: D) -> AnyPublisher<Data, Error> where D: TopLevelDecoder, Output == D.Input {
        tryMap { data -> Data in
            if let response = try? decoder.decode(ErrorResponse.self, from: data) {
                throw ServiceError.errorResponse(response.error)
            }
            return data
        }
        .eraseToAnyPublisher()
    }
}

private struct ErrorResponse: Decodable {
    let success: Bool
    let error: String
}

extension Publisher where Output == URLSession.DataTaskPublisher.Output {
    /// Transforms all elements from the upstream publisher with a provided error-throwing closure.
    func tryResponse<Decoder: TopLevelDecoder> (for request: URLRequest, responseInterceptors: [ResponseInterceptor], errorDecoder: Decoder) -> AnyPublisher<Data, Error> where Decoder.Input == Data {
        tryMap { data, response -> Data in
            let errorDescription = try? errorDecoder.decode(ErrorDescription.self, from: data)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.invalidResponse(response)
            }
            let networkResponse = NetworkResponse(request: request, response: httpResponse, responseData: data)
            responseInterceptors.forEach { $0.intercept(response: networkResponse) }
            if let httpError = httpResponse.statusCode.mapError(errorDescription: errorDescription) {
                throw httpError
            }
            return data
        }
        .eraseToAnyPublisher()
    }
}

