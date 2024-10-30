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
        case 5...11:
            return .morning
        case 12...16:
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
    let id = UUID()
    let name: UPDRSItemName
    let rating: Int
    let date: Date
    let daytime: Daytime
    
    init(date: String, itemname: UPDRSItemName, rating: Int){
        
        self.name = itemname
        self.rating = rating
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        let correctDate = dateFormatter.date(from: date) ?? .now
        self.date = correctDate
        self.daytime = correctDate.getTimeOfDay()
    }
    
    static let demoData = [
        MockChartData(date: "01-08-2023 14:14", itemname: .Fingertap, rating: 2),
        MockChartData(date: "01-08-2023 14:14", itemname: .Sitting, rating: 3),
        MockChartData(date: "01-08-2023 14:14", itemname: .PronationSupination, rating: 2),
        MockChartData(date: "01-08-2023 14:14", itemname: .Walking, rating: 4),
        MockChartData(date: "02-08-2023 14:14", itemname: .Fingertap, rating: 1),
        MockChartData(date: "02-08-2023 14:14", itemname: .Sitting, rating: 3),
        MockChartData(date: "02-08-2023 14:14", itemname: .PronationSupination, rating: 4),
        MockChartData(date: "02-08-2023 14:14", itemname: .Walking, rating: 3),
        MockChartData(date: "03-08-2023 14:14", itemname: .Fingertap, rating: 1),
        MockChartData(date: "03-08-2023 14:14", itemname: .Sitting, rating: 2),
        MockChartData(date: "03-08-2023 14:14", itemname: .PronationSupination, rating: 3),
        MockChartData(date: "03-08-2023 14:14", itemname: .Walking, rating: 2),
        MockChartData(date: "04-08-2023 14:14", itemname: .Fingertap, rating: 1),
        MockChartData(date: "04-08-2023 14:14", itemname: .Sitting, rating: 2),
        MockChartData(date: "04-08-2023 14:14", itemname: .PronationSupination, rating: 3),
        MockChartData(date: "04-08-2023 14:14", itemname: .Walking, rating: 4),
        MockChartData(date: "05-08-2023 14:14", itemname: .Fingertap, rating: 1),
        MockChartData(date: "05-08-2023 14:14", itemname: .Sitting, rating: 2),
        MockChartData(date: "05-08-2023 14:14", itemname: .PronationSupination, rating: 3),
        MockChartData(date: "05-08-2023 14:14", itemname: .Walking, rating: 3),
        MockChartData(date: "06-08-2023 14:14", itemname: .Fingertap, rating: 3),
        MockChartData(date: "06-08-2023 14:14", itemname: .Sitting, rating: 2),
        MockChartData(date: "06-08-2023 14:14", itemname: .PronationSupination, rating: 4),
        MockChartData(date: "06-08-2023 14:14", itemname: .Walking, rating: 2),
    ]
    
    static var chunkedDemoData: [(name: String, data: [MockChartData])] = UPDRSItemName.allCases.map { itemName in
        (name: itemName.rawValue, data: MockChartData.demoData.filter {$0.name == itemName})
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
                    ForEach(MockChartData.chunkedDemoData, id: \.name){series in
                        ForEach(series.data) {item in
                            
                            LineMark(x: .value("Datum",item.date.monthAndDay()),
                                     y: .value("Einschätzung",item.rating))
                        }
                        .foregroundStyle(by: .value("Item",series.name))
                        .symbol(by: .value("Item", series.name))
                        .interpolationMethod(.linear)
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
