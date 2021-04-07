//
//  User.swift
//  Syllable
//
//  Created by Jarvis Zhaowei Wu on 2021-03-11.
//  Copyright © 2021 jarviswu. All rights reserved.
//

import Foundation
import UIKit

protocol UserEditDelegate {
    func didUpdateUserInformation()
}

struct SCountry {
    let name: String
    let countryCode: String
}

class User {

    static var currentUser: User?

    public let id: String
    public private(set) var firstName: String?
    public private(set) var middleName: String?
    public private(set) var lastName: String?
    public private(set) var country: SCountry?
    public private(set) var program: String?
    public private(set) var classYear: String?
    public private(set) var profilePicture: UIImage?
    public private(set) var bio: String?

    public private(set) var status: Status = .none

    var delegate: UserEditDelegate?

    // model order of names? Last name comes first?

    init(id: String,
         firstName: String? = nil,
         middleName: String? = nil,
         lastName: String? = nil,
         country: SCountry? = nil,
         program: String? = nil,
         classYear: String? = nil,
         profilePicture: UIImage? = nil,
         bio: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.middleName = middleName
        self.lastName = lastName
        self.country = country
        self.program = program
        self.classYear = classYear
        self.profilePicture = profilePicture
        self.bio = bio
    }

    init(id: String, userInfoDict: [String : AnyObject], profilePicture: UIImage?, status: Status) {
        self.id = id
        self.firstName = userInfoDict["firstName"] as? String
        self.middleName = userInfoDict["middleName"] as? String
        self.lastName = userInfoDict["lastName"] as? String
        if let countryCode = userInfoDict["countryCode"] as? String,
           let countryName = userInfoDict["countryName"] as? String {
            self.country = SCountry(name: countryName, countryCode: countryCode)
        }
        self.setProfilePicture(profilePicture: profilePicture)
        self.setStatus(status: status)
        self.program = userInfoDict["program"] as? String
        self.classYear = userInfoDict["classYear"] as? String
        self.bio = userInfoDict["bio"] as? String
    }

    func setFirstName(firstName: String?) {
        self.firstName = (firstName == "" ? nil : firstName)
        delegate?.didUpdateUserInformation()
    }

    func setMiddleName(middleName: String?) {
        self.middleName = (middleName == "" ? nil : middleName)
        delegate?.didUpdateUserInformation()
    }

    func setLastName(lastName: String?) {
        self.lastName = (lastName == "" ? nil : lastName)
        delegate?.didUpdateUserInformation()
    }

    func setCountry(country: SCountry?) {
        self.country = country
        delegate?.didUpdateUserInformation()
    }

    func setProgram(program: String?) {
        self.program = (program == "" ? nil : program)
        delegate?.didUpdateUserInformation()
    }

    func setClassYear(classYear: String?) {
        self.classYear = (classYear == "" ? nil : classYear)
        delegate?.didUpdateUserInformation()
    }

    func setProfilePicture(profilePicture: UIImage?) {
        self.profilePicture = profilePicture
        delegate?.didUpdateUserInformation()
    }

    func setBio(bio: String?) {
        self.bio = bio
        delegate?.didUpdateUserInformation()
    }

    func setStatus(status: Status) {
        self.status = status
    }

    func getFullName() -> String? {
        guard let firstName = firstName, let lastName = lastName else { return nil }
        return User.buildFullName(firstName: firstName, middleName: middleName, lastName: lastName)
    }

    func getSecondaryLabel() -> String? {
        guard let program = program, let classYear = classYear else { return "Unknown program and class" }
        return "\(program) \(classYear)"
    }

    func getBio() -> String? {
        return bio ?? "Roses are red, violets are blue, this user did not leave any clue..."
    }

    func filledAllRequiredFields() -> Bool {
        return firstName != nil && lastName != nil
    }

    static func buildFullName(firstName: String, middleName: String?, lastName: String) -> String {
        let middleNameString: String
        if let middleName = middleName {
            middleNameString = "\(middleName) "
        } else {
            middleNameString = ""
        }
        return "\(firstName) \(middleNameString)\(lastName)"
    }

}
