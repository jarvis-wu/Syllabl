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

    override func viewDidDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }

    func setupHeader() {
        profilePictureImageView.layer.cornerRadius = profilePictureImageView.frame.height / 2
        /// - TODO: What if currentUser is not stored yet? should not depend on the currentUser -> get from db/cache instead...
        guard let user = User.currentUser else { return }
        profilePictureImageView.image = user.profilePicture
        fullNameLabel.text = user.getFullName()
        secondaryLabel.text = user.getSecondaryLabel()
    }

    @IBAction func didTapEditButton(_ sender: UIButton) {
        tabBarController?.featureNotAvailable()
    }

    func logout(){
        let alertController = UIAlertController(title: "Confirm Logout", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Log out", style: .default, handler: { (action) in
            do {
                try Auth.auth().signOut()
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let rootNavigationViewController = storyboard.instantiateViewController(identifier: "RootNavigationViewController") as! UINavigationController
                let landingViewController = storyboard.instantiateViewController(identifier: "LandingViewController")
                rootNavigationViewController.viewControllers = [landingViewController]
                rootNavigationViewController.modalPresentationStyle = .fullScreen
                self.present(rootNavigationViewController, animated: true, completion: nil) // is this the right way?
            } catch let error {
                print(error.localizedDescription)
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
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
        let backgroundView = UIView()
        backgroundView.backgroundColor = .systemGray6
        cell.selectedBackgroundView = backgroundView
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
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                tabBarController?.featureNotAvailable()
            case 1:
                tabBarController?.featureNotAvailable()
            case 2:
                tabBarController?.featureNotAvailable()
            case 3:
                tabBarController?.featureNotAvailable()
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                tabBarController?.featureNotAvailable()
            case 1:
                tabBarController?.featureNotAvailable()
            default:
                break
            }
        case 2:
            switch indexPath.row {
            case 0:
                logout()
            default:
                break
            }
        default:
            break
        }
    }

}
