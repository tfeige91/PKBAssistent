//
//  RecordingsView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 16.06.23.
//

import SwiftUI
import CoreData

struct DoctorsView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity:Session.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Session.date, ascending: true)],
        animation: .default)
    var sessions: FetchedResults<Session>
    
    var filteredSessions: [Session] {
        return sessions.filter {session in
            return session.recordedItemsArray.contains(where: {$0.rating > 2}) 
        }
    }
    
    var recordingsFromLast14Days: [UPDRSRecordedItem] {
        let fourteenDaysAgo: Date = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let filteredSession = sessions.filter { $0.date ?? Date() >= fourteenDaysAgo }
        return filteredSession.flatMap { session in
            session.recordedItemsArray
        }
    }
    
    var recordings: [UPDRSRecordedItem] {
        sessions.flatMap {$0.recordedItemsArray}
    }
    
    var morningRecordings: [(name: String, data: [UPDRSRecordedItem])] {
        let filtered = recordings.filter { item in
            item.daytime == .morning
        }
        
        return UPDRSItemName.allCases.map { itemName in
            (name: itemName.rawValue, data: filtered.filter {$0.wrappedName == itemName.rawValue})
        }
    }
    
    var afternoonRecordings: [(name: String, data: [UPDRSRecordedItem])] {
        let filtered = recordings.filter { item in
            item.daytime == .afternoon
        }
        return UPDRSItemName.allCases.map { itemName in
            (name: itemName.rawValue, data: filtered.filter {$0.wrappedName == itemName.rawValue})
        }
    }
    var eveningRecordings: [(name: String, data: [UPDRSRecordedItem])] {
        let filtered = recordings.filter { item in
            item.daytime == .evening
        }
        return UPDRSItemName.allCases.map { itemName in
            (name: itemName.rawValue, data: filtered.filter {$0.wrappedName == itemName.rawValue})
        }
    }
    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Verlaufsübersicht")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                
                CDLineChartView(title: "Vormittags", data: morningRecordings)
                CDLineChartView(title: "Nachmittags", data: afternoonRecordings)
                CDLineChartView(title: "Abends", data: eveningRecordings)
                
                Text("Markierte Aufnahmen")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                
                ForEach(filteredSessions) { session in
                    DisclosureGroup(content: {
                        ScrollView(.horizontal, showsIndicators: false){
                            HStack {
                                ForEach(session.recordedItemsArray) {item in
                                    if item.rating > 2 {
                                        SingleItemView(recoredItem: item)
                                    }
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
            .padding()
            
        }
        
    }
}

extension DoctorsView {
//    private func addPreviewData() {
//        for x
//        
//        let session = Session(context: viewContext)
//        session.id =
//        session.date
//    }
    
    private func save() {
        do {
            try viewContext.save()
        }catch {
            print("Error saving")
        }
    }
}

struct DoctorsView_Preview: PreviewProvider {
    static func makePreviewContainer() -> NSPersistentContainer{
        let container = NSPersistentContainer(name:"Model")
        let storeDescription = NSPersistentStoreDescription()
        storeDescription.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions = [storeDescription]
        
        container.loadPersistentStores {(_,error) in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }
        
        let context = container.viewContext
        
        let datetimes: [Daytime] = [.morning, .afternoon, .evening]
        //create 14 days
        for i in 1...14 {
            
            let baseDate = Date().addingTimeInterval(-Double(i) * 86400)
            var components = Calendar.current.dateComponents([.year, .month, .day], from: baseDate)
            
            //create 3 sessions per day
            for j in 0...2 {
                let daytime = datetimes[j]
                // Über den Calendar Komponenten (Jahr/Monat/Tag) holen
                if daytime == .morning {
                    components.hour = 10
                }else if daytime == .afternoon {
                    components.hour = 14
                }else if daytime == .evening {
                    components.hour = 20
                }
                let date = Calendar.current.date(from: components)!
                print(date)
                let session = Session(context: context)
                session.id = Int16((i - 1)*3 + (j + 1))
                session.url = ""
                session.date = date
                print("SESSION")
                print(session)
                //create all items per session by iterating over the UPDRSRecordingItems
                for updrsItem in UPDRSData.ViewModelUPDRSItems {
                    let rating = Int.random(in: 0...4)
                    let item = UPDRSRecordedItem(context: context)
                    item.session = session
                    item.date = date
                    item.rating = Int16(rating)
                    item.videoURL = URL(string: "https://www.youtube.com/watch?v=Q1QuYGLaGr8")
                    item.name = updrsItem.itemName
                    item.side = updrsItem.side
                    item.orderNumber = Int16(updrsItem.orderNumber)
                    print(item)
                    
                }
                
            }
            do {
                try context.save()
            } catch {
                print("something went wrong")
                fatalError("Failed to save mock data: \(error)")
            }
            
            
        }
        return container
    }
    static var previews: some View {
            DoctorsView()
            .environment(\.managedObjectContext, makePreviewContainer().viewContext)
        
    }
}

