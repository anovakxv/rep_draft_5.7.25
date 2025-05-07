//
//  Request.swift
//  
//
//  Created by Dmytro Holovko on 12.12.2023.
//

import Foundation

public protocol Request {
    var isAuthRequired: Bool { get }
    var headers: [RequestHeader] { get }
    var queryParameters: [String: Any] { get }
    var route: String { get }
    var method: RequestMethod { get }
}

extension Request {
    /// Creates a URLRequest.
    /// throws: ServiceError
    func urlRequest(
        baseURL: String,
        body: Data? = nil,
        token: String?
    ) throws -> URLRequest {
        guard let url = url(with: baseURL) else { throw ServiceError.invalidUrl }
        var request = URLRequest(url: url)
        request.timeoutInterval = 60
        request.httpMethod = method.rawValue
        request.httpBody = body
        headers.forEach { request.addValue($0) }
        if isAuthRequired {
            guard let token else { throw ServiceError.invalidToken }
            request.addValue(.authorization(bearerToken: token))
        }
        return request
    }
}

private extension Request {
    func url(with baseURL: String) -> URL? {
        guard var urlComponents = URLComponents(string: baseURL) else { return nil }
        urlComponents.path += route
        urlComponents.queryItems = queryItems
        return urlComponents.url
    }

    /// Creates a list of parameters.
    var queryItems: [URLQueryItem]? {
        queryParameters.map { item -> URLQueryItem in
            let valueString = String(describing: item.value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            return URLQueryItem(name: item.key, value: valueString)
        }
    }
}
