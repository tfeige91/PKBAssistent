//
//  FileManager.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 12.06.23.
//

import Foundation

enum VideoFileManagerError: Error {
    case documentsDirectoryNotFound
}

class VideoFileManager {
    static let instance: VideoFileManager = {
        do {
            return try VideoFileManager()
        }catch{
            fatalError("Failed to initialize the VideoFileManager with: \(error)")
        }
    }()
    
    let documentsDirectory: URL
    let videosDirectory: URL

    
    private init() throws {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw VideoFileManagerError.documentsDirectoryNotFound
        }
        self.documentsDirectory = url
        let videosDirectory = url.appendingPathComponent("recordings")
        self.videosDirectory = videosDirectory
        
        setUpFolderStructure()
        print("FILE MANAGER VIDEOS DIRECTORY",videosDirectory)
    }
    
    //optional

    
    func getNewSessionFolder()->(sessionNumber: Int?, newSessionDirectory:URL?)?{
        //count current session folders
        do {
            let sessionDirectories = try FileManager.default.contentsOfDirectory(at: videosDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            let sessionDirectoryUrls = sessionDirectories.filter { url in
                var isDirectory: ObjCBool = false
                FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                return isDirectory.boolValue
            }
            let newSessionNumber = sessionDirectoryUrls.count + 1
            let newSessionDirectory = videosDirectory.appendingPathComponent("Session_\(newSessionNumber)")
            // Create the new session directory if it doesn't exist.
            try FileManager.default.createDirectory(at: newSessionDirectory, withIntermediateDirectories: true, attributes: nil)
            return (newSessionNumber, newSessionDirectory)
            
        }catch {
            return nil
        }
    }
    
    
    private func setUpFolderStructure(){
        
        if !FileManager.default.fileExists(atPath: videosDirectory.path){
            do {
                try FileManager.default.createDirectory(at: videosDirectory, withIntermediateDirectories: true,attributes: nil)
            } catch let error {
                print(error.localizedDescription)
            }
        }
        
    }
    
    
}
