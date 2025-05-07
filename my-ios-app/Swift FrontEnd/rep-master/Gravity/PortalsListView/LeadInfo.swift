//
//  PortalsListView.swift
//  Rep 
//
//  Created by Dmytro Holovko on 28.10.2023.
//

import SwiftUI

struct LeadInfo: View {
    var lead: LeadModel
    var portals: [PortalModel]
    
    @State private var favoriteColor = 0
    
    init(
        lead: LeadModel,
        portals: [PortalModel]
    ) {
        self.lead = lead
        self.portals = portals
    }
    
    var body: some View {
        VStack {
            VStack {
                LeadInfoHeader(lead: lead)
                Picker("", selection: $favoriteColor) {
                    Text("Rep").tag(0)
                    Text("Goals").tag(1)
                    Text("Feed").tag(2)
                }
            }
            .padding(.horizontal)
            .pickerStyle(.segmented)
            .allowsHitTesting(false)
            PortalList(portals: portals)
           
        }
        .padding(.top)
        .navigationTitle(lead.firstName + " " + lead.lastName)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                ToolBar {}
            }
        }
    }
}

struct PortalList: View {
    var portals: [PortalModel]
    
    var body: some View {
        List {
            ForEach(portals) { portal in
                VStack {
                    NavigationLink {
                        PortalPage(viewModel: .init(portal: portal))
                    } label: {
                        PortalListItem(portal: portal)
                    }
                    Divider()
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        LeadInfo(
            lead: .init(id: "1", firstName: "Mukundh", lastName: "Pandian", imageName: "leadPic", city: "LA", repType: "Lead", additionalInfo: "1. Human Resources - Scale\n2. Operations - Manufacturing\n3. Sales - Social Connector"),
            portals: portals)
    }
}










