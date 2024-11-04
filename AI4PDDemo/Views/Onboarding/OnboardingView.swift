//
//  OnboardingView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 28.07.23.
//

import SwiftUI
import AVFoundation

// This is the View that Users will sie on first App Launch.
// 1. The Purpose of the App
// 2. The Functionality
// 3. Permissions?
// 4. How to use it: 3 times a day for two weeks
// 5. Cardinal Complaint
// 6. Diary
// 7. Chat

enum OnboardingState: Int, CaseIterable {
    case purpose
    case functionalityVideo
    case cardinalComplaint
    case functionalityDiary
    case doctor
    //case chat
    case permissions
    case studyFlow
    case questionnaire
}

struct OnboardingView: View {
    @State var onboardingState: OnboardingState = .purpose
    @AppStorage("didFinishedOnboarding") var didFinishedOnboarding: Bool?
    @EnvironmentObject var speechRecognizer: SpeechRecognizer
    
    let transition: AnyTransition = .asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading))
    
    var body: some View {
        ZStack{
            switch onboardingState {
            case .purpose:
                purposeView
                    .transition(transition)
            case .functionalityVideo:
                functionalityVideoView
                    .transition(transition)
            case .functionalityDiary:
                functionalityDiaryView
                    .transition(transition)
            case .permissions:
                permissionsView
                    .transition(transition)
            case .studyFlow:
                studyView
                    .transition(transition)
            case .cardinalComplaint:
                cardinalComplaintView
                    .transition(transition)
            case .doctor:
                doctorDiaryView
                    .transition(transition)
//            case .chat:
//                chat
//                    .transition(transition)
            case .questionnaire:
                QuestionnaireView()
                    .transition(transition)
            }
            
            VStack {
                Spacer()
                HStack {
                    if onboardingState.rawValue > 0  {
                        previousButton
                    }
                    nextButton
                }
            }
            .padding(30)
        }
        
        .frame(maxWidth: .infinity)
        .background(.gray.opacity(0.2))
        
        
    }
    
    //MARK: - Views
    
    private var nextButton: some View {
        Button {
            if onboardingState.rawValue <= (OnboardingState.allCases.count-2){
                withAnimation(.spring()){
                    onboardingState = OnboardingState(rawValue: (onboardingState.rawValue+1))!
                }
                
            }else{
                withAnimation(.spring()){
                    didFinishedOnboarding = true
                }
                
            }
            
        } label: {
            Text(onboardingState.rawValue == (OnboardingState.allCases.count-1) ? "Einführung beenden" : "Weiter")
                .foregroundColor(.white)
                .font(.headline.bold())
                .frame(height: 50)
                .frame(maxWidth: 400)
                .background(.blue)
                .cornerRadius(10)
                .padding(.horizontal, 30)
        }
    }
    
    private var previousButton: some View {
        
        
            Button {
                if onboardingState.rawValue > 0 {
                    withAnimation(.spring()){
                    onboardingState = OnboardingState(rawValue: (onboardingState.rawValue-1))!}
                }
                
            } label: {
                Text("Zurück")
                    .foregroundColor(.white)
                    .font(.headline.bold())
                    .frame(height: 50)
                    .frame(maxWidth: 400)
                    .background(.blue)
                    .cornerRadius(10)
                    .padding(.horizontal, 30)
            }
        
        
    }
    
    private var purposeView: some View {
        VStack(){
            Image("doctor")
                .resizable()
                .scaledToFit()
                .frame(width: 300)
            Spacer()
                .frame(height: 50)
            Text("Herzlich Wilkommen")
                .titleText()
            
            Text(OnboardingData.welcomeMessage)
                .paragraphTextStyle()
                .padding()
            
        }
        .frame(idealHeight: 500)
        .padding(.horizontal, 60)
    }

    private var functionalityVideoView: some View {
        VStack{
           Text("Funktionalitäten")
                .titleText()
            Text(OnboardingData.functionalityText)
                .paragraphTextStyle()
        }
        .frame(idealHeight: 500)
        .padding(.horizontal, 60)
    }
    
    private var functionalityDiaryView: some View {
        VStack{
           Text("Symptomtagebuch")
                .titleText()
            Text(OnboardingData.diaryText)
                .paragraphTextStyle()
        }
        .frame(idealHeight: 500)
        .padding(.horizontal, 60)
        
    }
    private var permissionsView: some View {
        VStack{
           Text("Berechtigungen")
                .titleText()
            Text(OnboardingData.permissions)
                .paragraphTextStyle()
            
            Button {
                speechRecognizer.askPermission()
                
                //Video Recording Permission
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                switch status {
                case .authorized:
                    break
                case .notDetermined:
                    AVCaptureDevice.requestAccess(for: .video) { granted in
                        if !granted {
                            fatalError("Camera permission is required.")
                        }
                    }
                default:
                    fatalError("Camera permission is required.")
                }
                
                print("permission Button pressed")
                //camera Permision
                //microphone Permission
                //Speech recognition Permission
                
            } label: {
                Text("Berechtigungen erteilen")
                    .foregroundColor(.white)
                    .font(.headline.bold())
                    .frame(height: 50)
                    .frame(maxWidth: 400)
                    .background(.blue)
                    .cornerRadius(10)
                    .padding(30)
            }

        }
        .frame(idealHeight: 500)
        .padding(.horizontal, 60)
    }
    
    private var studyView: some View {
        VStack{
           Text("Ablauf der Studie")
                .titleText()
            Text(OnboardingData.studyText)
                .paragraphTextStyle()
        }
        .frame(idealHeight: 500)
        .padding(.horizontal, 60)
    }
    
    private var cardinalComplaintView: some View {
        VStack{
           Text("Eigene Aufnahmen")
                .titleText()
            Text(OnboardingData.cardinalComplaintText)
                .paragraphTextStyle()
        }
        .frame(idealHeight: 500)
        .padding(.horizontal, 60)
    }
    
    private var doctorDiaryView: some View {
        VStack{
           Text("Arztvisite")
                .titleText()
            Text(OnboardingData.doctorDiaryText)
                .paragraphTextStyle()
        }
        .frame(idealHeight: 500)
        .padding(.horizontal, 60)
    }
    
    private var chat: some View {
        VStack{
           Text("Antworten auf Ihre Fragen")
                .titleText()
            Text(OnboardingData.chatText)
                .paragraphTextStyle()
        }
        .frame(idealHeight: 500)
        .padding(.horizontal, 60)
    }
    
    struct QuestionnaireView: View {
        @State var text: String = ""
        var body: some View {
            VStack{
               Text("Abschlussfragebogen")
                    .titleText()
                Text(text)
                    .paragraphTextStyle()
                    .task{
                        text = await OnboardingData.getQuestionnaireText()
                    }
            }
            .frame(idealHeight: 500)
            .padding(.horizontal, 60)
        }
        
    }
    
}

struct OnboardingData {
    static let welcomeMessage: String =
    """
    Ich bin Ihr persönlicher Parkinson-Assistent.
    Ich freue mich sehr, dass Sie an unserer Studie teilnehmen!
    Ich möchte Ihnen zunächst erklären, wie ich Ihnen helfen kann, Ihre Symptome bestmöglich zu dokumentieren und für Ihren nächsten Arzt-Besuch aufzubereiten.
    """
    
    static let functionalityText: String =
    """
    
    Die wichtigste Funktion ist die geführte Videoaufnahme Ihrer motorischen Symptome.
    Ich werde Sie dabei mit gesprochenen Anweisungen und eingeblendeten Hilfen unterstützen, insgesamt vier Übungen aufzunehmen, die Ihrem behandelten Arzt oder Ihrer Ärztin dabei helfen, Ihre Medikation bestmöglich einzustellen.
    Im Anschluss an die Aufnahmen erhalten Sie die Möglichkeit, ihre Beweglichkeit selbst einzuschätzen. So entsteht automatisch ein Symptomtagebuch.
    Wichtig: Sie können jederzeit individuelle Aufnahmen erstellen, um besonders relevante Symptome festzuhalten, die in den Übungen nicht enthalten sind.
    """
    
    static let diaryText: String =
    """
    Die App bietet die Möglichkeit, alle Aufnahmen jederzeit wieder anzusehen. Darüber hinaus werden Ihre persönlichen Einschätzungen in Diagrammen aufbereitet.
    So ist es sehr einfach und schnell möglich, den Verlauf Ihrer Symptome zu überblicken und mögliche Schwankungen zu identifizieren.
    """
    
    static let permissions: String =
    """
    Damit Sie alle Funktionen der App nutzen können, müssen Sie einige Berechtigungen erteilen. Diese sind die Zustimmung zur Nutzung der Kamera sowie des Mikrofons und der Sprachaufnahme. Mit der Sprachaufnahme ist es für Sie möglich, die App mit Ihrer Stimme zu steuern. Wie das genau funktioniert, erkläre ich Ihnen später.
    Um die Berechtigungen zu erteilen, klicken Sie bitte hier:
    """
    
    static let studyText: String =
    """
    Im Rahmen dieser Studie bitten wir Sie für einen Zeitraum von zwei Wochen jeden Tag drei Aufnahmen mit der App vorzunehmen, beispielsweise eine Vormittags, eine Nachmittags und eine Abends. Am besten geeignet sind Zeitpunkte, an denen sich Ihre Beweglichkeit oft verändert. Jede Aufnahme benötigt etwa fünf Minuten Zeit.
    
    Nutzen Sie gern während der gesamten Studienzeit die Möglichkeit, über die Chat-Funktion Fragen zu stellen, die Ihnen bezüglich Ihrer Erkrankung durch den Kopf gehen.
    """
    
    static let cardinalComplaintText: String =
    """
    Wenn Sie eines oder mehrere Symptome haben, die in den vier Aufnahmen nicht abgedeckt werden, die Sie aber gern Ihrem behandelnden Arzt zeigen möchten, können Sie individuelle Aufnahmen machen.
    Nutzen Sie dafür den Knopf "Eigene Aufnahme" im Hauptmennü.
    Wenn Sie eine eigene Aufnahme aufgezeichnet haben, nutzen Sie bitte die Eingabemaske am Ende der Aufzeichnung, um kurz zu notieren, auf was Ihr Arzt achten soll.
    """
    
    static let doctorDiaryText: String =
    """
    Aufnahmen, bei denen Sie sich nur eine 4 oder 5 gegeben haben, werden automatisch in die Ansicht für Ihren behandelnden Arzt übernommen.
    Darüber hinaus finden sich hier auch die von Ihnen zusätzlich aufgenommen Symptome und ihre Beschreibungen.
    """
    static let chatText: String =
    """
    In der Chat-Funktion können Sie Fragen stellen, die Ihnen in Bezug auf Ihre Erkrankung haben. Tippen Sie dazu einfach Ihre Fragen ein und sie erhalten umgehend eine Antwort.
    """
    
    static func getQuestionnaireText() async -> String{
        
        do {
            if  UserDefaults.standard.object(forKey: "RecordID") == nil {
                let recordID = try await
                RedCapAPIService.instance.addNewEmptyRecord()
                UserDefaults.standard.set(recordID, forKey: "RecordID")
            }
            let recordID = UserDefaults.standard.value(forKey: "RecordID")!
            return
                        """
                        Bitte füllen Sie am Ende der zweiwöchigen Studiendauer den Fragebogen aus. Ihre RecordID lautet: \(recordID).
                        """
        }catch{
            print("no RecordID created")
            return ""
        }
        
    }
    
    
}


struct ParagraphText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 32))
            .foregroundColor(.black.opacity(0.8))
            .multilineTextAlignment(.leading)
            .lineSpacing(7)
    }
}

struct TitleText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 40,weight: .bold))
            .padding(.bottom, 30)
    }
}

extension View {
    func paragraphTextStyle() -> some View {
        modifier(ParagraphText())
    }
    func titleText() -> some View {
        modifier(TitleText())
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            OnboardingView()
        }
    }
}
