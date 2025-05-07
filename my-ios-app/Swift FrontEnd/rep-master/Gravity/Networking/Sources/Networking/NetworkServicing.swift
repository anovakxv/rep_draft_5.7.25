//
//  NetworkServicing.swift
//  
//
//  Created by Dmytro Holovko on 12.12.2023.
//

import Foundation
import Combine

extension NetworkServicing {
    /// Error publisher for input data error.
    func serviceErrorPublisher<M>(_ error: ServiceError) -> AnyPublisher<M, ServiceError> {
        Fail<M, ServiceError>(error: error)
            .eraseToAnyPublisher()
    }
}

extension NetworkServicing {
    /// Performs a request with a body for.
    func perform<Input: Encodable>(_ request: Request, with body: Input) -> AnyPublisher<Data, ServiceError> {
        do {
            let httpBody = try encoder.encode(body)
            let request = try request.urlRequest(
                baseURL: baseURL,
                body: httpBody,
                token: token
            )
            return perform(request)
        } catch {
            return serviceErrorPublisher((error as? ServiceError) ?? .inputDataError)
        }
    }

    func perform(_ request: Request) -> AnyPublisher<Data, ServiceError> {
        do {
            let request = try request.urlRequest(
                baseURL: baseURL,
                token: token
            )
            return perform(request)
        } catch {
            return serviceErrorPublisher((error as? ServiceError) ?? .inputDataError)
        }
    }
}

extension NetworkServicing {
    /// Performs a URLRequest.
    func perform(_ request: URLRequest) -> AnyPublisher<Data, ServiceError> {
        return urlSession
            .dataTaskPublisher(for: request)
            .tryResponse(
                for: request,
                responseInterceptors: responseInterceptors,
                errorDecoder: decoder
            )
            .mapServiceError()
            .eraseToAnyPublisher()
    }
}
