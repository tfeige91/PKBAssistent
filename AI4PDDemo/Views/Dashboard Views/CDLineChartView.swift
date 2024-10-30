//
//  LineChartView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 17.08.23.
//

import SwiftUI
import Charts

struct CDLineChartView: View {
    let title: String
    let data: [(name: String, data: [UPDRSRecordedItem])]
    @State private var showSelectionBar = false
    @State private var offsetX = 0.0
    @State private var offsetY = 0.0
    @State private var selectedDate: String?
    
    var body: some View {
        VStack{
            GroupBox(title){
                Chart {
                    ForEach(data, id: \.name){(series: (name: String, data: [UPDRSRecordedItem])) in
                        ForEach(series.data) {(item:UPDRSRecordedItem) in
                            
                            LineMark(x: .value("Datum",item.wrappedDate.monthAndDay()),
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
                                CDChartAnnotationView(
                                    data: self.data.flatMap{$0.data},
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
                .chartYScale(domain: 0...4) 
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

struct CDChartAnnotationView: View {
    let data: [UPDRSRecordedItem]
    let date: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(date)
                .font(.headline)
            Divider()
            ForEach(data.filter({ data in
                data.wrappedDate.monthAndDay() == date
            })) { data in
                let name = data.wrappedName
                let value = data.rating
                Text(name + ": \(value)")
            }
        }
        .padding()
        .background(Color.annotationBackground)
    }
}

struct CDLineChartView_Previews: PreviewProvider {
    static var previews: some View {
        LineChartView()
    }
}
