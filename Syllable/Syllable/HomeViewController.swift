//
//  HomeViewController.swift
//  Syllable
//
//  Created by Jarvis Zhaowei Wu on 2021-02-25.
//  Copyright © 2021 jarviswu. All rights reserved.
//

import UIKit

enum Status {
    case none
    case learned
    case needPractice
}

class HomeViewController: UIViewController {

    var users = [User]()

    var statuses = [Int : Status]()

    var filteredUsers = [User]()

    var isSearchBarEmpty: Bool {
      return searchController.searchBar.text?.isEmpty ?? true
    }

    var isFiltering: Bool {
      return searchController.isActive && !isSearchBarEmpty
    }

    let searchController = UISearchController(searchResultsController: nil)

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        populateUsers()
        populateStatuses()
        tableView.dataSource = self
        tableView.delegate = self
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for a name or a program"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    /// - TODO: pagination?
    private func populateUsers() {
        users = [
            User(id: 0, firstName: "Viktor", lastName: "Aarstad", faculty: "Software Engineering", classNumber: "2021"),
            User(id: 1, firstName: "Iris", lastName: "Alcocer", faculty: "Software Engineering", classNumber: "2021"),
            User(id: 2, firstName: "Geosha", lastName: "Alexander", faculty: "Computer Science", classNumber: "2021"),
            User(id: 3, firstName: "Jaymore", lastName: "Austin", faculty: "Physics", classNumber: "2021"),
            User(id: 4, firstName: "Hsueh", middleName: "Feng", lastName: "Bai", faculty: "Computer Science", classNumber: "2021"),
            User(id: 5, firstName: "Chunying", lastName: "Bao", faculty: "Software Engineering", classNumber: "2021"),
            User(id: 6, firstName: "Maha", lastName: "Bhaumik", faculty: "Political Science", classNumber: "2021"),
            User(id: 7, firstName: "Acilio", lastName: "Bona", faculty: "Software Engineering", classNumber: "2021"),
            User(id: 8, firstName: "Wenbin", lastName: "Bu", faculty: "Computer Science", classNumber: "2021")
        ]
    }

    private func populateStatuses() {
        statuses = [
            0 : .needPractice,
            1 : .none,
            2 : .learned,
            3 : .learned,
            4 : .needPractice,
            5 : .needPractice,
            6 : .none,
            7 : .none,
            8 : .learned,
        ]
    }

    func filterContentForSearchText(_ searchText: String) {
      filteredUsers = users.filter { (item: User) -> Bool in
        let fullName = "\(item.firstName) \(item.lastName)"
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
        cell.profileImageView.image = UIImage(named: user.getProfilePictureName())
        guard let status = statuses[user.id] else { return UITableViewCell() }
        switch status {
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
        return 80
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

    func shouldPlayPronunciation(withId id: Int) {
        print("retrieve recording and play for user \(id).")
    }

}
