//
//  StudyGroupView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 30.12.24.
//

import SwiftUI

enum UserGroup: String {
    case intervention, control
}

struct StudyGroupView: View {
    @State private var recordID: String = ""
    @AppStorage("userGroup") var userGroup: String?
    @State private var navigateToHome = false
    @State private var showAlert = false
    @State private var fetchingRecordID = false
    
    var body: some View {
        HStack{
            NavigationStack {
                VStack(spacing: 30) {
                    Text("Bitte wählen Sie die Studiengruppe")
                        .font(.largeTitle.bold())
                        .padding()
                    
                    Button(action: {
                        userGroup = UserGroup.intervention.rawValue
                        assignGroupAndFetchRecordID(group: .intervention)
                    }) {
                        WideButton(title: "Interventionsgruppe", color: .green)
                    }
                    .disabled(fetchingRecordID)
                    
                    Button(action: {
                        userGroup = UserGroup.control.rawValue
                        assignGroupAndFetchRecordID(group: .control)
                    }) {
                        WideButton(title: "Kontrollgruppe", color: .orange)
                    }
                    .disabled(fetchingRecordID)
                }
                .alert("RecordID erstellt", isPresented: $showAlert) {
                    Button("OK") {
                        UserDefaults.standard.set(self.recordID, forKey: "RecordID")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            navigateToHome = true
                        }
                    }
                } message: {
                    Text("Folgende RecordID wurde erstellt: \(recordID)")
                }
                .padding()
                .navigationDestination(isPresented: $navigateToHome) {
                    HomeScreen()
                }
            }
        }
        
    }
    
    private func assignGroupAndFetchRecordID(group: UserGroup) {
        userGroup = group.rawValue
        fetchingRecordID = true
        Task {
            do {
                if  UserDefaults.standard.object(forKey: "RecordID") == nil {
                    let newRecordID = try await
                    RedCapAPIService.instance.addNewEmptyRecord(for: group)
                    
                    DispatchQueue.main.async {
                        self.recordID = newRecordID
                        self.showAlert = true
                    }
                }
            } catch {
                
                print("Fehler beim Generieren der RecordID: \(error)")
            }
            fetchingRecordID = false
        }
    }
    
}

#Preview {
    StudyGroupView()
}
