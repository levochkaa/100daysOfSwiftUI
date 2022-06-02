// CachedFriend+CoreDataProperties.swift
//

import Foundation
import CoreData


extension CachedFriend {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedFriend> {
        return NSFetchRequest<CachedFriend>(entityName: "CachedFriend")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var cachedUser: NSSet?

    public var wrappedName: String {
        return name ?? "Unknown name"
    }

}

// MARK: Generated accessors for cachedUser
extension CachedFriend {

    @objc(addCachedUserObject:)
    @NSManaged public func addToCachedUser(_ value: CachedUser)

    @objc(removeCachedUserObject:)
    @NSManaged public func removeFromCachedUser(_ value: CachedUser)

    @objc(addCachedUser:)
    @NSManaged public func addToCachedUser(_ values: NSSet)

    @objc(removeCachedUser:)
    @NSManaged public func removeFromCachedUser(_ values: NSSet)

}

extension CachedFriend : Identifiable {

}
