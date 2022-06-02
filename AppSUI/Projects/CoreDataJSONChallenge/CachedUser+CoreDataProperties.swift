// CachedUser+CoreDataProperties.swift
//

import Foundation
import CoreData


extension CachedUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedUser> {
        return NSFetchRequest<CachedUser>(entityName: "CachedUser")
    }

    @NSManaged public var id: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var name: String?
    @NSManaged public var age: Int16
    @NSManaged public var company: String?
    @NSManaged public var email: String?
    @NSManaged public var address: String?
    @NSManaged public var about: String?
    @NSManaged public var registered: Date?
    @NSManaged public var tags: String?
    @NSManaged public var cachedFriends: NSSet?

    public var wrappedName: String {
        return name ?? "Unknown name"
    }

    public var wrappedCompany: String {
        return company ?? "Unknown company"
    }

    public var wrappedEmail: String {
        return email ?? "Unknown email"
    }

    public var wrappedAddress: String {
        return address ?? "Unknown address"
    }

    public var wrappedAbout: String {
        return about ?? "Unknown about"
    }

    public var tagsArray: [String] {
        return tags?.components(separatedBy: ",") ?? []
    }

    public var cachedFriendsArray: [CachedFriend] {
        return cachedFriends?.allObjects as? [CachedFriend] ?? []
    }

}

// MARK: Generated accessors for cachedFriends
extension CachedUser {

    @objc(addCachedFriendsObject:)
    @NSManaged public func addToCachedFriends(_ value: CachedFriend)

    @objc(removeCachedFriendsObject:)
    @NSManaged public func removeFromCachedFriends(_ value: CachedFriend)

    @objc(addCachedFriends:)
    @NSManaged public func addToCachedFriends(_ values: NSSet)

    @objc(removeCachedFriends:)
    @NSManaged public func removeFromCachedFriends(_ values: NSSet)

}

extension CachedUser : Identifiable {

}
