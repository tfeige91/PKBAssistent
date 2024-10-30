//
//  RedCapAPIService.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 25.09.23.
//

import Foundation

enum RedCapErrors: Error {
    case invalidURL
    case couldNotCreateJSON
    case invalidResponse
    case noValidResponse
    case noRecordID
}

extension Dictionary {
    func percentEncoded() -> Data? {
        return map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}

class RedCapAPIService {
    
    private let apiKey = "26D5DADEA6925E84E0CFFEA3AF0D9A44"
    private let endpoint = "https://parkinsonzentrum.uniklinikum-dresden.de/api/"
    private init() {
        
    }
    static let instance = RedCapAPIService()
    
    
    func createNewRecordID() async throws -> String {
        guard let url = URL(string: endpoint) else {
            throw RedCapErrors.invalidURL
        }
        let body = [
            "token" : apiKey,
            "content" : "generateNextRecordName"]
        
        //convert to x-www-form-urlencoded
        var requestBodyComponents = URLComponents()
        requestBodyComponents.queryItems = []
        for (key, value) in body {
            requestBodyComponents.queryItems?.append(URLQueryItem(name: key, value: value))
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBodyComponents.query?.data(using: .utf8)
        
        let (data,response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            let _ = response as? HTTPURLResponse
            print("are here")
            throw RedCapErrors.invalidResponse
        }
        guard let answer = String(data: data, encoding: .utf8) else {
            throw RedCapErrors.noValidResponse
        }
        //Store RecordID in User Defaults
        UserDefaults.standard.setValue("\(answer)", forKey: "RecordId")
        return answer
    }
    
    func addNewEmptyRecord() async throws -> String {
        let newRecordID = try await createNewRecordID()
        guard let url = URL(string: endpoint) else {
            throw RedCapErrors.invalidURL
        }
        
        let values = [[
            "record_id" : newRecordID
        ]]
        print(values)
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: values, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("blabla")  // Output: [{"record_id":"3"}]
            throw RedCapErrors.couldNotCreateJSON
        }
        
        
        print(newRecordID)
        let body: [String:String] = [
            "token" : apiKey,
            "content" : "record",
            "action": "import",
            "format": "json",
            "type": "flat",
            "overwriteBehavior": "overwrite",
            "forceAutoNumber": "false",
            "data": jsonString,
            "returnContent": "count",
            "returnFormat": "json"
        ]
        var requestBodyComponents = URLComponents()
        requestBodyComponents.queryItems = []
        for (key, value) in body {
            requestBodyComponents.queryItems?.append(URLQueryItem(name: key, value: value))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBodyComponents.query?.data(using: .utf8)
        
        let (data,response) = try await URLSession.shared.data(for: request)
        //print(String(data: request.httpBody!,encoding: .utf8)!)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            let _ = response as? HTTPURLResponse
            //print(String(data: request.httpBody!,encoding: .utf8)!)
            throw RedCapErrors.invalidResponse
        }
        guard let answer = String(data: data, encoding: .utf8) else {
            throw RedCapErrors.noValidResponse
        }
        print(answer)
        
        return newRecordID
    }
    
    func uploadRecord(record: [RCField]) async throws {
        guard let url = URL(string: endpoint) else {
            throw RedCapErrors.invalidURL
        }
        
        guard let recordID = UserDefaults.standard.value(forKey: "RecordId") else {
            throw RedCapErrors.noRecordID
        }
        
        var values:[[String:String?]] = [[
            "record_id": "\(recordID)"
        ]]
        // get only relevant parts
        var answers : [String:String?] = [:]
        let _ = record.map { RCfield in
            answers[RCfield.fieldName] = RCfield.answer
        }
        
       //since it's an array of dicts
        values[0].merge(answers) { (current,_) in
            current
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: values, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("blabla")  // Output: [{"record_id":"3"}]
            throw RedCapErrors.couldNotCreateJSON
        }
        
        let body: [String:String] = [
            "token" : apiKey,
            "content" : "record",
            "action": "import",
            "format": "json",
            "type": "flat",
            "overwriteBehavior": "overwrite",
            "forceAutoNumber": "false",
            "data": jsonString,
            "returnContent": "count",
            "returnFormat": "json"
        ]
        var requestBodyComponents = URLComponents()
        requestBodyComponents.queryItems = []
        for (key, value) in body {
            requestBodyComponents.queryItems?.append(URLQueryItem(name: key, value: value))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBodyComponents.query?.data(using: .utf8)
        
        let (data,response) = try await URLSession.shared.data(for: request)
        //print(String(data: request.httpBody!,encoding: .utf8)!)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            let _ = response as? HTTPURLResponse
            //print(String(data: request.httpBody!,encoding: .utf8)!)
            throw RedCapErrors.invalidResponse
        }
        guard let answer = String(data: data, encoding: .utf8) else {
            throw RedCapErrors.noValidResponse
        }
        print(answer)
        
        
        
    }
    
    func fetchInstruments() async throws -> [RCInstrument] {
        guard let url = URL(string: endpoint) else {
            throw RedCapErrors.invalidURL
        }
        let body = [
            "token" : apiKey,
            "content" : "instrument",
            "format": "json",
            "returnFormat": "json"
        ]
        guard let requestData = body.percentEncoded() else {
            throw RedCapErrors.couldNotCreateJSON
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        
        let (data,response) = try await URLSession.shared.data(for: request)
        //print(String(data: request.httpBody!,encoding: .utf8)!)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            let _ = response as? HTTPURLResponse
            //print(String(data: request.httpBody!,encoding: .utf8)!)
            throw RedCapErrors.invalidResponse
        }
        let decoder = JSONDecoder()
        guard let instruments = try? decoder.decode([RCInstrument].self, from: data) else {
            
            throw RedCapErrors.noValidResponse
            
        }
        print(instruments)
        return instruments
    }
    
    func fetchInstrument(_ instrument: String) async throws -> [RCField] {
        guard let url = URL(string: endpoint) else {
            throw RedCapErrors.invalidURL
        }
        let body = [
            "token" : apiKey,
            "content" : "metadata",
            "format": "json",
            "returnFormat": "json",
            "forms": instrument
        ]
        guard let requestData = body.percentEncoded() else {
            throw RedCapErrors.couldNotCreateJSON
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        
        let (data,response) = try await URLSession.shared.data(for: request)
        //print(String(data: request.httpBody!,encoding: .utf8)!)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            let _ = response as? HTTPURLResponse
            //print(String(data: request.httpBody!,encoding: .utf8)!)
            throw RedCapErrors.invalidResponse
        }
        let decoder = JSONDecoder()
        guard let form = try? decoder.decode([RCField].self, from: data) else {
            
            throw RedCapErrors.noValidResponse
            
        }
        print(form)
        return form
    }
}
