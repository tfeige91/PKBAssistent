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

enum OnboardingStateControl: Int, CaseIterable {
    case purpose_control
    case studyFlow_control
    case questionnaire_control
}

struct OnboardingView: View {
    @State var onboardingState: OnboardingState = .purpose
    @AppStorage("didFinishedOnboarding") var didFinishedOnboarding: Bool?
    @AppStorage("userGroup") var userGroup: String = ""
    var studyGroup: UserGroup {
        if let studyGroup = UserGroup(rawValue: userGroup) {
            return studyGroup
        }else {
            return .intervention
        }
    }
    @EnvironmentObject var speechRecognizer: SpeechRecognizer
    var steps: [Any] {
        // Dynamisch die Schritte basierend auf der Gruppe auswählen
        switch studyGroup {
        case .intervention:
            return OnboardingState.allCases
        case .control:
            return OnboardingStateControl.allCases
        }
    }
    @State private var currentStepIndex: Int = 0
    @State private var pageTurnedForward: Bool = true
    
    var transition: AnyTransition {
        if pageTurnedForward {
            return AnyTransition.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading))
        }else{
            return AnyTransition.asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing))
        }
        
    }
    
    var body: some View {
        ZStack{
            if studyGroup == .intervention, let step = steps[currentStepIndex] as? OnboardingState {
                            switch step {
                            case .purpose:
                                purposeView.transition(transition)
                            case .functionalityVideo:
                                functionalityVideoView.transition(transition)
                            case .cardinalComplaint:
                                cardinalComplaintView.transition(transition)
                            case .functionalityDiary:
                                functionalityDiaryView.transition(transition)
                            case .doctor:
                                doctorDiaryView.transition(transition)
                            case .permissions:
                                permissionsView.transition(transition)
                            case .studyFlow:
                                studyView.transition(transition)
                            case .questionnaire:
                                QuestionnaireView()
                                    .transition(transition)
                            }
                        } else if studyGroup == .control, let step = steps[currentStepIndex] as? OnboardingStateControl {
                            switch step {
                            case .purpose_control:
                                purposeView.transition(transition)
                            case .studyFlow_control:
                                studyView.transition(transition)
                            case .questionnaire_control:
                                QuestionnaireView()
                                    .transition(transition)
                            }
                        }
            
            
            
            VStack {
                Spacer()
                HStack {
                    if currentStepIndex > 0  {
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
            pageTurnedForward = true
            withAnimation(.spring()) {
                            if currentStepIndex < steps.count - 1 {
                                currentStepIndex += 1
                            } else {
                                didFinishedOnboarding = true
                            }
                        }
            
        } label: {
            Text(currentStepIndex == steps.count - 1 ? "Einführung beenden" : "Weiter")
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
            pageTurnedForward = false
            withAnimation(.spring()){
                currentStepIndex = max(0, currentStepIndex - 1)
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
            
            Text(studyGroup == .intervention ? OnboardingData.welcomeMessage : OnboardingData.welcomeMessageControl)
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
            Text(studyGroup == .intervention ? OnboardingData.studyText: OnboardingData.studyTextControl)
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
    
    static let welcomeMessageControl: String =
    """
    Vielen Dank, dass sie an unserer Studie teilnehmen! 
    In dieser Studie möchten wir gerne herausfinden, wie zufrieden Sie mit der Versorgung Ihrer Parkinson-Erkrankung sind.
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
    
    """
    
    static let studyTextControl: String =
    """
    Im Rahmen dieser Studie bitten wir Sie an folgenden drei Zeitpunkten einige Fragebögen auszufüllen:
    - Vor Ihrer Parkinson-Komplexbehandlung (PKB)
    - Am Ende Ihrer PKB
    - 8 Wochen nach Ihrer PKB
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
    
    static func getRecordIDText() async -> String{
        do {
            if  UserDefaults.standard.object(forKey: "RecordID") == nil {
                let recordID = try await
                RedCapAPIService.instance.addNewEmptyRecord()
                UserDefaults.standard.set(recordID, forKey: "RecordID")
            }
            if let recordID = UserDefaults.standard.value(forKey: "RecordID") as? String {
                return recordID
            } else {
                throw NSError(domain: "UserDefaultsError", code: 1, userInfo: [NSLocalizedDescriptionKey: "RecordID is not a String"])
            }
        } catch {
            print("Error fetching or saving RecordID: \(error)")
            return "" // or handle the error as appropriate
        }
    }
    
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
                        Die Fragebögen vor Ihrer PKB füllen Sie bitte hier in der App aus. 
                        Dafür ist es notwendig, dass das iPad mit dem Internet verbunden ist. 
                        Wie Sie das iPad mit dem Internet verbinden, finden Sie in der gedruckten Anleitung.
                        
                        Die Fragebögen, die Sie am Ende Ihrer PKB ausfüllen sollen, können Sie ebenfalls in der App beantworten.
                        
                        Für den Abschlussfragebogen senden wir Ihnen eine E-Mail mit einem Link zu dem Abschlussfragebogen.
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
            .font(.system(size: 30))
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
        .defaultAppStorage(PreviewUserDefaults.previewUserDefaults)
    }
}
