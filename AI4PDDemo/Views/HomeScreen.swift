//
//  HomeScreen.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 05.06.23.
//

import SwiftUI
import AVFoundation

struct HomeScreen: View {
    
    //Show Onboarding on first App Launch
    @AppStorage("didFinishedOnboarding") var didFinishedOnboarding: Bool = false
    @AppStorage("RecordID") var recordID: String = ""
    
    
    @State private var path = NavigationPath()
    @EnvironmentObject var speechRecognizer: SpeechRecognizer
    let validOptions: [SpokenNavigation] = [.chat,.diary,.doctor,.recording]
    
    @State var showWelcome = false
    @State var showToolbar = false
    @State var audioPlayer: AVAudioPlayer?
    @EnvironmentObject var model: CameraViewModel
    
    //TipView
    @State private var showTips = false
    
    var body: some View {
        NavigationStack(path: $path) {
            //If already onboarded
            if didFinishedOnboarding{
                //Welcome Back View
                if showWelcome {
                    welcomeView
                        .transition(.opacity)
                }else{
                    //main Menu
                    VStack {
                        Spacer()
                        avatarImage
                            .padding(.top, 20)
                        buttons
                        Spacer()
                        versionIdentifier()
                        Spacer()
                            .frame(height: 10)
                        
                            
                        //.navigationBarTitleDisplayMode(.large)
                            .toolbar {
                                ToolbarItemGroup{
                                    rewindButton
                                        .onAppear{
                                            model.stopSpeech()
                                        }
                                    voiceRecordingButton
                                        .showCase(order: 1, title: "Sprachsteuerung", cornerRadius: 50, scale: 1)
                                    
                                    helpButton
                                        .showCase(order: 0, title: "Hilfe ausgeben", cornerRadius: 50, scale: 1)

                                        .onChange(of: model.currentTip, perform: { newValue in
                                            if model.currentTip != -1 {
                                                model.explainMainScreen()
                                            }else{
                                                showTips = false
                                            }
                                            
                                        })
                                        
                                }
                                
                                
                            }
                    }
                    .onAppear(){
                        path = NavigationPath()
                        
                        
                        
                    }
                    .onChange(of: speechRecognizer.spokenNavigation){navigation in
                        if validOptions.contains(navigation) {
                            self.path.append(navigation)
                            speechRecognizer.stopRecording()
                        }
                    }
                    .navigationDestination(for: SpokenNavigation.self) { spokenNav in
                        if spokenNav == .recording {
                            RecordingView()
                                .onAppear{
                                    model.currentItem = 0 //maybe change later
                                    model.speakHelp = true
                                    model.bodyLayoutGuideFrame = CGRect(x: 0, y: -30, width: 370, height: 800)
                                    model.showLayoutGuidingView = true
                                    model.showFinishedRecordingRatingView = false
                                    model.dismissRecordingView = false
                                    model.sessionURL = nil
                                    print("recordingView")
                                }
                                .onDisappear{
                                    model.timer?.invalidate()
                                    model.speakHelp = false
                                    model.stopSpeech()
                                }
                        }else if spokenNav == .diary {
                            RecordingsView()
                        }else if spokenNav == .doctor {
                            DoctorsView()
                        }else if spokenNav == .chat {
                            //MatrixView()
                        }else if spokenNav == .questionnaire{
                            RCFormView()
                        }
                    }
                    .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge:.top)))
                }
                //If not onboarded
            }else {
                OnboardingView()
                    .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge:.bottom)))
                    .onDisappear(){
                        if showTips{
                            self.model.currentTip = 0
                        }
                    }
            }
            
        }
        
        .onAppear{
            if !didFinishedOnboarding {
                showTips = true
            }
            showWelcome = didFinishedOnboarding ? true : false
        }
        .onDisappear{
            speechRecognizer.stopRecording()
        }
        .modifier(ShowCaseRoot(showHighlights: $showTips, onFinished: {
            print("finished onboarding")
        }, currentHighlight: $model.currentTip))
        
    }
}

//MARK: - View Components
extension HomeScreen {
    private var welcomeView: some View {
        WelcomeView()
            .onAppear {
//                self.playOnBoarding(audioFilename: "OnboardingAudio", audioFileExtension: "mp3")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                    withAnimation(.easeIn(duration: 2)) {
                        self.showWelcome = false

                    }
                }
//                DispatchQueue.main.asyncAfter(deadline: .now() + 6){
//                    withAnimation(.easeIn(duration: 2)) {
//                        self.showToolbar = true
//
//                    }
//                }
            }
    }
    private var avatarImage: some View {
        Image("doctor")
            .resizable()
            .scaledToFit()
            .frame(width: 300, height: 300)
            .padding(.bottom, 50)
    }
    private var buttons: some View {
        VStack{
            //ChatbotButton
//            NavigationLink(value: SpokenNavigation.chat) {
//                WideButton(title: "Chat", color: .black)
//                    .showCase(order: 2, title: "Sprachsteuerung", cornerRadius: 10, scale: 1.05)
//            }
            
            NavigationLink(value: SpokenNavigation.recording) {
                WideButton(title: "Übung starten", color: .green)
                    .showCase(order: 2, title: "Sprachsteuerung", cornerRadius: 10, scale: 1.05)
                    
            }
            
            NavigationLink(value: SpokenNavigation.diary) {
                WideButton(title: "Videotagebuch", color: .blue)
                    .showCase(order: 3, title: "Sprachsteuerung", cornerRadius: 10, scale: 1.05)
            }
            
            NavigationLink(value: SpokenNavigation.doctor) {
                WideButton(title: "Videovorstellung für den Arzt",color: Color.yellow)
                    .showCase(order: 4, title: "Sprachsteuerung", cornerRadius: 10, scale: 1.05)
            }
            
            NavigationLink(value: SpokenNavigation.questionnaire) {
                WideButton(title: "Abschlussfragebogen",color: Color.gray)
                    .showCase(order: 5, title: "Abschlussfragebogen", cornerRadius: 10, scale: 1.05)
            }
        }
        .frame(width: 500)
    }
    //View that displays the current installed Bundle Version
    @ViewBuilder
    func versionIdentifier() -> some View {
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            Text("Version: \(appVersion) (Build: \(buildNumber)) | RecordID: \(recordID)")
            
        } else {
            EmptyView()
        }
    }
    
    
    
    private var voiceRecordingButton: some View {
        Button {
            print("Voice clicked")
            do {
                try speechRecognizer.startRecording()
            }catch let error {
                print(error.localizedDescription)
            }
            
        } label: {
            Image(systemName: "mic.fill")
                .font(.largeTitle)
            
        }
    }
    
    private var rewindButton: some View {
        Button {
            didFinishedOnboarding = false
            model.currentTip = -1
        } label: {
            Image(systemName: "arrowshape.turn.up.backward.circle")
                .font(.largeTitle)
            
        }
    }
    
    private var helpButton: some View {
        Button {
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.largeTitle)
        }
        .simultaneousGesture(LongPressGesture(minimumDuration: 1.0).onEnded({ _ in
            print("long press updated?")
            self.showTips = true
            model.currentTip = 0
        }))
        .simultaneousGesture(TapGesture().onEnded {
            print("audioPlayer clicked")
                                            if let audioPlayer = audioPlayer,
                                                audioPlayer.isPlaying{
                                                audioPlayer.pause()
                                            }else{
                                                audioPlayer?.play()
                                            }
        })
    }
}

//functions
extension HomeScreen{
    func playOnBoarding (audioFilename: String, audioFileExtension: String) {
        if let audioFilePath = Bundle.main.path(forResource: audioFilename, ofType: audioFileExtension) {
            let audioFileURL = URL(fileURLWithPath: audioFilePath)
            do {
                // Create an audio player with the specified audio file URL
                audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
                //audioPlayer.delegate = self
                
                // Prepare the audio player for playback
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch {
                print("Failed to create audio player: \(error)")
            }
        } else {
            print("Audio file not found.")
        }
    }
}

struct WelcomeView: View {
    
    var body: some View {
        VStack {
            avatarImage
            textBox
        }
        .frame(width: 700)
    }
    
    private var avatarImage: some View {
        Image("doctor")
            .resizable()
            .scaledToFit()
            .frame(width: 300, height: 300)
            .padding(.bottom, 40)
    }
    private var textBox: some View {
            VStack{
                Text("Schön,\ndass du da bist")
                    .font(.system(size: 40).bold())
                    .foregroundColor(.white)
                    .padding(50)
                    .multilineTextAlignment(.center)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
}

struct WideButton: View {
    let title: String
    let color: Color
    
    var body: some View {
        ZStack{
            RoundedRectangle(cornerRadius: 10)
                .fill(color)
                .frame(maxWidth: .infinity)
                .frame(height: 90)
            
            VStack{
                Text(title)
                    .font(.system(size: 32).bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .environmentObject(SpeechRecognizer())
    }
}
