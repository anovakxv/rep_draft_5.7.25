//
//  LoginView.swift
//  Rep 
//
//  Created by Dmytro Holovko on 04.12.2023.
//

import SwiftUI
import Combine
import Dependiject

struct LoginView: View {
    @Store private var viewModel = Factory.shared.resolve(LoginViewModel.self)
    @State private var isAlertPresented = false
    
    var body: some View {
        VStack {
            VStack {
                Spacer(minLength: 0)
                headerView
                Spacer(minLength: 0)
                VStack (spacing: 12.0) {
                    textFieldsView
                    forgotPasswordButton
                }
                Spacer()
                Spacer()
                Spacer()
                NavigationLink(destination: MainScreen(), isActive: $viewModel.isLoggedIn) { EmptyView() }
                NavigationLink(destination: SignUpView(), isActive: $viewModel.isSignUpPresented) { EmptyView() }
            }
            .padding(24)
            buttonsView
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
                Text("Welcome Back,")
                    .font(.largeTitle)
                Text("Sign in to continue")
                    .font(.footnote)
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    var textFieldsView: some View {
        VStack(spacing: 24.0) {
            GTextField(model: .email, text: $viewModel.email)
            GTextField(model: .password, text: $viewModel.password)
        }
    }
    
    @ViewBuilder
    var forgotPasswordButton: some View {
        HStack {
            Spacer()
            Button("Forgot password?") {
                
            }
            .buttonStyle(.borderless)
            .accentColor(.green)
            .font(.caption)
        }
    }
    
    @ViewBuilder
    var buttonsView: some View {
        VStack(spacing: 24.0) {
            GButton(text: "Login") {
                viewModel.login()
            }
            .buttonStyle(.borderedProminent)
            HStack {
                Text("New User?")
                
                Button (action:{
                    viewModel.isSignUpPresented = true
                }, label: {
                    Text("Sign Up")
                })
                .buttonStyle(.borderless)
                .accentColor(.green)
            }
        }
        .padding(24)
        .font(.subheadline)
    }
}

#Preview {
    LoginView()
}
