//  RepSkillsModel.swift
//  Rep
//
//  Created by Dmytro Holovko on 10.12.2023.
//

import Foundation

enum RepSkillsModel: String, CaseIterable, Identifiable, Codable {
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

    // MARK: - Identifiable
    var id: String { self.rawValue }

    // MARK: - CustomStringConvertible
    static var title: String { "Rep Skills" }
    var description: String { self.rawValue }
}
