//
//  HomeViewController.swift
//  Syllable
//
//  Created by Jarvis Zhaowei Wu on 2021-02-25.
//  Copyright © 2021 jarviswu. All rights reserved.
//

import UIKit
import AVFoundation
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

enum Status {
    case none
    case learned
    case needPractice
}

class HomeViewController: UIViewController {

    var users = [User]()
    var filteredUsers = [User]()

    var databaseRef = Database.database().reference()
    var storageRef = Storage.storage().reference()
    var refHandle: DatabaseHandle!

    var audioPlayer: AVAudioPlayer!

    var isSearchBarEmpty: Bool {
      return searchController.searchBar.text?.isEmpty ?? true
    }

    var isFiltering: Bool {
      return searchController.isActive && !isSearchBarEmpty
    }

    let searchController = UISearchController(searchResultsController: nil)
    let lightHapticGenerator = UIImpactFeedbackGenerator(style: .light)

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        populateUsers()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for a name or a program"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    /// - TODO: pagination?
    private func populateUsers() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        refHandle = databaseRef.child("users").observe(DataEventType.value, with: { (snapshot) in
            self.users = []
            let dataDict = snapshot.value as? [String : [String : AnyObject]] ?? [:]
            for (userId, userInfoDict) in dataDict {
                var status = Status.none
                self.refHandle = self.databaseRef.child("statuses").child(currentUid).child(userId).observe(DataEventType.value, with: { (snapshot) in
                    let statusString = snapshot.value as? String
                    switch statusString {
                    case "learned":
                        status = .learned
                    case "needPractice":
                        status = .needPractice
                    default:
                        break // default none
                    }
                    var profileImage: UIImage? = nil
                    let profilePictureRef = self.storageRef.child("profile-pictures/\(userId).jpg")
                    profilePictureRef.getData(maxSize: 3 * 1024 * 1024) { (data, error) in
                        if let error = error {
                            print("Error when downloading the profile picture: \(error.localizedDescription)")
                        } else {
                            profileImage = UIImage(data: data!)
                        }
                        let user = User(id: userId, userInfoDict: userInfoDict, profilePicture: profileImage, status: status)
                        if user.id == Auth.auth().currentUser?.uid {
                            User.currentUser = user
                        }
                        self.users.append(user)
                        self.tableView.reloadData() // inefficient?
                    }
                })
            }
        })

        // mock data
//        users = [
//            User(id: "0", firstName: "Viktor", lastName: "Aarstad", faculty: "Software Engineering", classNumber: "2021"),
//            User(id: "1", firstName: "Iris", lastName: "Alcocer", faculty: "Software Engineering", classNumber: "2021"),
//            User(id: "2", firstName: "Geosha", lastName: "Alexander", faculty: "Computer Science", classNumber: "2021"),
//            User(id: "3", firstName: "Jaymore", lastName: "Austin", faculty: "Physics", classNumber: "2021"),
//            User(id: "4", firstName: "Hsueh", middleName: "Feng", lastName: "Bai", faculty: "Computer Science", classNumber: "2021"),
//            User(id: "5", firstName: "Chunying", lastName: "Bao", faculty: "Software Engineering", classNumber: "2021"),
//            User(id: "6", firstName: "Maha", lastName: "Bhaumik", faculty: "Political Science", classNumber: "2021"),
//            User(id: "7", firstName: "Acilio", lastName: "Bona", faculty: "Software Engineering", classNumber: "2021"),
//            User(id: "8", firstName: "Wenbin", lastName: "Bu", faculty: "Computer Science", classNumber: "2021")
//        ]
    }

    func filterContentForSearchText(_ searchText: String) {
      filteredUsers = users.filter { (user: User) -> Bool in
        let fullName = user.getFullName() ?? ""
        return fullName.lowercased().contains(searchText.lowercased())
      }
      tableView.reloadData()
    }

}

extension HomeViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
          return filteredUsers.count
        }
        return users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HomeTableViewCell", for: indexPath) as? HomeTableViewCell else { return UITableViewCell() }
        let user: User
        if isFiltering {
            user = filteredUsers[indexPath.row]
        } else {
            user = users[indexPath.row]
        }
        cell.delegate = self
        cell.userId = user.id
        cell.nameLabel.text = user.getFullName()
        cell.secondaryInfoLabel.text = user.getSecondaryLabel()
        cell.profileImageView.image = user.profilePicture
        switch user.status {
        case .none:
            cell.statusView.backgroundColor = .systemGray5
        case .learned:
            cell.statusView.backgroundColor = .systemGreen
        case .needPractice:
            cell.statusView.backgroundColor = .systemYellow
        }
        return cell
    }

}

extension HomeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

extension HomeViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
  }

}

extension HomeViewController: HomeTableViewCellDelegate {

    func shouldPlayPronunciation(withId id: String) {
        print("retrieve recording and play for user \(id).")
        lightHapticGenerator.prepare()
        lightHapticGenerator.impactOccurred()
        let audioRef = self.storageRef.child("audio-recordings/\(id).m4a")
        audioRef.getData(maxSize: 1 * 1024 * 1024) { (data, error) in
            if let error = error {
                print("Error when downloading the audio recording: \(error.localizedDescription)")
            } else {
                do {
                    self.audioPlayer = try AVAudioPlayer(data: data!)
                    self.audioPlayer.play()
                    // add animation
                } catch {
                    print("play failed")
                }
            }
        }
    }

}
