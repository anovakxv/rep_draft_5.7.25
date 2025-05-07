//
//  SignUpModel.swift
//  Rep 
//
//  Created by Dmytro Holovko on 13.12.2023.
//

import Foundation

struct SignUpModel {
    var name = ""
    var surname = ""
    var email = ""
    var newPassword = ""
    var confirmPassword = ""
    var phone = ""
    
    // TODO: Refactor fields validation
    var isValid: Bool {
        !name.isEmpty
        && !surname.isEmpty
        && !phone.isEmpty
        && !email.isEmpty
        && !newPassword.isEmpty
        && newPassword == confirmPassword
    }
}

extension SignUpDTO {
    init(from model: SignUpModel) {
        self.init(
            email: model.email,
            password: model.newPassword,
            confirmPassword: model.confirmPassword,
            name: model.name,
            surname: model.surname,
            phone: model.phone
        )
    }
}
