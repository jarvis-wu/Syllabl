//
//  SettingsViewController.swift
//  Syllable
//
//  Created by Jarvis Zhaowei Wu on 2021-03-28.
//  Copyright © 2021 jarviswu. All rights reserved.
//

import UIKit
import FirebaseAuth

enum SettingsSection: Int, CaseIterable {
    case settings = 0
    case support
    case logout
}

struct SettingsRowData {
    let rowTitle: String
    let rowIconName: String
}

let settingsData: [[SettingsRowData]] = [
    [
        SettingsRowData(rowTitle: "Dark mode", rowIconName: "night"),
        SettingsRowData(rowTitle: "Data and storage", rowIconName: "database"),
        SettingsRowData(rowTitle: "Language", rowIconName: "global"),
        SettingsRowData(rowTitle: "Invite friends", rowIconName: "customer")
    ], [
        SettingsRowData(rowTitle: "Contact us", rowIconName: "email"),
        SettingsRowData(rowTitle: "Syllable FAQ", rowIconName: "question")
    ], [
        SettingsRowData(rowTitle: "Log out", rowIconName: "door")
    ]
]

class SettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var secondaryLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHeader()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.sectionFooterHeight = 10
        tableView.alwaysBounceVertical = false
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }

    func setupHeader() {
        profilePictureImageView.layer.cornerRadius = profilePictureImageView.frame.height / 2
        // What if currentUser is not stored yet?
        guard let user = User.currentUser else { return }
        profilePictureImageView.image = user.profilePicture
        fullNameLabel.text = user.getFullName()
        secondaryLabel.text = user.getSecondaryLabel()
    }

    func logout(){
        do {
            try Auth.auth().signOut()
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let rootNavigationViewController = storyboard.instantiateViewController(identifier: "RootNavigationViewController") as! UINavigationController
            let landingViewController = storyboard.instantiateViewController(identifier: "LandingViewController")
            rootNavigationViewController.viewControllers = [landingViewController]
            rootNavigationViewController.modalPresentationStyle = .fullScreen
            present(rootNavigationViewController, animated: true, completion: nil)
        } catch let error {
            print(error.localizedDescription)
        }
    }

}

extension SettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return SettingsSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsData[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsTableViewCell", for: indexPath) as? SettingsTableViewCell else { return UITableViewCell() }
        cell.labelView.text = settingsData[indexPath.section][indexPath.row].rowTitle
        cell.iconImageView.image = UIImage(named: settingsData[indexPath.section][indexPath.row].rowIconName)
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = SettingsSection(rawValue: section)!
        switch section {
        case .settings:
            return "Settings"
        case .support:
            return "Support"
        case .logout:
            return "Account"
        }
    }

}

extension SettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            if indexPath.row == 0 {
                logout()
            }
        }
    }

}
