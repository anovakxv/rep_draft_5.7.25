//
//  LoginView.swift
//  Rep 
//
//  Created by Dmytro Holovko on 04.12.2023.
//

import SwiftUI

struct GridView: View {
    @Binding var items: [ImageItem]

    @State private var isAddingPhoto = false
    @State private var isEditing = false
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: 2)
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    LazyVGrid(columns: gridColumns) {
                        ForEach(items) { item in
                            GeometryReader { geo in
                                NavigationLink(destination: ImageView(item: item)) {
                                    GridItemView(size: geo.size.width, item: item)
                                }
                            }
                            .cornerRadius(8.0)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(alignment: .topTrailing) {
                                if isEditing {
                                    Button {
                                        withAnimation {
                                            if let index = items.firstIndex(of: item) {
                                                items.remove(at: index)
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "xmark.square.fill")
                                            .font(Font.title)
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.white, .primary)
                                    }
                                    .offset(x: 7, y: -7)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitle("Graphics Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isAddingPhoto) {
                PhotoPicker(items: $items)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditing ? "Done" : "Edit") {
                        withAnimation { isEditing.toggle() }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isAddingPhoto = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(isEditing)
                }
            }
            .accentColor(.green)
        }
    }
}
