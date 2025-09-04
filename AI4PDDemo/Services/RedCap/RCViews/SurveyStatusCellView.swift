//
//  SurveyStatusCellView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 08.01.25.
//

import SwiftUI

struct SurveyStatusCellView: View {
    let survey: SurveyStatusCellModel
    @State var navigationActive = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading){                Text(survey.surveyName)
                    .font(.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Fragebogen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            Spacer()
            if survey.status != .completed {
                NavigationLink {
                    RCSurveyWebView(url: survey.surveyURL)
                } label: {
                    Text("Fragebogen ausfüllen")
                        .foregroundStyle(.white)
                        .font(.headline)
                        .frame(width: 180, height: 40)
                        .padding(.horizontal)
                        .background(.blue)
                        .cornerRadius(20)
                        .padding(.horizontal)
                }
            }
 
            Image(systemName: survey.status == .completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(survey.status == .completed ? .green : .gray)
            
            
            
        }
        .overlay(
                    Rectangle()
                        .frame(height: 1) // Border thickness
                        .foregroundColor(.gray), // Border color
                    alignment: .bottom // Align the border to the bottom
                )
        .padding()
        
        
                    
         // NavigationLink au
    }
}

#Preview {
    let url = URL(string: "https://parkinsonzentrum.uniklinikum-dresden.de/surveys/?s=aJxPmaYH6e2r5iJx")!
    let survey = SurveyStatusCellModel( surveyName: "mds_updrs_ii", surveyURL: url,  status: AI4PDDemo.SurveyCompletionStatus.notStarted)
    NavigationStack {
        SurveyStatusCellView(survey: survey)
    }
    
}
