//
//  RepSkillsModel.swift
//  Rep 
//
//  Created by Dmytro Holovko on 10.12.2023.
//

import Foundation

enum RepSkillsModel: String {
    // MARK: - HR Skills
    case hrScale = "HR: Scale"
    case hrSducation = "HR: Education"
    case hrProductivity = "HR: Productivity"
    case hrPhysicalHealth = "HR: Physical Health"
    case hrMentalHealth = "HR: Mental Health"
    
    // MARK: - Engineering Skills
    case engineeringSoftwareDesign = "Engineering: Software Design"
    case engineeringSoftwareDev = "Engineering: Software Dev"
    case engineeringHardware = "Engineering: Hardware"
    case engineeringCSAndAI = "Engineering: CS and AI"
    case engineeringCivil = "Engineering: Civil"
    case engineeringMechanical = "Engineering: Mechanical"
    case engineeringAirNSpace = "Engineering: Air & Space"
    case engineeringMaterials = "Engineering: Materials"
    case engineeringRND = "Engineering: R&D"
    case engineeringOther = "Engineering: Other"
    
    // MARK: - Sales & Marketing Skills
    case smNetworking = "Sales & Marketing: Networking"
    case smSales = "Sales & Marketing: Sales"
    case smAdvertising = "Sales & Marketing: Advertising"
    case smBranding = "Sales & Marketing: Branding"
    case smComms = "Sales & Marketing: Comms"
    
    // MARK: - Grassroots Skills
    case grassrootsVirtualMeetings = "Grassroots: Virtual Meetings"
    case grassrootsCoordination = "Grassroots: Coordination"
    case grassrootsEventComms = "Grassroots: Event Comms"
    
    // MARK: - Events Skills
    case eventsPlanning = "Events: Planning"
    case eventsLogistics = "Events: Logistics"
    case eventsPromotion = "Events: Promotion"
    case eventsIterativeEvolution = "Events: Iterative Evolution"
    
    // MARK: - Content Skills
    case cantentGraphics = "Content: Graphics"
    case cantentImages = "Content: Images"
    case cantentWriting = "Content: Writing"
    case cantentVideoProduction = "Content: Video Production"
    case cantentVideoEditing = "Content: Video Editing"

    // MARK: - Finance Skills
    case financeInternal = "Finance: Internal"
    case financeAccounting = "Finance: Accounting"
    case financeMNA = "Finance: M&A"
    case financeDealStructures = "Finance: Deal Structures"
    case financeInvesting = "Finance: Investing"
    case financeOptimization = "Finance: Optimization"
    case financeIncentiveStructures = "Finance: Incentive Structures"
    
    // MARK: - Spiritual Skills
    case spiritualPrinciples = "Spiritual: Principles"
    case spiritualCollaboration = "Spiritual: Collaboration"
    case spiritualLeadership = "Spiritual: Leadership"
    
    // MARK: -
    case managementOptimization = "Management: Optimization"
    case other = "Other: Other"
}

// MARK: - RepSkillsModel + CustomStringConvertible -

extension RepSkillsModel: CustomStringConvertible {
    static var title: String {
        "Rep Skills"
    }
    
    var description: String {
        switch self {
        case .hrScale: return "HR: Scale"
        case .hrSducation: return "HR: Education"
        case .hrProductivity: return "HR: Productivity"
        case .hrPhysicalHealth: return "HR: Physical Health"
        case .hrMentalHealth: return "HR: Mental Health"
        case .engineeringSoftwareDesign: return "Engineering: Software Design"
        case .engineeringSoftwareDev: return "Engineering: Software Dev"
        case .engineeringHardware: return "Engineering: Hardware"
        case .engineeringCSAndAI: return "Engineering: CS and AI"
        case .engineeringCivil: return "Engineering: Civil"
        case .engineeringMechanical: return "Engineering: Mechanical"
        case .engineeringAirNSpace: return "Engineering: Air & Space"
        case .engineeringMaterials: return "Engineering: Materials"
        case .engineeringRND: return "Engineering: R&D"
        case .engineeringOther: return "Engineering: Other"
        case .smNetworking: return "Sales & Marketing: Networking"
        case .smSales: return "Sales & Marketing: Sales"
        case .smAdvertising: return "Sales & Marketing: Advertising"
        case .smBranding: return "Sales & Marketing: Branding"
        case .smComms: return "Sales & Marketing: Comms"
        case .grassrootsVirtualMeetings: return "Grassroots: Virtual Meetings"
        case .grassrootsCoordination: return "Grassroots: Coordination"
        case .grassrootsEventComms: return "Grassroots: Event Comms"
        case .eventsPlanning: return "Events: Planning"
        case .eventsLogistics: return "Events: Logistics"
        case .eventsPromotion: return "Events: Promotion"
        case .eventsIterativeEvolution: return "Events: Iterative Evolution"
        case .cantentGraphics: return "Content: Graphics"
        case .cantentImages: return "Content: Images"
        case .cantentWriting: return "Content: Writing"
        case .cantentVideoProduction: return "Content: Video Production"
        case .cantentVideoEditing: return "Content: Video Editing"
        case .financeInternal: return "Finance: Internal"
        case .financeAccounting: return "Finance: Accounting"
        case .financeMNA: return "Finance: M&A"
        case .financeDealStructures: return "Finance: Deal Structures"
        case .financeInvesting: return "Finance: Investing"
        case .financeOptimization: return "Finance: Optimization"
        case .financeIncentiveStructures: return "Finance: Incentive Structures"
        case .spiritualPrinciples: return "Spiritual: Principles"
        case .spiritualCollaboration: return "Spiritual: Collaboration"
        case .spiritualLeadership: return "Spiritual: Leadership"
        case .managementOptimization: return "Management: Optimization"
        case .other: return "Other: Other"
        }
    }
}

// MARK: - RepSkillsModel + Identifiable -

extension RepSkillsModel: Identifiable {
    var id: String {
        self.rawValue
    }
}

// MARK: - RepSkillsModel + CaseIterable -

extension RepSkillsModel: CaseIterable {}


