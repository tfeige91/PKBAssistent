//
//  QuestionnairesScreen.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 10.01.25.
//

import SwiftUI

struct QuestionnairesScreen: View {
    
    
    var body: some View {
        List{
            ForEach(views, id: \.id) {entry in
                entry.view
            }
        }
        .scrollContentBackground(.hidden)
    }
      
        
//            RCManualEventView(eventName: "baseline", eventDisplayName: "Eingangsfragebögen", shortDescription: "Bitte füllen Sie diese Fragebögen vor Ihrer Parkinson-Komplexbehandlung aus.", detailViewNavigationText: "Eingangsfragebögen", detailViewIntroText: "Bitte füllen Sie diese Fragebögen vor Ihrer Parkinson-Komplexbehandlung aus.")
//            RCManualEventView(eventName: "pkb", eventDisplayName: "Fragebögen für Ihren stationären Aufenthalt", shortDescription: "Bitte füllen Sie diese Fragebögen am Ende Ihrer Parkinson-Komplexbehandlung aus.", detailViewNavigationText: "Parkinson-Komplexbehandlung", detailViewIntroText: "Bitte füllen Sie diese Fragebögen am Ende Ihrer Parkinson-Komplexbehandlung aus.")
            
        
//        .navigationTitle("Fragebögen")
        
    
    
//    private var baselineView: some View {
//        RCManualEventView(eventName: "baseline", eventDisplayName: "Eingangsfragebögen", shortDescription: "Bitte füllen Sie diese Fragebögen vor Ihrer Parkinson-Komplexbehandlung aus.", detailViewNavigationText: "Eingangsfragebögen", detailViewIntroText: "Bitte füllen Sie diese Fragebögen vor Ihrer Parkinson-Komplexbehandlung aus.")
//    }
//    private var pkbView: some View {
//        RCManualEventView(eventName: "pkb", eventDisplayName: "Fragebögen für Ihren stationären Aufenthalt", shortDescription: "Bitte füllen Sie diese Fragebögen am Ende Ihrer Parkinson-Komplexbehandlung aus.", detailViewNavigationText: "Parkinson-Komplexbehandlung", detailViewIntroText: "Bitte füllen Sie diese Fragebögen am Ende Ihrer Parkinson-Komplexbehandlung aus.")
//    }
    private var views: [(id:String,view:RCManualEventView)] = [
        (id: "baseline",view: RCManualEventView(eventName: "baseline", eventDisplayName: "Eingangsfragebögen", shortDescription: "Bitte füllen Sie diese Fragebögen vor Ihrer Parkinson-Komplexbehandlung aus.", detailViewNavigationText: "Eingangsfragebögen", detailViewIntroText: "Bitte füllen Sie diese Fragebögen vor Ihrer Parkinson-Komplexbehandlung aus.")),
        (id: "pkb",view: RCManualEventView(eventName: "pkb", eventDisplayName: "Fragebögen für Ihren stationären Aufenthalt", shortDescription: "Bitte füllen Sie diese Fragebögen am Ende Ihrer Parkinson-Komplexbehandlung aus.", detailViewNavigationText: "Parkinson-Komplexbehandlung", detailViewIntroText: "Bitte füllen Sie diese Fragebögen am Ende Ihrer Parkinson-Komplexbehandlung aus."))
    ]
}

#Preview {
    NavigationStack{
        QuestionnairesScreen()
            
    }
    .defaultAppStorage(PreviewUserDefaults.previewUserDefaults)
    
}
