//  SkillAPI.swift
//  Rep
//
//  Created by Adam Novak 7.6.25
//

import Foundation

func fetchSkills(jwtToken: String, completion: @escaping ([SkillModel]) -> Void) {
    guard let url = URL(string: "\(APIConfig.baseURL)/api/user/get_skills") else { return }
    var request = URLRequest(url: url)
    if !jwtToken.isEmpty {
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
    }
    URLSession.shared.dataTask(with: request) { data, _, _ in
        guard let data = data else { return }
        if let result = try? JSONDecoder().decode([String: [SkillModel]].self, from: data) {
            DispatchQueue.main.async {
                completion(result["result"] ?? [])
            }
        }
    }.resume()
}

