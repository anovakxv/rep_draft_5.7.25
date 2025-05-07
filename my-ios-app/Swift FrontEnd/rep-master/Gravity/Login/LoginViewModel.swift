//
//  LoginViewModel.swift
//  Rep 
//
//  Created by Dmytro Holovko on 13.12.2023.
//

import Foundation
import Dependiject
import Networking
import Combine

protocol LoginViewModel: AnyObservableObject {
    var email: String { get set}
    var password: String { get set }
    var isLoggedIn: Bool { get set }
    var isSignUpPresented: Bool { get set }
    var isLoading: Bool { get }
    var error: ServiceError? { get set }
    
    func login()
}

class SimpleLoginViewModel: LoginViewModel, ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoggedIn = false
    @Published var isSignUpPresented = false
    @Published var isLoading = false
    @Published var error: ServiceError? = nil
    
    @KeychainWrapper(authTokenKey, defaultValue: nil)
    private var authToken: String?
    
    private let authAPIProvider: AuthAPIProvidable
    private var networkService: any NetworkServicing
    private var cancellables = Set<AnyCancellable>()
    
    init(
        authAPIProvider: AuthAPIProvidable,
        networkService: any NetworkServicing
    ) {
        self.authAPIProvider = authAPIProvider
        self.networkService = networkService
    }
    
    func login() {
        guard !email.isEmpty && !password.isEmpty else {
            error = ServiceError.inputDataError
            return
        }
        isLoading = true
        authAPIProvider
            .login(with: .init(email: email, password: password))
            .handleEvents(receiveOutput: { [weak self] response in
                self?.authToken = response.token
                self?.networkService.token = response.token
            })
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case let .failure(cError) = completion {
                        self?.error = cError
                    }
                },
                receiveValue: { [weak self] response in
                    self?.isLoggedIn = true
                }
            )
            .store(in: &cancellables)
    }
}


private let defaults = UserDefaults.standard

@propertyWrapper
public struct UserDefault<T> {
    let key: String
    let defaultValue: T

    public init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    public var wrappedValue: T {
        get {
            return defaults.object(forKey: key) as? T ?? defaultValue
        }
        set {
            if let value = newValue as? OptionalProtocol, value.isNil {
                defaults.removeObject(forKey: key)
            } else {
                defaults.set(newValue, forKey: key)
            }
        }
    }
}

@propertyWrapper
public struct RawUserDefault<T: RawRepresentable> {
    let key: String
    let defaultValue: T

    public init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    public var wrappedValue: T {
        get {
            guard let rawValue = defaults.object(forKey: key) as? T.RawValue else {
                return defaultValue
            }
            return .init(rawValue: rawValue) ?? defaultValue
        }
        set {
            if let value = newValue as? OptionalProtocol, value.isNil {
                defaults.removeObject(forKey: key)
            } else {
                defaults.set(newValue.rawValue, forKey: key)
            }
        }
    }
}

@propertyWrapper
public struct CodableUserDefault<T: Codable> {
    let key: String
    let defaultValue: T

    public init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    public var wrappedValue: T {
        get {
            guard let value = defaults.object(forKey: key) as? Data else {
                return defaultValue
            }
            let decoder = JSONDecoder()
            let typedValue = try? decoder.decode(T.self, from: value)

            return typedValue ?? defaultValue
        }
        set {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(newValue) {
                defaults.set(encoded, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
    }
}

private protocol OptionalProtocol {
    var isNil: Bool { get }
}

extension Optional: OptionalProtocol {
    fileprivate var isNil: Bool {
        self == nil
    }
}

import KeychainSwift

fileprivate let keychain = KeychainSwift()

@propertyWrapper
struct KeychainWrapper {
    let key: String
    let defaultValue: String?

    init(_ key: String, defaultValue: String?) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: String? {
        get {
            return keychain.get(key)
        }
        set {
            guard let value = newValue else {
                keychain.delete(key)
                return
            }
            keychain.set(value, forKey: key)
        }
    }
}

let authTokenKey = "auth_token"
