//
//  RCEventsOverview.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 07.01.25.
//

import SwiftUI

//Use this View if you know which event you want to display.

struct RCManualEventView: View {
    let eventName: String
    let eventDisplayName: String
    let shortDescription: String
    let detailViewNavigationText: String
    let detailViewIntroText: String
    @AppStorage("userGroup") var userGroup: String?
    var studyArm: Int{
        if userGroup == UserGroup.intervention.rawValue{
            1
        }else {
            2
        }
    }
    
    @State private var redCapEvents: [Event] = []
    
    var body: some View {
        
            List {
                ForEach(redCapEvents.filter{$0.customEventLabel == eventName},id: \.uniqueEventName){event in
                    HStack{
                        VStack(alignment: .leading){
                            NavigationLink {
                                SingleEventSurveysView(event: event, NavigationText: detailViewNavigationText, introText: detailViewIntroText)
                            } label: {
                                Text(eventDisplayName)
                                    .font(.title)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            Text(shortDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .onAppear(){
                                    print(event)
                                }
                        }
                        
                        

                    }
                    .overlay(
                                Rectangle()
                                    .frame(height: 1) // Border thickness
                                    .foregroundColor(.gray), // Border color
                                alignment: .bottom // Align the border to the bottom
                            )
                }
            }
            .frame(height: 160)
        //.scrollContentBackground(.hidden)
        .padding(.horizontal,30)
        .onAppear{
            if let userGroup = UserGroup(rawValue: userGroup!){
                Task {
                    redCapEvents = try await RedCapAPIService.instance.getEventsForStudyArm(arm: userGroup)
                   
                }
                
            }
        }
    }
}



#Preview {
    // Provide a default value for the @AppStorage key
    let previewUserDefaults: UserDefaults = {
        let d = UserDefaults(suiteName: "preview_user_defaults")!
        return d
    }()
    
    NavigationStack {
        RCManualEventView(eventName: "pkb",
                         eventDisplayName: "Eingangsfragebögen",
                         shortDescription: "Bitte füllen Sie diese Fragebögen bis zu Ihrer Parkinson Komplexbehandlung aus",
                         detailViewNavigationText: "Eingangsfragebögen",
                         detailViewIntroText: "Bitte führen Sie diese Fragebögen bis zu Ihrer Parkinson Komplexbehandlung aus")
        
        .onAppear() {
            PreviewUserDefaults.previewUserDefaults.set("control", forKey: "userGroup")
            PreviewUserDefaults.previewUserDefaults.set("146", forKey: "RecordID")
        }
    }
    .defaultAppStorage(PreviewUserDefaults.previewUserDefaults)
}
