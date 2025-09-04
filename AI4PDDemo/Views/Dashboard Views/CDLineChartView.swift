//
//  LineChartView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 17.08.23.
//

import SwiftUI
import Charts
import CoreData
import AVKit

struct CDLineChartView: View {
    
    @State private var selectedTasks: Set<String> = []   // Task-Namen, z. B. "Ruhetremor"
    @State private var selectedSides: Set<Side> = []     // .left, .right, .none
    
    let domain: [String] = UPDRSItemName.allCases.map { $0.rawValue }
    let range:  [Color]  = UPDRSItemName.allCases.enumerated().map { i, _ in
        AppConstants.lineChartColors[i]
    }

    let title: String
    let data: [(name: String, data: [UPDRSRecordedItem])]
    var left_data: [(name: String,id:String,side:Side, data: [UPDRSRecordedItem])] {
        data.map { (name, items) in
            let sideRaw = Side.left.rawValue
            return (name, name + "left", .left,
                    items.filter { $0.sideRaw == sideRaw }
                         .keepLatestPerDaySlot(itemName: name, sideRaw: sideRaw))
        }
    }

    var right_data: [(name: String,id:String,side:Side, data: [UPDRSRecordedItem])] {
        data.map { (name, items) in
            let sideRaw = Side.right.rawValue
            return (name, name + "right", .right,
                    items.filter { $0.sideRaw == sideRaw }
                         .keepLatestPerDaySlot(itemName: name, sideRaw: sideRaw))
        }
    }

    var global_data: [(name: String,id:String,side:Side, data: [UPDRSRecordedItem])] {
        data.map { (name, items) in
            let sideRaw = Side.none.rawValue
            return (name, name + "none", .none,
                    items.filter { $0.sideRaw == sideRaw }
                         .keepLatestPerDaySlot(itemName: name, sideRaw: sideRaw))
        }
    }
    var combinedData: [(name: String, id: String, side: Side, data: [UPDRSRecordedItem])] {
        (left_data + right_data + global_data).map { series in
            let sortedItems = series.data.sorted { $0.wrappedDate < $1.wrappedDate}
            return (series.name, series.id, series.side, sortedItems)
        }
    }
    
    var filteredData: [(name: String, id: String, side: Side, data: [UPDRSRecordedItem])] {
        combinedData.filter { series in
            let taskOK = selectedTasks.isEmpty || selectedTasks.contains(series.name)
            let sideOK = selectedSides.isEmpty || selectedSides.contains(series.side)
            return taskOK && sideOK
        }
    }
    
    private var xDomainStrings: [String] {
        let cal = Calendar.current
        // alle Tage aus allen Serien holen
        let days = filteredData
            .flatMap { $0.data }
            .map { cal.startOfDay(for: $0.wrappedDate) }
        
        // eindeutig + sortiert
        let uniqueSortedDays = Array(Set(days)).sorted()
        return uniqueSortedDays.map { $0.monthAndDay() }
    }
    
   

    
    @State private var showSelectionBar = false
    @State private var offsetX = 0.0
    @State private var offsetY = 0.0
    @State private var selectedDate_: Date?
    @State private var selectedDate: String?
    var colorDict: [UPDRSItemName: Color] {
        var colorDict: [UPDRSItemName: Color] = [:]
        for (i, itemName) in UPDRSItemName.allCases.enumerated() {
            colorDict[itemName] = AppConstants.lineChartColors[i]
        }
        return colorDict
    }
    
    var body: some View {
        VStack{
            GroupBox(title){
                Chart {
                    
                    ForEach(filteredData, id: \.id) { series in
                        
                        
                        let updrsItemName = UPDRSItemName(rawValue: series.name)
                        // Farbe aus colorDict oder Fallback-Farbe
                        let color = updrsItemName.flatMap { colorDict[$0] } ?? .gray
                        ForEach(series.data, id: \.objectID) { item in
                            LineMark(
                                x: .value("Datum", item.wrappedDate.monthAndDay()),
                                y: .value("Einschätzung", item.rating)
                            )
                        }
                        .foregroundStyle(by: .value("Item", series.name))
                        .lineStyle(by: .value("Item",series.side.rawValue))
                        
                        .interpolationMethod(.linear)
                        // Durchgezogene Linie für rechts
                    }
                    //
                    
                    //                    ForEach(left_data, id: \.id){(series: (name: String,id:String, data: [UPDRSRecordedItem])) in
                    //                        // name -> UPDRSItemName
                    //                                let updrsItemName = UPDRSItemName(rawValue: series.name)
                    //                                // Farbe aus colorDict oder Fallback-Farbe
                    //                        let color = updrsItemName.flatMap { colorDict[$0] } ?? .gray
                    //
                    //
                    //
                    //                        ForEach(series.data) {(item:UPDRSRecordedItem) in
                    //
                    //                            LineMark(x: .value("Datum",item.wrappedDate.monthAndDay()),
                    //                                     y: .value("Einschätzung",item.rating))
                    //                            .foregroundStyle(color) // Nur die Farbe direkt anwenden
                    //
                    //
                    //                        }
                    //
                    //                        .symbol(by: .value("Item", series.name))
                    //                        .interpolationMethod(.linear)
                    //                    }
                    //
                    //                    ForEach(right_data, id: \.id){(series: (name: String,id:String, data: [UPDRSRecordedItem])) in
                    //                        // name -> UPDRSItemName
                    //                                let updrsItemName = UPDRSItemName(rawValue: series.name)
                    //                                // Farbe aus colorDict oder Fallback-Farbe
                    //                        let color = updrsItemName.flatMap { colorDict[$0] } ?? .gray
                    //
                    //
                    //
                    //                        ForEach(series.data) {(item:UPDRSRecordedItem) in
                    //
                    //                            LineMark(x: .value("Datum",item.wrappedDate.monthAndDay()),
                    //                                     y: .value("Einschätzung",item.rating))
                    //                            .foregroundStyle(color) // Nur die Farbe direkt anwenden
                    //
                    //
                    //                        }
                    //                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    //                        .symbol(by: .value("Item", series.name))
                    //                        .interpolationMethod(.linear)
                    //                    }
                    
                    
                    
                    
                    if let selectedDate,showSelectionBar {
                        RectangleMark(x: .value("Datum", selectedDate),width:MarkDimension.ratio(1))
                            .foregroundStyle(.primary.opacity(0.1))
                        //                            .annotation(
                        //                                position: .leading,
                        //                                alignment: .center, spacing: 0
                        //                            ) {
                        //                                CDChartAnnotationView(
                        //                                    data: self.data.flatMap{$0.data},
                        //                                    date: selectedDate
                        //                                )
                        //                            }
                        //                            .accessibilityHidden(true)
                    }
                }
                .chartLegend(position: .bottom)
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(.gray.opacity(0.1))
                }
                .chartForegroundStyleScale(domain: domain, range: range)
                .chartXScale(domain: xDomainStrings)
                .chartYScale(domain: 0...4)
                .frame(height: 300)
                .padding()
                .chartOverlay { chartProxy in
                    // true, wenn es überhaupt Punkte gibt
                        let hasPoints = filteredData.contains { !$0.data.isEmpty }
                        if !hasPoints {
                            Color.clear   // oder EmptyView()
                        } else {
                        GeometryReader { geoProxy in
                            
                            
                            Rectangle().fill(.clear).contentShape(Rectangle())
                                .simultaneousGesture(DragGesture(minimumDistance: 10).onChanged { value in
                                    withAnimation {
                                        if !showSelectionBar {
                                            showSelectionBar = true
                                        }
                                    }
                                    
                                    let origin = geoProxy[chartProxy.plotAreaFrame].origin
                                    let location = CGPoint(
                                        x: value.location.x - origin.x,
                                        y: value.location.y - origin.y
                                    )
                                    offsetX = location.x
                                    offsetY = location.y
                                    let dateString = chartProxy.value(
                                        atX: location.x, as: String.self)
                                    selectedDate = dateString
                                    print(String(describing: dateString))
                                    
                                })
                                .simultaneousGesture(
                                    TapGesture()
                                        .onEnded{withAnimation {
                                            showSelectionBar = false
                                        }
                                            // Hier kannst du z. B. ausblenden
                                            
                                            // selectedDate = nil
                                        }
                                )
                        }
                    }
                }
                if let selectedDate, showSelectionBar {
                    CDChartAnnotationView(
                        data: self.combinedData.flatMap { $0.data },
                        date: selectedDate
                    )
                    // Bei Bedarf Stil/Größe/Position anpassen
                    .padding()
                    .transition(.move(edge: .bottom))  // animiertes Ein-/Ausblenden
                }
            }
            .overlay(alignment: .topTrailing) {
                Menu {
                    // Tasks
                    Section("Tasks") {
                        ForEach(Set(combinedData.map { $0.name }).sorted(), id: \.self) { task in
                            Button {
                                if selectedTasks.contains(task) {
                                    selectedTasks.remove(task)
                                } else {
                                    selectedTasks.insert(task)
                                }
                            } label: {
                                Label(task,
                                      systemImage: selectedTasks.contains(task) ? "checkmark" : "")
                            }
                        }
                    }
                    
                    // Seiten
                    Section("Seite") {
                        ForEach([Side.left, Side.right, Side.none], id: \.self) { side in
                            Button {
                                if selectedSides.contains(side) {
                                    selectedSides.remove(side)
                                } else {
                                    selectedSides.insert(side)
                                }
                            } label: {
                                Label(side.rawValue.capitalized,
                                      systemImage: selectedSides.contains(side) ? "checkmark" : "")
                            }
                        }
                    }
                    
                    // Reset
                    Section {
                        Button("Alle zurücksetzen") {
                            selectedTasks.removeAll()
                            selectedSides.removeAll()
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .padding(8)
                }
            }
        }
    }
}

struct CDChartAnnotationView: View {
    
    let data: [UPDRSRecordedItem]
    let date: String
    
    
    var globalItems: [UPDRSRecordedItem] {
        data.filter { item in
            item.side == .none && item.wrappedDate.monthAndDay() == date
        }.sorted {$0.orderNumber < $1.orderNumber}
    }
    
    var leftItems: [UPDRSRecordedItem] {
        data.filter { item in
            item.side == .left && item.wrappedDate.monthAndDay() == date
        }.sorted {$0.orderNumber < $1.orderNumber}
    }
    var rightItems: [UPDRSRecordedItem] {
        data.filter { item in
            item.side == .right && item.wrappedDate.monthAndDay() == date
        }.sorted {$0.orderNumber < $1.orderNumber}
    }
    
    @State private var showPlayer = false
    @State private var player: AVPlayer?
    @State private var previewImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(globalItems.first?.wrappedDate.monthAndDay() ?? "Keine Daten für diesen Tag")
                .font(.headline)
            Divider()
            Text("Global")
                .font(.headline)
            ForEach(globalItems, id: \.objectID) { data in
                let name = data.prettyItemName
                let value = data.rating
                HStack {
                    Text(name + ": ")
                        .frame(width: 200, alignment: .leading)
                    Text("\(value)")
                    
                    Button {
                        Task {
                            do {
                                guard let url = data.videoURL else {
                                    print("no valid URL")
                                    return
                                }
                                
                                let documentURL = VideoFileManager.instance.documentsDirectory
                                let fileURL = documentURL.appendingPathComponent(url.path())
                                print("DEBUG SESSION URL: url to show in player:", fileURL)
                                player = AVPlayer(url: fileURL)
                                
                                previewImage = try await previewImageFromVideo(url: fileURL)
                            } catch {
                                print("failed loading the previewImage")
                            }
                            self.showPlayer.toggle()
                        }
                    } label: {
                        Text("Play")
                    }
                }
            }
            HStack{
                VStack(alignment: .leading){
                    Text("Links")
                        .font(.headline)
                    ForEach(leftItems, id: \.objectID){ data in
                        let name = data.prettyItemName
                        let value = data.rating
                        HStack {
                            Text(name + ": ")
                                .frame(width: 200, alignment: .leading)
                            Text("\(value)")
                            
                            Button {
                                Task {
                                    do {
                                        guard let url = data.videoURL else {
                                            print("no valid URL")
                                            return
                                        }
                                        
                                        let documentURL = VideoFileManager.instance.documentsDirectory
                                        let fileURL = documentURL.appendingPathComponent(url.path())
                                        print("DEBUG SESSION URL: url to show in player:", fileURL)
                                        player = AVPlayer(url: fileURL)
                                        
                                        previewImage = try await previewImageFromVideo(url: fileURL)
                                    } catch {
                                        print("failed loading the previewImage")
                                    }
                                    self.showPlayer.toggle()
                                }
                            } label: {
                                Text("Play")
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading){
                    Text("Rechts")
                        .font(.headline)
                    ForEach(rightItems, id: \.objectID){ data in
                        let name = data.prettyItemName
                        let value = data.rating
                        HStack {
                            Text(name + ": ")
                                .frame(width: 200, alignment: .leading)
                            Text("\(value)")
                            
                            Button {
                                Task {
                                    do {
                                        guard let url = data.videoURL else {
                                            print("no valid URL")
                                            return
                                        }

                                        let documentURL = VideoFileManager.instance.documentsDirectory
                                        let fileURL = documentURL.appendingPathComponent(url.path())
                                        print("DEBUG SESSION URL: url to show in player:", fileURL)
                                        player = AVPlayer(url: fileURL)
                                        
                                        previewImage = try await previewImageFromVideo(url: url)
                                    } catch {
                                        print("failed loading the previewImage")
                                    }
                                    self.showPlayer.toggle()
                                }
                            } label: {
                                Text("Play")
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .frame(minHeight:600)
        .overlay(content: {
            if showPlayer {
                ZStack{
                    if let player = player {
                        ZStack {
                            VStack{
                                HStack{
                                    Spacer()
                                    Button(action: {
                                        self.showPlayer.toggle()
                                        player.pause()
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .resizable()
                                            .foregroundColor(.black)
                                            .frame(width: 40, height: 40)
                                    }
                                }
                                .padding()
                                Spacer()
                            }
                            
                            VideoPlayer(player: player)
                                .frame(width: 270*1.1, height: 480*1.1)
                                .onAppear {
                                                    player.play() // Video starten, wenn der View erscheint
                                                }
                                
                            
                            
                            //                    Image(systemName: "play.circle")
                            //                        .resizable()
                            //                        .foregroundColor(.white)
                            //                        .frame(width: 50, height: 50)
                            
                        }
                    }else {
                        RoundedRectangle(cornerRadius: 15)
                    }
                }
                .frame(width: 440, height: 620)
                .background(.thickMaterial)
                .cornerRadius(20)
            }
            
        })
        .padding()
        .background(Color.annotationBackground)
    }
                                   
                                   func previewImageFromVideo(url: URL) async throws -> UIImage? {
                                       let asset = AVURLAsset(url: url)
                                       let generator =  AVAssetImageGenerator(asset: asset)
                                       generator.appliesPreferredTrackTransform = true
                                       
                                       let imageTask = Task { () -> UIImage? in
                                           var duration = try await asset.load(.duration)
                                           duration.value = min(duration.value, 22)
                                           
                                           do {
                                               let (image, _) = try await generator.image(at: CMTimeMake(value: duration.value, timescale: 30))
                                               return UIImage(cgImage: image)
                                           }catch{
                                               print("could not create VideoPreview")
                                               return nil
                                           }
                                           
                                       }
                                       
                                       return try await imageTask.value
                                   }
}

struct CDLineChartView_Previews: PreviewProvider {
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
        var counter = 0
        let numbers = Array(0...41)
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
                session.id = Int16(numbers[counter])
                counter+=1
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
                    item.videoURL = URL(string: "https://embed-ssl.wistia.com/deliveries/cc8402e8c16cc8f36d3f63bd29eb82f99f4b5f88/accudvh5jy.mp4")!
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
        @State var showDoctorsView = true
        VStack{
            if showDoctorsView {
                DoctorsView()
            }
            
        }
        .environment(\.managedObjectContext, makePreviewContainer().viewContext)
    }
}
