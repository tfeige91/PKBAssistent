//
//  RedCapAPIService.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 25.09.23.
//

import Foundation

//MARK: - Models
enum RedCapErrors: Error {
    case invalidURL
    case couldNotCreateJSON
    case invalidResponse
    case noValidResponse
    case noRecordID
    case couldNotCreateRequest
}

struct FormEventMapping: Codable, Identifiable {
    let armNum: Int
    let eventName: String
    let form: String
    
    var id: String {
        eventName + "_" + form
    }
    
    enum CodingKeys: String,CodingKey{
        case armNum = "arm_num"
        case eventName = "unique_event_name"
        case form
    }
}

struct SurveyStatusCellModel: Identifiable {
    let id = UUID()
    let surveyName: String
    var surveyURL: URL
    var SurveyCompletionCode = 111 // to be implemented later
    var status: SurveyCompletionStatus
}


struct Event: Codable{
    let eventName: String
    let armNumber:Int
    let uniqueEventName:String
    let customEventLabel:String
    let eventID:Int
    
    enum CodingKeys: String,CodingKey {
        case eventName = "event_name"
        case armNumber = "arm_num"
        case uniqueEventName = "unique_event_name"
        case customEventLabel = "custom_event_label"
        case eventID = "event_id"
    }
}

enum SurveyCompletionStatus: Int {
    case notStarted = 0
    case started = 1
    case completed = 2
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
    
    //can add for specific user Group
    func addNewEmptyRecord(for arm: UserGroup?=nil) async throws -> String {
        var studyArm: String {
            switch arm {
            case .intervention:
                "_arm_1"
            case .control:
                "_arm_2"
            case nil:
                //set as intervention group (for all running)
                "_arm_1"
            }
        }
        
        let newRecordID = try await createNewRecordID()
        guard let url = URL(string: endpoint) else {
            throw RedCapErrors.invalidURL
        }
        
        let values = [[
            "record_id" : newRecordID,
            "redcap_event_name":"baseline"+studyArm
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
    
    private func generateRequest(_ urlString: String,postData:[String:Any]) throws -> URLRequest {
        guard let url = URL(string: urlString) else {
            throw RedCapErrors.invalidURL
        }
        
        guard let requestData = postData.percentEncoded() else {
            throw RedCapErrors.couldNotCreateJSON
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        
        return request
    }
    
    //Check if it is a valid Response and if it is decode to the Type it should decode to
    private func handleURLResponse<T: Decodable>(_ requestResponse: (data:Data,response:URLResponse),decodeAs type:T.Type) throws -> T {
        guard let response = requestResponse.response as? HTTPURLResponse, response.statusCode == 200 else {
            let _ = requestResponse.response as? HTTPURLResponse
                //print(String(data: request.httpBody!,encoding: .utf8)!)
                throw RedCapErrors.invalidResponse
            }
            let decoder = JSONDecoder()
        guard let returnedData = try? decoder.decode(type, from: requestResponse.data) else {
                
                throw RedCapErrors.noValidResponse
                
            }
        return returnedData
    }
    
    func fetchInstrument(_ instrument: String) async throws -> [RCField] {
        let body = [
            "token" : apiKey,
            "content" : "metadata",
            "format": "json",
            "returnFormat": "json",
            "forms": instrument
        ]
        //generate Request
        guard let request = try? generateRequest(endpoint, postData: body) else {
            throw RedCapErrors.couldNotCreateRequest
        }
        
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
    
    //MARK: - Fetch Surveys for RecordID
    
    //get Events for Study Arm
    func getEventsForStudyArm(arm: UserGroup) async throws -> [Event] {
        let arm = switch arm {
        case .intervention:
            1
        case .control:
            2
        }
        let body = [
            "token" : apiKey,
            "content" : "event",
            "format": "json",
            "arms": "\(arm)",
            "returnFormat": "json",
        ]
        
        guard let request = try? generateRequest(endpoint, postData: body) else {
            throw RedCapErrors.couldNotCreateRequest
        }
        
        let requestResult = try await URLSession.shared.data(for: request)
        
        guard let events = try? handleURLResponse(requestResult, decodeAs: [Event].self) else {
            throw RedCapErrors.noValidResponse
        }
        
        return events
    }
    
    //get Survey Event Mapping
    func getFormEventMapping(arm: UserGroup) async throws -> [FormEventMapping] {
        let arm = switch arm {
        case .intervention:
            1
        case .control:
            2
        }
        let body = [
            "token" : apiKey,
            "content" : "formEventMapping",
            "format": "json",
            "arms": "\(arm)",
            "returnFormat": "json",
        ]
        guard let request = try? generateRequest(endpoint, postData: body) else {
            throw RedCapErrors.couldNotCreateRequest
        }
        let requestResult = try await URLSession.shared.data(for: request)
        
        guard let formEventMappings = try? handleURLResponse(requestResult, decodeAs: [FormEventMapping].self) else {
            throw RedCapErrors.noValidResponse
        }
        
        return formEventMappings
    }
    
   
    //get survey completion status
    func getSurveyCompletionStatus(arm: UserGroup,eventName:String, recordID:String,surveyName:String) async throws -> SurveyCompletionStatus {
        let arm = switch arm {
        case .intervention:
            1
        case .control:
            2
        }
        let key = surveyName+"_complete"
        let body = [
            "token" : apiKey,
            "content" : "record",
            "action" : "export",
            "format": "json",
            "type" : "flat",
            "records" : recordID,
            "fields" : key,
            "events" : eventName,
            "rawOrLabel": "raw",
            "rawOrLabelHeaders": "raw",
            "exportCheckboxLabel": "false",
            "exportSurveyFields": "false",
            "exportDataAccessGroups": "false",
            "returnFormat": "json",
        ]
        
        guard let request = try? generateRequest(endpoint, postData: body) else {
            throw RedCapErrors.couldNotCreateRequest
        }
        let (data,response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            let _ = response as? HTTPURLResponse
                //print(String(data: request.httpBody!,encoding: .utf8)!)
                throw RedCapErrors.invalidResponse
            }
            let decoder = JSONDecoder()
        //Antwort manuell decodieren
        guard let decodedArray = try? decoder.decode([[String:String]].self, from: data) else {
            throw RedCapErrors.noValidResponse
        }
        
        var completionStatus: SurveyCompletionStatus = .notStarted
        if let survey = decodedArray.first(where: {$0.keys.contains(key)}),
           let value = survey[key] {
            if value == "0" {
                completionStatus = .notStarted
            }else if value == "1" {
                completionStatus = .started
            }else if value == "2" {
                completionStatus = .completed
            }
        }
        return completionStatus
        
    }
    
    func fetchSurveyLink(recordID:String, event:String,surveyName:String) async throws -> URL {
        let body = [
            "token" : apiKey,
            "content" : "surveyLink",
            "format": "json",
            "instrument": surveyName,
            "event":event,
            "record": recordID,
            "returnFormat": "json",
        ]
        
        guard let request = try? generateRequest(endpoint, postData: body) else {
            throw RedCapErrors.couldNotCreateRequest
        }
        
        let (data,response) = try await URLSession.shared.data(for: request)
        //print(String(data: request.httpBody!,encoding: .utf8)!)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            let _ = response as? HTTPURLResponse
            //print(String(data: request.httpBody!,encoding: .utf8)!)
            throw RedCapErrors.invalidResponse
        }
        guard let surveyURLString = String(data: data, encoding: .utf8) else {
            throw RedCapErrors.invalidURL
        }
        
        guard let surveyURL = URL(string: surveyURLString) else {
            throw RedCapErrors.invalidURL
        }
        
        return surveyURL
    }
    
    func fetchSurveyStatus(for recordID:String, event:Event, arm:UserGroup) async throws -> [SurveyStatusCellModel] {
        let formEventMapping = try await getFormEventMapping(arm: arm)
            .filter { $0.eventName == event.uniqueEventName }
        
        return try await withThrowingTaskGroup(of: SurveyStatusCellModel.self) { group in
            for form in formEventMapping {
                group.addTask {
                    let formCompletionStatus = try await self.getSurveyCompletionStatus(
                        arm: arm,
                        eventName: event.uniqueEventName,
                        recordID: recordID,
                        surveyName: form.form
                    )
                    let surveyLink = try await self.fetchSurveyLink(
                        recordID: recordID,
                        event: event.uniqueEventName,
                        surveyName: form.form
                    )
                    
                    return SurveyStatusCellModel(
                        surveyName: form.form,
                        surveyURL: surveyLink,
                        status: formCompletionStatus
                    )
                }
            }
            
            var tmp: [SurveyStatusCellModel] = []
            for try await model in group {
                tmp.append(model)
            }
            return tmp
        }
    }
    
//    func fetchSurveyStatus(for recordID:String, event:Event, arm:UserGroup) async throws -> [SurveyStatusCellModel] {
//        //fetch all forms for event
//        let formEventMapping = try await getFormEventMapping(arm: arm).filter{$0.eventName == event.uniqueEventName}
//        print(formEventMapping)
//       
//        var surveys: [SurveyStatusCellModel] = []
//        //for each form fetch the completion status
//        //for each form fetch the surveyLink
//        for form in formEventMapping {
//            let formCompletionStatus = try await getSurveyCompletionStatus(arm: arm, eventName: event.uniqueEventName, recordID: recordID, surveyName: form.form)
//            let surveyLink = try await fetchSurveyLink(recordID: recordID, event: event.uniqueEventName, surveyName: form.form)
//            let model = SurveyStatusCellModel(surveyName: form.form, surveyURL: surveyLink, status: formCompletionStatus)
//            surveys.append(model)
//            
//        }
//        return surveys
//            
//    }
    
}
