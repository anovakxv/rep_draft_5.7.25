//
//  RepSocialApp.swift
//  Rep 
//
//  Created by Dmytro Holovko on 28.10.2023.
//

import SwiftUI
import Dependiject
import Networking



@main
struct RepSocialApp: App {
    @KeychainWrapper(authTokenKey, defaultValue: nil)
    private var authToken: String?
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if authToken == nil {
                    LoginView()
                } else {
                    MainScreen()
                }
            }
        }
    }
    
    
    init() {
        Factory.register {
            // MARK: - InlineResponseInterceptor
            
            Service(.transient, ResponseInterceptor.self) { _ in
                InlineResponseInterceptor { networkResponse in
                    let request = networkResponse.request
                    let response = networkResponse.response
                    let responseData = networkResponse.responseData
                    var requestBodyString = ""
                    var responseBodyString = ""
                    if let requestBodyData = request.httpBody,
                       let jsonString = requestBodyData.prettyJSONString() {
                        requestBodyString = jsonString
                    } else {
                        requestBodyString = request.httpBody?.isEmpty ?? true
                            ? "empty"
                            : "couldn't parse request body"
                    }
                    if let jsonString = responseData.prettyJSONString() {
                        responseBodyString = "\(jsonString)"
                    } else {
                        responseBodyString = responseData.isEmpty
                            ? "empty"
                            : "couldn't parse response body"
                    }
                    let msg = """
                    \n> REQUEST: \(request.url?.description ?? "unknown")
                    > REQUEST HEADERS:\n\(request.allHTTPHeaderFields ?? [:])
                    > REQUEST BODY:\n\(requestBodyString)
                    < RESPONSE STATUS CODE: \(response.statusCode.description)
                    < RESPONSE HEADER x-request-id: \(response.allHeaderFields["x-request-id"] ?? "unknown")
                    < RESPONSE BODY:\n\(responseBodyString)
                    """
                    print(msg)
                }
            }
            
            // MARK: - NetworkService
        
            Service(.singleton, (any NetworkServicing).self) { [self] r in
                NetworkService(
                    token: self.authToken,
                    decoder: JSONDecoder.default,
                    encoder: JSONEncoder.default,
                    baseURL: "https://rep.zen.software/repapp/index.php/api/v1/",
                    urlSession: URLSession.shared,
                    responseInterceptors: [r.resolve(ResponseInterceptor.self)]
                )
            }
            
            // MARK: - AuthAPIProvider
            Service(.transient, AuthAPIProvidable.self) { r in
                AuthAPIProvider(networkService: r.resolve())
            }
            
            Service(.weak, SignUpViewModel.self) { r in
                SimpleSignUpViewModel(
                    authAPIProvider: r.resolve(),
                    networkService: r.resolve()
                )
            }
            
            Service(.weak, LoginViewModel.self) { r in
                SimpleLoginViewModel(
                    authAPIProvider: r.resolve(), 
                    networkService: r.resolve()
                )
            }
        }
    }
}




let lead = LeadModel(
    id: "1",
    firstName: "Mukundh",
    lastName: "Pandian",
    imageName: "leadPic",
    city: "LA",
    repType: "Lead",
    additionalInfo: "1. Human Resources - Scale\n2. Operations - Manufacturing\n3. Sales - Social Connector"
)

let portals: [PortalModel] = [
    .init(
        id: "1",
        title: "Networked Capital",
        subtitle: "Rep Something",
        city: "BOI",
        imageItems: [networkCapitalImageItem],
        description: "Networked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\nNetworked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\nNetworked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\n",
        categories: [.business],
        leads: [
            .init(id: "1", firstName: "Mukundh", lastName: "Pandian", imageName: "leadPic", city: "LA", repType: "Lead", additionalInfo: "1. Human Resources - Scale\n2. Operations - Manufacturing\n3. Sales - Social Connector"),
            .init(id: "2", firstName: "Mukundh", lastName: "Pandian", imageName: "leadPic", city: "LA", repType: "Lead", additionalInfo: "1. Human Resources - Scale\n2. Operations - Manufacturing\n3. Sales - Social Connector")
        ]
    ),
    
        .init(
            id: "2",
            title: "Software",
            subtitle: "Open Sourced V.1.1",
            city: "BOI",
            imageItems: [openSourceImageItem],
            description: "Networked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\nNetworked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\nNetworked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\n",
            categories: [.software, .business],
            leads: [
                .init(id: "1", firstName: "Mukundh", lastName: "Pandian", imageName: "leadPic", city: "LA", repType: "Lead", additionalInfo: "1. Human Resources - Scale\n2. Operations - Manufacturing\n3. Sales - Social Connector"),
                .init(id: "2", firstName: "Mukundh", lastName: "Pandian", imageName: "leadPic", city: "LA", repType: "Lead", additionalInfo: "1. Human Resources - Scale\n2. Operations - Manufacturing\n3. Sales - Social Connector")
            ]
        ),
    
        .init(
            id: "3",
            title: "Finance",
            subtitle: "Open Sourced V.1.1",
            city: "BOI",
            imageItems: [financeImageItem],
            description: "Networked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\nNetworked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\nNetworked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\n",
            categories: [],
            leads: [
                .init(id: "1", firstName: "Mukundh", lastName: "Pandian", imageName: "leadPic", city: "LA", repType: "Lead", additionalInfo: "1. Human Resources - Scale\n2. Operations - Manufacturing\n3. Sales - Social Connector"),
                .init(id: "2", firstName: "Mukundh", lastName: "Pandian", imageName: "leadPic", city: "LA", repType: "Lead", additionalInfo: "1. Human Resources - Scale\n2. Operations - Manufacturing\n3. Sales - Social Connector")
            ]
        ),
    
        .init(
            id: "4",
            title: "Idaho Solar Energy",
            subtitle: "Acceleration!",
            city: "BOI",
            imageItems: [idahoSolarImageItem],
            description: "Networked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\nNetworked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\nNetworked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\n",
            categories: [.business],
            leads: [
                .init(id: "1", firstName: "Mukundh", lastName: "Pandian", imageName: "leadPic", city: "LA", repType: "Lead", additionalInfo: "1. Human Resources - Scale\n2. Operations - Manufacturing\n3. Sales - Social Connector"),
                .init(id: "2", firstName: "Mukundh", lastName: "Pandian", imageName: "leadPic", city: "LA", repType: "Lead", additionalInfo: "1. Human Resources - Scale\n2. Operations - Manufacturing\n3. Sales - Social Connector")
            ]
        ),
    
        .init(
            id: "5",
            title: "Spiritual Health",
            subtitle: "Principled Congregations",
            city: "BOI",
            imageItems: [spiritualHealthImageItem],
            description: "Networked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\nNetworked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\nNetworked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\n",
            categories: [.health],
            leads: [
                .init(id: "1", firstName: "Mukundh", lastName: "Pandian", imageName: "leadPic", city: "LA", repType: "Lead", additionalInfo: "1. Human Resources - Scale\n2. Operations - Manufacturing\n3. Sales - Social Connector"),
                .init(id: "2", firstName: "Mukundh", lastName: "Pandian", imageName: "leadPic", city: "LA", repType: "Lead", additionalInfo: "1. Human Resources - Scale\n2. Operations - Manufacturing\n3. Sales - Social Connector")
            ]
        ),
    
        .init(
            id: "6",
            title: "Physical Health",
            subtitle: "Alliance?",
            city: "BOI",
            imageItems: [physicalHeadthImageItem],
            description: "Networked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\nNetworked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\nNetworked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\n",
            categories: [.health],
            leads: [
                .init(id: "1", firstName: "Mukundh", lastName: "Pandian", imageName: "leadPic", city: "LA", repType: "Lead", additionalInfo: "1. Human Resources - Scale\n2. Operations - Manufacturing\n3. Sales - Social Connector"),
                .init(id: "2", firstName: "Mukundh", lastName: "Pandian", imageName: "leadPic", city: "LA", repType: "Lead", additionalInfo: "1. Human Resources - Scale\n2. Operations - Manufacturing\n3. Sales - Social Connector")
            ]
        ),
    
        .init(
            id: "7",
            title: "Events",
            subtitle: "(...in real life...)",
            city: "BOI",
            imageItems: [eventsImageItem],
            description: "Networked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\nNetworked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\nNetworked Capital's goal is to accelerate and open-source the execution of projects. By uploading the blueprint for a project to the Networked Capital mobile application, leaders (\"Leads\") of a project can isolate the core metrics that need to be accomplished, recruit and scale teams, and incentivize people along the way.\n\nWe think of these projects as \"portals\" into the future, and think we should use technology to help build a better future. Not just reflect the present.\n\n",
            categories: [.events],
            leads: [
                .init(id: "1", firstName: "Mukundh", lastName: "Pandian", imageName: "leadPic", city: "LA", repType: "Lead", additionalInfo: "1. Human Resources - Scale\n2. Operations - Manufacturing\n3. Sales - Social Connector"),
                .init(id: "2", firstName: "Mukundh", lastName: "Pandian", imageName: "leadPic", city: "LA", repType: "Lead", additionalInfo: "1. Human Resources - Scale\n2. Operations - Manufacturing\n3. Sales - Social Connector")
            ]
        ),
]

let goals: [GoalModel] = [
    .init(
        title: "Energy",
        subtitle: "Clean Energy",
        progress: 120
    ),
    .init(
        title: "Energy",
        subtitle: "Potential Cutomers",
        progress: 2
    ),
    .init(
        title: "Energy",
        subtitle: "SolarCity Rep",
        progress: 33
    )
]


let chatItems: [ChatItemModel] = [
    .init(imageName: "lead3", name: "Martin G.", lastMessage: "Hello Matt! Are you still there? ", lastMessageDate: Date().addingTimeInterval(-1500)),
    .init(imageName: "lead2", name: "Hao Yong", lastMessage: "I ll think about it", lastMessageDate: Date().addingTimeInterval(-14000)),
    .init(imageName: "lead1", name: "Gloria Abrams", lastMessage: "Leaders of a project can isolate the core metrics that need to be accomplished", lastMessageDate: Date().addingTimeInterval(-1500)),
    .init(imageName: "lead4", name: "Leo Leo", lastMessage: "See you there", lastMessageDate: Date().addingTimeInterval(-9000)),
    .init(imageName: "lead5", name: "Ivan Jonson", lastMessage: "OK", lastMessageDate: Date().addingTimeInterval(-100)),
]


let eventsImageItem = ImageItem(url: Bundle.main.url(forResource: "events", withExtension: "png")!)
let financeImageItem = ImageItem(url: Bundle.main.url(forResource: "finance", withExtension: "png")!)
let idahoSolarImageItem = ImageItem(url: Bundle.main.url(forResource: "idahoSolar", withExtension: "png")!)
let openSourceImageItem = ImageItem(url: Bundle.main.url(forResource: "openSourcedSoftware", withExtension: "png")!)
let physicalHeadthImageItem = ImageItem(url: Bundle.main.url(forResource: "physicalHealth", withExtension: "png")!)
let spiritualHealthImageItem = ImageItem(url: Bundle.main.url(forResource: "spiritualHealth", withExtension: "png")!)
let networkCapitalImageItem = ImageItem(url: Bundle.main.url(forResource: "networkCapital", withExtension: "png")!)
