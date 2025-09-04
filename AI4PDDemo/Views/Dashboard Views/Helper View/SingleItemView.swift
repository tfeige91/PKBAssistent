//
//  SingleItemView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 19.06.23.
//

import SwiftUI
import AVFoundation
import AVKit



struct SingleItemView: View {
    
    @Environment(\.managedObjectContext) var viewContext
    @ObservedObject var recoredItem: UPDRSRecordedItem
    @State private var previewImage: UIImage?
    @State private var selectedID: Int = 0
    @State private var player: AVPlayer?
    
    let colors: [Color] = [.red,.orange, .yellow, .green.opacity(0.7), .green].reversed()
    
    
    var body: some View {
        
        VStack {
            Text("\(recoredItem.displayName)")
                .font(.title.bold())
            
            if let player = player {
                ZStack {
                    
                    VideoPlayer(player: player)
                        .frame(width: 270, height: 480)
                    
                    
                    //                    Image(systemName: "play.circle")
                    //                        .resizable()
                    //                        .foregroundColor(.white)
                    //                        .frame(width: 50, height: 50)
                    
                }
            }else {
                RoundedRectangle(cornerRadius: 15)
            }
            
            //
            //
            //            if let image = previewImage {
            //                Image(uiImage: image)
            //                    .frame(width: 180, height: 320)
            //            }
            
            Text("Ihre Einschätzung:")

                HStack {
                    ForEach((0...4), id: \.self) {id in
                        ZStack {
                            Circle()
                                .fill(id == selectedID ? colors[id] : colors[id].opacity(0.3))
                                .frame(width: 50, height: 50)
                            Text("\(id)")
                                .font(.title.bold())
                        }.onTapGesture {
                            recoredItem.rating = Int16(id)
                            selectedID = id
                            do {
                                try viewContext.save()
                            }catch{
                                print("could not save the recorded Item")
                            }
                        }
                    }
                }
            
        }
        .frame(width: 400, height: 640)
        .padding()
        .background(.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 20))
        .onAppear{
            Task {
                do {
                    guard let url = recoredItem.videoURL else {print("no valid URL"); return}
                    
                    let documentURL = VideoFileManager.instance.documentsDirectory
                    let fileURL = documentURL.appendingPathComponent(url.path())
                    print("DEBUG SESSION URL: url to show in player:", fileURL)
                    player = AVPlayer(url: fileURL)
                    
                    previewImage = try await previewImageFromVideo(url: fileURL)
                }catch {
                    print("failed loading the previewImage")
                }
            }
            selectedID = Int(recoredItem.rating)
        }
        
    }
    
    func previewImageFromVideo(url: URL) async throws -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator =  AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let imageTask = Task { () -> UIImage? in
            var duration = try await asset.load(.duration)
            duration.value = min(duration.value, 22)
            
            do {
                let (image, _) = try await generator.image(at: CMTimeMake(value: duration.value, timescale: 30))
                return UIImage(cgImage: image)
            }catch{
                print("could not create VideoPreview")
                return nil
            }
            
        }
        
        return try await imageTask.value
    }
}

//struct SingleItemView_Previews: PreviewProvider {
//    static var previews: some View {
//        SingleItemView()
//    }
//}
