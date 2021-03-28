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

struct Country {
    let name: String
    let countryCode: String
}

class User {

    static var currentUser: User?

    public let id: String
    public private(set) var firstName: String?
    public private(set) var middleName: String?
    public private(set) var lastName: String?
    public private(set) var country: Country?
    public private(set) var faculty: String?
    public private(set) var classNumber: String?
    public private(set) var profilePicture: UIImage?
    public private(set) var status: Status = .none

    var delegate: UserEditDelegate?

    // model order of names? Last name comes first?

    init(id: String,
         firstName: String? = nil,
         middleName: String? = nil,
         lastName: String? = nil,
         country: Country? = nil,
         faculty: String? = nil,
         classNumber: String? = nil,
         profilePicture: UIImage? = nil) {
        self.id = id
        self.firstName = firstName
        self.middleName = middleName
        self.lastName = lastName
        self.country = country
        self.faculty = faculty
        self.classNumber = classNumber
        self.profilePicture = nil
    }

    init(id: String, userInfoDict: [String : AnyObject], profilePicture: UIImage?, status: Status) {
        self.id = id
        self.firstName = userInfoDict["firstName"] as? String
        self.middleName = userInfoDict["middleName"] as? String
        self.lastName = userInfoDict["lastName"] as? String
        if let countryCode = userInfoDict["countryCode"] as? String,
           let countryName = userInfoDict["countryName"] as? String {
            self.country = Country(name: countryName, countryCode: countryCode)
        }
        self.setProfilePicture(profilePicture: profilePicture)
        self.setStatus(status: status)
        // faculty
        // class number
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

    func setCountry(country: Country?) {
        self.country = country
        delegate?.didUpdateUserInformation()
    }

    func setFaculty(faculty: String?) {
        self.faculty = (faculty == "" ? nil : faculty)
        delegate?.didUpdateUserInformation()
    }

    func setClassNumber(classNumber: String?) {
        self.classNumber = (classNumber == "" ? nil : classNumber)
        delegate?.didUpdateUserInformation()
    }

    func setProfilePicture(profilePicture: UIImage?) {
        self.profilePicture = profilePicture
        delegate?.didUpdateUserInformation()
    }

    func setStatus(status: Status) {
        self.status = status
//        delegate?.didUpdateUserInformation()
    }

    func getFullName() -> String? {
        guard let firstName = firstName, let lastName = lastName else { return nil }
        let middleNameString: String
        if let middleName = middleName {
            middleNameString = "\(middleName) "
        } else {
            middleNameString = ""
        }
        return "\(firstName) \(middleNameString)\(lastName)"
    }

    func getSecondaryLabel() -> String? {
        guard let faculty = faculty, let classNumber = classNumber else { return "Unknown faculty and class" }
        return "\(faculty) \(classNumber)"
    }

    func getSelfRecording() {
        // get the file? url?
    }

    func filledAllRequiredFields() -> Bool {
        return firstName != nil && lastName != nil
    }

}
