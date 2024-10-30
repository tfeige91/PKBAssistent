//
//  UPDRSRecordedItem+CoreDataProperties.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 16.06.23.
//
//

import Foundation
import CoreData


extension UPDRSRecordedItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UPDRSRecordedItem> {
        return NSFetchRequest<UPDRSRecordedItem>(entityName: "UPDRSRecordedItem")
    }

    @NSManaged public var orderNumber: Int16
    @NSManaged public var name: String?
    @NSManaged public var videoURL: URL?
    @NSManaged public var date: Date?
    @NSManaged public var rating: Int16
    @NSManaged public var session: Session?
    @NSManaged public var siteRaw: String

    public var wrappedName: String {
        name ?? "UPDRS Aufnahme"
    }
    
    
    
    public var wrappedDate: Date {
        return date ?? Date(timeIntervalSinceReferenceDate: 190_058_400.0)
    }
    
    var daytime: Daytime {
        wrappedDate.getTimeOfDay()
    }
    
    var site: Site {
        get { return Site(rawValue: siteRaw) ?? .none }
        set { siteRaw = newValue.rawValue }
    }
    
    public var displayName: String {
        let site: String = switch site {
        case .left: "links"
        case .right:"rechts"
        case .none:  ""
        }
        
        let displayName: String = if wrappedName == UPDRSItemName.Sitting.rawValue {"Ruhetremor"}
            else if wrappedName == UPDRSItemName.MovementTremor.rawValue {"Bewegungstremor"}
            else if wrappedName == UPDRSItemName.Fingertap.rawValue {"Finger Tippen"}
            else if wrappedName == UPDRSItemName.PronationSupination.rawValue {"Pronation/Supination"}
            else if wrappedName == UPDRSItemName.ToeTapping.rawValue {"Fußtippen"}
            else if wrappedName == UPDRSItemName.Walking.rawValue {"Gehen"}
            else {""}
        
        
        let displayString = displayName + " " + site
        return displayString
    }
}

extension UPDRSRecordedItem : Identifiable {

}
