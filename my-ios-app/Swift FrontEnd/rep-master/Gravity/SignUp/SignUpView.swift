//
//  StartScreen.swift
//  Rep 
//
//  Created by Dmytro Holovko on 04.12.2023.
//

import SwiftUI
import Dependiject

struct GButton: View {
    private let text: String
    private let action: () -> Void
    
    init(
        text: String,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.action = action
    }
    
    var body: some View {
        Button(
            action: action,
            label: {
                HStack {
                    Spacer()
                    Text(text).font(.headline)
                    Spacer ()
                }
                .padding(8)
            }
        )
        
        .accentColor(.green)
    }
}

enum GTextFieldModel {
    case name
    case surname
    case newPassword
    case confirmPassword
    case password
    case email
    case phone
}

extension GTextFieldModel{
    var imageName: String {
        switch self {
        case .name, .surname: return "person"
        case .newPassword, .confirmPassword, .password: return "lock"
        case .email: return "envelope"
        case .phone: return "phone"
        }
    }
    
    var description: String {
        switch self {
        case .name: return "Name"
        case .surname: return "Surname"
        case .newPassword: return "New Password"
        case .confirmPassword: return "Confirm Password"
        case .password: return "Password"
        case .email: return "Email"
        case .phone: return "Phone Number"
        }
    }
    
    var textContentType: UITextContentType {
        switch self {
        case .phone: return .telephoneNumber
        case .name: return .name
        case .surname: return .familyName
        case .newPassword: return .newPassword
        case .confirmPassword, .password: return .password
        case .email: return .emailAddress
        }
    }
    
    var isPassword: Bool {
        switch self {
        case .confirmPassword, .password, .newPassword: return true
        default: return false
        }
    }
    
    var keyboardType: UIKeyboardType {
        switch self {
        case .phone: return .phonePad
        case .email: return .emailAddress
        default: return .default
        }
    }
}

struct GTextField: View {
    private let model: GTextFieldModel
    @Binding private var text: String
    
    init(
        model: GTextFieldModel,
        text: Binding<String>
    ) {
        self.model = model
        self._text = text
    }
    
    var body: some View {
        VStack(spacing: 8.0) {
            HStack {
                Image(systemName: model.imageName)
                    .frame(width: 30)
                if model.isPassword {
                    SecureField(model.description, text: $text)
                } else {
                    TextField(model.description, text: $text)
                }
            }
            .textContentType(model.textContentType)
            .keyboardType(model.keyboardType)
            .autocapitalization(.none)    
            .disableAutocorrection(true)
            Divider()
        }
    }
}

struct SignUpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Store var viewModel = Factory.shared.resolve(SignUpViewModel.self)
    @State var isAlertPresented: Bool = false
    
    var body: some View {
        VStack {
            VStack {
                Spacer(minLength: 0)
                headerView
                Spacer(minLength: 0)
                textFieldsView
                Spacer()
                Spacer()
            }
            .padding(24)
            buttonsView
            
            NavigationLink(destination: MainScreen(), isActive: $viewModel.isLoggedIn) { EmptyView() }
        }
        .toolbar(.hidden)
        .ignoresSafeArea(.keyboard)
        .onChange(of: viewModel.error) { _, newValue in
            isAlertPresented = newValue != nil
        }
        .alert(viewModel.error?.debugDescription ?? "", isPresented: $isAlertPresented) {
            Button("Ok", role: .cancel) { viewModel.error = nil }
        }
        .loading(isLoading: viewModel.isLoading)
    }
    
    @ViewBuilder
    var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8.0) {
                Text("Welcome,")
                    .font(.largeTitle)
                Text("Create new account to continue")
                    .font(.footnote)
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    var textFieldsView: some View {
        VStack(spacing: 24.0) {
            GTextField(model: .name, text: $viewModel.model.name)
            GTextField(model: .surname, text: $viewModel.model.surname)
            GTextField(model: .email, text: $viewModel.model.email)
            GTextField(model: .phone, text: $viewModel.model.phone)
            GTextField(model: .newPassword, text: $viewModel.model.newPassword)
            GTextField(model: .confirmPassword, text: $viewModel.model.confirmPassword)
        }
    }
    
    @ViewBuilder
    var buttonsView: some View {
        VStack(spacing: 24.0) {
            GButton(text: "Sign Up", action: viewModel.signup)
                .buttonStyle(.borderedProminent)
            HStack {
                Text("Already have an account?")
                Button("Login") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderless)
                .accentColor(.green)
            }
        }
        .padding(24)
        .font(.subheadline)
    }
}
