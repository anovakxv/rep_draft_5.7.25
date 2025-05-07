//
//  NetworkService.swift
//
//
//  Created by Dmytro Holovko on 12.12.2023.
//

import Foundation
import Combine

public final class NetworkService<Decoder: TopLevelDecoder, Encoder: TopLevelEncoder>: NetworkServicing where Decoder.Input == Data, Encoder.Output == Data {
    public var token: String?
    public var urlSession: URLSession
    public var decoder: Decoder
    public var encoder: Encoder
    public var baseURL: String
    public var responseInterceptors: [ResponseInterceptor]

    public init(
        token: String?,
        decoder: Decoder,
        encoder: Encoder,
        baseURL: String,
        urlSession: URLSession,
        responseInterceptors: [ResponseInterceptor]
    ) {
        self.token = token
        self.decoder = decoder
        self.encoder = encoder
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.responseInterceptors = responseInterceptors
    }
}
