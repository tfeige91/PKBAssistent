//
//  Session+CoreDataProperties.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 16.06.23.
//
//

import Foundation
import CoreData


extension Session {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Session> {
        return NSFetchRequest<Session>(entityName: "Session")
    }

    @NSManaged public var id: Int16
    @NSManaged public var date: Date?
    @NSManaged public var recordedItems: NSSet?
    
    //get date or the time of Steve Jobs iPhone presentation easter egg
    public var wrappedDate: Date {
        return date ?? Date(timeIntervalSinceReferenceDate: 190_058_400.0)
    }
    
    public var recordedItemsArray: [UPDRSRecordedItem] {
        let set = recordedItems as? Set<UPDRSRecordedItem> ?? []
        
        return set.sorted { item1, item2 in
            item1.orderNumber < item2.orderNumber
        }
    }
}

// MARK: Generated accessors for recordedItems
extension Session {

    @objc(addRecordedItemsObject:)
    @NSManaged public func addToRecordedItems(_ value: UPDRSRecordedItem)

    @objc(removeRecordedItemsObject:)
    @NSManaged public func removeFromRecordedItems(_ value: UPDRSRecordedItem)

    @objc(addRecordedItems:)
    @NSManaged public func addToRecordedItems(_ values: NSSet)

    @objc(removeRecordedItems:)
    @NSManaged public func removeFromRecordedItems(_ values: NSSet)

}

extension Session : Identifiable {

}
