//
//  SingleEventSurveysView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 08.01.25.
//

import SwiftUI

struct SingleEventSurveysView: View {
    let event: Event
    let NavigationText: String
    let introText: String
    @State private var surveys: [SurveyStatusCellModel] = []

    
    var body: some View {
        VStack{
            Spacer()
                .frame(height:16)
            if surveys.count > 0 {
                Text(introText)
                    .font(.headline)
            }
            ForEach(surveys) {survey in
                SurveyStatusCellView(survey: survey)
                //Text(survey.surveyName)
            }
            Spacer()
            
        }
        .onAppear() {
            if let userGroupValue = UserDefaults.standard.string(forKey: "userGroup"),
               let recordID = UserDefaults.standard.string(forKey: "RecordID"),
               let userGroup = UserGroup(rawValue: userGroupValue){
                Task{
                    surveys = try await RedCapAPIService.instance.fetchSurveyStatus(for: recordID, event: event, arm: userGroup)
                    
                }
            }
            
            
        }
        
    }
}

//          
//#Preview {
//    let event = Event(eventName: "Baseline", armNumber: 2, uniqueEventName: "baseline_arm_2", customEventLabel: "baseline", eventID: 1540)
//    // Provide a default value for the @AppStorage key
//    let previewUserDefaults: UserDefaults = {
//        let d = UserDefaults(suiteName: "preview_user_defaults")!
//        d.set("control", forKey: "userGroup")
//        d.set("146", forKey: "RecordID")
//        return d
//    }()
//
//    NavigationStack{
//        SingleEventSurveysView(event: event,
//                               NavigationText: "Eingangsfragebögen",
//                               introText: "Bitte Füllen Sie diese Fragebögen vor Ihrer Parkinson-Komplexbehandlung aus.")
//        //
//        //            .onAppear() {
//        //                PreviewUserDefaults.previewUserDefaults.set("control", forKey: "userGroup")
//        //                PreviewUserDefaults.previewUserDefaults.set("146", forKey: "RecordID")
//        //            }
//    }
//    .defaultAppStorage(PreviewUserDefaults.previewUserDefaults)
//
//}
