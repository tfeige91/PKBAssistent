//
//  ChartTest.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 21.08.23.
//

import SwiftUI
import Charts

struct Workout: Identifiable, Hashable {
    var id = UUID()
    var day: String
    var minutes: Int
}

extension Workout {
    static var walkData: [Workout] {
        [
            .init(day: "Mon", minutes: 23),
            .init(day: "Tue", minutes: 45),
            .init(day: "Wed", minutes: 76),
            .init(day: "Thu", minutes: 21),
            .init(day: "Fri", minutes: 15),
            .init(day: "Sat", minutes: 35),
            .init(day: "Sun", minutes: 10)
        ]
    }
}

struct ChartTest: View {
    @State private var data = Workout.walkData
        @State private var showSelectionBar = false
        @State private var offsetX = 0.0
        @State private var offsetY = 0.0
        @State private var selectedDay = ""
        @State private var selectedMins = 0
        
        var body: some View {
            NavigationStack {
                VStack {
                    Chart(data) {
                        BarMark(
                            x: .value("Day", $0.day),
                            y: .value("Minutes", $0.minutes)
                        )
                    }
                    .frame(height: 400)
                    .chartOverlay { pr in
                        GeometryReader { geoProxy in
                            Rectangle().foregroundStyle(Color.orange.gradient)
                                .frame(width: 2, height: geoProxy.size.height * 0.95)
                                .opacity(showSelectionBar ? 1.0 : 0.0)
                                .offset(x: offsetX)
                            
                            Capsule()
                                .foregroundStyle(.orange.gradient)
                                .frame(width: 100, height: 50)
                                .overlay {
                                    VStack {
                                        Text("\(selectedDay)")
                                        Text("\(selectedMins) mins")
                                            .font(.title2)
                                    }
                                    .foregroundStyle(.white.gradient)
                                }
                                .opacity(showSelectionBar ? 1.0 : 0.0)
                                .offset(x: offsetX - 50, y: offsetY - 50)
                            
                            Rectangle().fill(.clear).contentShape(Rectangle())
                                .gesture(DragGesture().onChanged { value in
                                    if !showSelectionBar {
                                        showSelectionBar = true
                                    }
                                    let origin = geoProxy[pr.plotAreaFrame].origin
                                    let location = CGPoint(
                                        x: value.location.x - origin.x,
                                        y: value.location.y - origin.y
                                    )
                                    offsetX = location.x
                                    offsetY = location.y
                                    
                                    let (day, _) = pr.value(at: location, as: (String, Int).self) ?? ("-", 0)
                                    let mins = Workout.walkData.first { w in
                                        w.day.lowercased() == day.lowercased()
                                    }?.minutes ?? 0
                                    selectedDay = day
                                    selectedMins = mins
                                }
                                .onEnded({ _ in
                                    showSelectionBar = false
                                }))
                        }
                    }
                    .padding()
                }
                .navigationTitle("DevTechie")
            }
        }
}

struct ChartTest_Previews: PreviewProvider {
    static var previews: some View {
        ChartTest()
    }
}
