//
//  RecordingView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 12.06.23.
//

import SwiftUI
import CoreData

struct RecordingView: View {
    
    @EnvironmentObject var model: CameraViewModel
    @Environment(\.dismiss) private var dismiss
    
    #if DEBUG
    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEW"] == "1"
    }
    #else
    private let isPreview = false
    #endif
    
    var body: some View {
        VStack{
            if !model.showFinishedRecordingRatingView{
                if isPreview{
                    Color.gray.opacity(0.2)
                        .edgesIgnoringSafeArea(.all)
                }else{
                    cameraView
                        .overlay {
                            if model.showInstructionOverlay{
                                GuidingOverlayView()
                            }
                        }
                }
            }else{
                Color.gray.opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                    .overlay{
                        EndOfRecordingRatingView(sessionID: model.sessionNumber!)
                    }
            }
        }
        
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onChange(of: model.dismissRecordingView) { shouldDismiss in
            if shouldDismiss {
                self.dismiss()
            }
        }
        
        //.edgesIgnoringSafeArea(.all)
        
    }
}

extension RecordingView {
    private var cameraView: some View {
        CameraView()
            .overlay {
                BodyBoundingBoxView()
            }
            .overlay(alignment: .top) {
                
                //TopView with some information
                Text(model.updrsItems[model.currentItem].displayName)
                    .font(.title.bold())
                    .frame(height: 45)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
                    .background(model.showRecordingIndicator ? .ultraThinMaterial : .thinMaterial)
                    .background {
                        if model.showRecordingIndicator {
                            Color.red.opacity(0.6)
                        }
                    }
            }
            .overlay {
                if model.showLayoutGuidingView{
                    VStack {
                        Spacer()
                        LayoutGuideView()
                        
                    }
                    .ignoresSafeArea(.all)
                    
                }
                
            }
            .background{
                Color.black
                    .ignoresSafeArea(.all)
            }
    }
}

struct RecordingView_Previews: PreviewProvider {
    static func makePreviewContainer() -> NSPersistentContainer{
        let container = NSPersistentContainer(name:"Model")
        let storeDescription = NSPersistentStoreDescription()
        storeDescription.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions = [storeDescription]
        
        container.loadPersistentStores {(_,error) in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }
        
        let context = container.viewContext
        //create dummy data
        for i in 1...3 {
            let session = Session(context: context)
            session.date = Date()
            session.id = Int16(i)
            session.url = ""
            for i in 1...2 {
                let item = UPDRSRecordedItem(context: context)
                item.rating = 2
                item.videoURL = URL(string: "")
                item.orderNumber = Int16(i)
                item.name = "UPDRS ITEM \(i)"
                item.session = session
                item.sideRaw = Side.left.rawValue
            }
        }
        do {
            try context.save()
        } catch {
            print("something went wrong")
            fatalError("Failed to save mock data: \(error)")
        }
        
        return container
    }
    
    
    static var vm: CameraViewModel = {
        let vm = CameraViewModel()
        vm.showFinishedRecordingRatingView = true
        vm.sessionNumber = 1
        return vm
    }()
    
    static var previews: some View {
        
        RecordingView()
            .environmentObject(vm)
            .environment(\.managedObjectContext, makePreviewContainer().viewContext)
        
    }
}
