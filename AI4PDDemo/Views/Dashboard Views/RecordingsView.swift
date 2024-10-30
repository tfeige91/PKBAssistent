//
//  RecordingsView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 16.06.23.
//

import SwiftUI
import CoreData

struct RecordingsView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Session.date, ascending: true)],animation: .default) var sessions: FetchedResults<Session>
    
   
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(sessions) { session in
                    DisclosureGroup(content: {
                        ScrollView(.horizontal, showsIndicators: false){
                            HStack(spacing:20) {
                                ForEach(session.recordedItemsArray) {item in
                                    SingleItemView(recoredItem: item)
                                        .padding()
                                }
                            }
                        }
                    },
                                    label: {
                        Text("Aufnahme \(session.id): \(session.date?.formatted(date: .long, time: .shortened) ?? "")")
                            .font(.largeTitle)
                            .frame(maxWidth: .infinity)
                            .frame(height: 70, alignment: .leading)
                            .background(.gray.opacity(0.2))
                            
                            
                    })
                }
                .frame(maxWidth: .infinity)
                
                .navigationTitle("Übersicht über alle Aufnahmen")
                
            }
            
            
        }
        
    }
}

struct RecordingsView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingsView()
    }
}
