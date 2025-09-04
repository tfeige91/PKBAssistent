//
//  LineChartView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 17.08.23.
//

import SwiftUI
import Charts
//import Algorithms

enum Daytime: String, CaseIterable  {
    case morning
    case afternoon
    case evening
}

private struct LatestKey: Hashable {
    let day: Date          // startOfDay
    let slot: Daytime      // aus getTimeOfDay()
    let itemName: String
    let sideRaw: String
}

extension Sequence where Element == UPDRSRecordedItem {
    func keepLatestPerDaySlot(itemName: String, sideRaw: String) -> [UPDRSRecordedItem] {
        var best: [LatestKey: UPDRSRecordedItem] = [:]
        let cal = Calendar.current
        
        for it in self {
            let key = LatestKey(
                day: cal.startOfDay(for: it.wrappedDate),
                slot: it.wrappedDate.getTimeOfDay(),
                itemName: itemName,
                sideRaw: sideRaw
            )
            if let old = best[key] {
                if it.wrappedDate > old.wrappedDate { best[key] = it }
            } else {
                best[key] = it
            }
        }
        return best.values.sorted { $0.wrappedDate < $1.wrappedDate }
    }
}


extension Date {
    func getTimeOfDay() -> Daytime {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: self)
        let minute = calendar.component(.minute, from: self)
        
        switch hour {
        case 0..<4:
            return .evening
        case 4:
            if minute < 30 {
                return .evening
            } else {
                return .morning
            }
        case 5...10:
            return .morning
        case 11...16:
            return .afternoon
        default:
            return .evening
        }
    }
    
    func monthAndDay() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd. MMM"
        return dateFormatter.string(from: self)
    }
}

struct MockChartData: Identifiable {
    let name: UPDRSItemName
    let rating: Int
    let date: Date
    let daytime: Daytime
    let side: String
    var id: String { "\(name)"+side}
    
    init(date: String, itemname: UPDRSItemName, rating: Int, side: String){
        
        self.name = itemname
        self.rating = rating
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        let correctDate = dateFormatter.date(from: date) ?? .now
        self.date = correctDate
        self.daytime = correctDate.getTimeOfDay()
        self.side = side
    }
    
    init(date:Date, daytime: Daytime, itemname: String, rating: Int, side: Side) {
        self.name = UPDRSItemName(rawValue: itemname) ?? .Fingertap
        self.rating = rating
        self.date = date
        self.daytime = daytime
        self.side = side.rawValue
    }
    
    static var demoData: [MockChartData] {
        let datetimes: [Daytime] = [.morning, .afternoon, .evening]
        var data: [MockChartData] = []
        //create 14 days
        for i in 1...14 {
            let date = Date().addingTimeInterval(-Double(i) * 86400)
            //create 3 sessions per day
            for j in 0...2 {
                let daytime = datetimes[j]
                let rating = Int.random(in: 0...4)
                //create all items per session by iterating over the UPDRSRecordingItems
                for updrsItem in UPDRSData.ViewModelUPDRSItems {
                    let item = MockChartData(date: date,daytime: daytime, itemname: updrsItem.itemName, rating: rating, side: updrsItem.side)
                    data.append(item)
                }
               
            }

        }
        print("DEBUG: MockChartData.demoData \(data)")
        //create all items per session
        return data
    }
        
//        MockChartData(date: "01-08-2023 14:14", itemname: .Fingertap, rating: 2,side: Side.left.rawValue),
//        MockChartData(date: "01-08-2023 14:14", itemname: .RestingTremor, rating: 3),
//        MockChartData(date: "01-08-2023 14:14", itemname: .PronationSupination, rating: 2),
//        MockChartData(date: "01-08-2023 14:14", itemname: .Walking, rating: 4),
//        MockChartData(date: "02-08-2023 14:14", itemname: .Fingertap, rating: 1),
//        MockChartData(date: "02-08-2023 14:14", itemname: .RestingTremor, rating: 3),
//        MockChartData(date: "02-08-2023 14:14", itemname: .PronationSupination, rating: 4),
//        MockChartData(date: "02-08-2023 14:14", itemname: .Walking, rating: 3),
//        MockChartData(date: "03-08-2023 14:14", itemname: .Fingertap, rating: 1),
//        MockChartData(date: "03-08-2023 14:14", itemname: .RestingTremor, rating: 2),
//        MockChartData(date: "03-08-2023 14:14", itemname: .PronationSupination, rating: 3),
//        MockChartData(date: "03-08-2023 14:14", itemname: .Walking, rating: 2),
//        MockChartData(date: "04-08-2023 14:14", itemname: .Fingertap, rating: 1),
//        MockChartData(date: "04-08-2023 14:14", itemname: .RestingTremor, rating: 2),
//        MockChartData(date: "04-08-2023 14:14", itemname: .PronationSupination, rating: 3),
//        MockChartData(date: "04-08-2023 14:14", itemname: .Walking, rating: 4),
//        MockChartData(date: "05-08-2023 14:14", itemname: .Fingertap, rating: 1),
//        MockChartData(date: "05-08-2023 14:14", itemname: .RestingTremor, rating: 2),
//        MockChartData(date: "05-08-2023 14:14", itemname: .PronationSupination, rating: 3),
//        MockChartData(date: "05-08-2023 14:14", itemname: .Walking, rating: 3),
//        MockChartData(date: "06-08-2023 14:14", itemname: .Fingertap, rating: 3),
//        MockChartData(date: "06-08-2023 14:14", itemname: .RestingTremor, rating: 2),
//        MockChartData(date: "06-08-2023 14:14", itemname: .PronationSupination, rating: 4),
//        MockChartData(date: "06-08-2023 14:14", itemname: .Walking, rating: 2),
//    ]
    
    static var chunkedDemoData_r: [(name: String, data: [MockChartData])] = UPDRSItemName.allCases.map { itemName in
        (name: itemName.rawValue, data: MockChartData.demoData.filter {$0.name == itemName && $0.side == Side.right.rawValue && $0.daytime == .afternoon})
    }
    static var chunkedDemoData_l: [(name: String, data: [MockChartData])] = UPDRSItemName.allCases.map { itemName in
        (name: itemName.rawValue, data: MockChartData.demoData.filter {$0.name == itemName && $0.side == Side.left.rawValue && $0.daytime == .afternoon})
    }
    
}

struct LineChartView: View {
    
    @State private var showSelectionBar = false
    @State private var offsetX = 0.0
    @State private var offsetY = 0.0
    @State private var selectedDate: String?
    
    
    var body: some View {
        VStack{
            GroupBox("Nachmittags"){
                Chart {
                    ForEach(MockChartData.chunkedDemoData_r, id: \.name){series in
                        let seriesName = "r_" + series.name
                        ForEach(series.data) {item in
                            
                            LineMark(x: .value("Datum",item.date.monthAndDay()),
                                     y: .value("Einschätzung",item.rating))
                        }
                        
                        .foregroundStyle(by: .value("Item",seriesName))
                        .symbol(by: .value("Item", seriesName))
                        .interpolationMethod(.linear)
                    }
                    ForEach(MockChartData.chunkedDemoData_l, id: \.name){series in
                        let seriesName = "l_" + series.name
                        ForEach(series.data) {item in
                            
                            LineMark(x: .value("Datum",item.date.monthAndDay()),
                                     y: .value("Einschätzung",item.rating))
                        }
                        
                        .foregroundStyle(by: .value("Item",seriesName))
                        .symbol(by: .value("Item", seriesName))
                        .interpolationMethod(.linear)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    }
                    if let selectedDate {
                        RectangleMark(x: .value("Datum", selectedDate),width:MarkDimension.ratio(1))
                            .foregroundStyle(.primary.opacity(0.1))
                            .annotation(
                                position: .leading,
                                alignment: .center, spacing: 0
                            ) {
                                ChartAnnotationView(
                                    //data: MockChartData.chunkedDemoData,
                                    date: selectedDate
                                )
                            }
                            .accessibilityHidden(true)
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(.gray.opacity(0.1))
                }
                .frame(height: 300)
                .padding()
                .chartOverlay { chartProxy in
                    GeometryReader { geoProxy in
                        
                        
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(DragGesture().onChanged { value in
                                if !showSelectionBar {
                                    showSelectionBar = true
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
                                
                            }
                                .onEnded({ _ in
                                    showSelectionBar = false
                                }))
                    }
                }
                
            }
        }
        .onAppear{
            print("DEBUG: MockChartData.demoData \(MockChartData.demoData)")
        }
    }
}

struct ChartAnnotationView: View {
    let data = MockChartData.demoData
    let date: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(date)
                .font(.headline)
            Divider()
            ForEach(data.filter({ data in
                data.date.monthAndDay() == date
            })) { data in
                let name = data.name.rawValue
                let value = data.rating
                Text(name + ": \(value)")
            }
        }
        .padding()
        .background(Color.annotationBackground)
    }
}

struct LineChartView_Previews: PreviewProvider {
    static var previews: some View {
        LineChartView()
    }
}
