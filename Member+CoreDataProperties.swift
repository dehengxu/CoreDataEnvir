//
//  Member+CoreDataProperties.swift
//  
//
//  Created by NicholasXu on 2020/9/14.
//
//

import Foundation
import CoreData


extension Member {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Member> {
        return NSFetchRequest<Member>(entityName: "Member")
    }

    @NSManaged public var age: NSNumber?
    @NSManaged public var birthday: Date?
    @NSManaged public var name: String?
    @NSManaged public var phonenum: String?
    @NSManaged public var belongedTeam: Team?

}
