//
//  NotificationsViewController.swift
//  Syllable
//
//  Created by Jarvis Zhaowei Wu on 2021-04-06.
//  Copyright © 2021 jarviswu. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import AVFoundation

enum FeedbackResult {
    case good
    case bad
    case none
}

enum NotificationCategory {
    case giveFeedback
    case receiveFeedback
}

struct NotificationItem {
    var personId: String
    var personImage: UIImage?
    var personName: String
    var category: NotificationCategory
    var result: FeedbackResult
    var practiceTimestamp: TimeInterval?
    var evaluationTimestamp: TimeInterval?
}

class NotificationsViewController: UIViewController {

    var playingCell: GiveEvaluationTableViewCell?
    var audioPlayer: AVAudioPlayer!
    var audioSession: AVAudioSession!

    var refHandle: DatabaseHandle!
    var databaseRef = Database.database().reference()
    var storageRef = Storage.storage().reference()

    let lightHapticGenerator = UIImpactFeedbackGenerator(style: .light)

    var feedbackResultNotifications = [NotificationItem]() {
        didSet {
            if feedbackResultNotificationsCount != 0 && feedbackResultNotifications.count == feedbackResultNotificationsCount {
                sortedItems.append(contentsOf: feedbackResultNotifications)
            }
        }
    }
    var feedbackRequestNotifications = [NotificationItem]() {
        didSet {
            if feedbackRequestNotificationsCount != 0 && feedbackRequestNotifications.count == feedbackRequestNotificationsCount {
                sortedItems.append(contentsOf: feedbackRequestNotifications)
            }
        }
    }
    var sortedItems = [NotificationItem]() {
        didSet {
            if feedbackResultNotificationsCount + feedbackRequestNotificationsCount != 0 && sortedItems.count == feedbackResultNotificationsCount + feedbackRequestNotificationsCount {
                // this way we only load the table once
                // there are two timestamp for each practice-evaluation item
                sortedItems.sort { (first, second) -> Bool in
                    let firstReferenceTimestamp = first.category == .giveFeedback ? first.evaluationTimestamp : first.practiceTimestamp
                    let secondReferenceTimestamp = second.category == .giveFeedback ? second.evaluationTimestamp : second.practiceTimestamp
                    return firstReferenceTimestamp! > secondReferenceTimestamp!
                }
                tableView.reloadData()
            }
        }
    }
    var feedbackResultNotificationsCount = 0
    var feedbackRequestNotificationsCount = 0

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.tableHeaderView = UIView()
        populateFeedbackResultNotifications()
        populateFeedbackRequestNotifications()
        lightHapticGenerator.prepare()
        preparePlaying()
    }

    func populateFeedbackRequestNotifications() {
        refHandle = databaseRef.child("evaluations/\(User.currentUser!.id)").observe(DataEventType.value, with: { (snapshot) in
            self.feedbackRequestNotifications = []
            let dataDict = snapshot.value as? [String : [String : AnyObject]] ?? [:]

            // remove items in dict that already has feedback (should we do this? i.e. removing evaluated items from the list)
            let itemsWithoutFeedback = dataDict // note: all items are kept now!!!!
//            let itemsWithoutFeedback = dataDict.filter { (keyValue) -> Bool in
//                let result = keyValue.value["result"] as! String
//                return result == "none"
//            }

            self.feedbackRequestNotificationsCount = itemsWithoutFeedback.count

            for (userId, itemDict) in itemsWithoutFeedback {
                var result = FeedbackResult.none
                switch itemDict["result"] as! String {
                case "good":
                    result = .good
                case "bad":
                    result = .bad
                default:
                    break
                }
                let timestamp = itemDict["practiceTimestamp"] as! TimeInterval

                self.refHandle = self.databaseRef.child("users/\(userId)").observe(DataEventType.value, with: { (snapshot) in
                    let dataDict = snapshot.value as? [String : AnyObject] ?? [:]
                    let firstName = dataDict["firstName"] as! String
                    let middleName = dataDict["middleName"] as? String
                    let lastName = dataDict["lastName"] as! String
                    let fullName = User.buildFullName(firstName: firstName, middleName: middleName, lastName: lastName)

                    var profileImage: UIImage? = nil
                    let profilePictureRef = self.storageRef.child("profile-pictures/\(userId).jpg")
                    profilePictureRef.getData(maxSize: 3 * 1024 * 1024) { (data, error) in
                        if let error = error {
                            print("Error when downloading the profile picture: \(error.localizedDescription)")
                        } else {
                            profileImage = UIImage(data: data!)

                            /// - TODO: we should still show other info if image is not loading for some reason...
                            let item = NotificationItem(personId: userId, personImage: profileImage, personName: fullName, category: .giveFeedback, result: result, practiceTimestamp: timestamp)
                            if self.feedbackRequestNotifications.count != 0 && self.feedbackRequestNotifications.count == self.feedbackRequestNotificationsCount {
                                // updating
                                if let index = self.feedbackRequestNotifications.firstIndex(where: {$0.personId == item.personId}) {
                                    self.feedbackRequestNotifications[index] = item
                                }
                            } else {
                                // populating
                                self.feedbackRequestNotifications.append(item)
                            }
                        }
                    }
                })
            }
        })
    }

    func populateFeedbackResultNotifications() {
        refHandle = databaseRef.child("practices/\(User.currentUser!.id)").observe(DataEventType.value, with: { (snapshot) in
            self.feedbackResultNotifications = []
            let dataDict = snapshot.value as? [String : [String : AnyObject]] ?? [:]

            // remove items in dict that has no feedback yet
            let itemsWithFeedback = dataDict.filter { (keyValue) -> Bool in
                let result = keyValue.value["result"] as! String
                return result != "none"
            }

            self.feedbackResultNotificationsCount = itemsWithFeedback.count

            for (userId, itemDict) in itemsWithFeedback {
                var result = FeedbackResult.none
                switch itemDict["result"] as! String {
                case "good":
                    result = .good
                case "bad":
                    result = .bad
                default:
                    break
                }

                let timestamp = itemDict["evaluationTimestamp"] as! TimeInterval

                self.refHandle = self.databaseRef.child("users/\(userId)").observe(DataEventType.value, with: { (snapshot) in
                    let dataDict = snapshot.value as? [String : AnyObject] ?? [:]
                    let firstName = dataDict["firstName"] as! String
                    let middleName = dataDict["middleName"] as? String
                    let lastName = dataDict["lastName"] as! String
                    let fullName = User.buildFullName(firstName: firstName, middleName: middleName, lastName: lastName)

                    var profileImage: UIImage? = nil
                    let profilePictureRef = self.storageRef.child("profile-pictures/\(userId).jpg")
                    profilePictureRef.getData(maxSize: 3 * 1024 * 1024) { (data, error) in
                        if let error = error {
                            print("Error when downloading the profile picture: \(error.localizedDescription)")
                        } else {
                            profileImage = UIImage(data: data!)

                            /// - TODO: we should still show other info if image is not loading for some reason...
                            let item = NotificationItem(personId: userId, personImage: profileImage, personName: fullName, category: .receiveFeedback, result: result, evaluationTimestamp: timestamp)
                            if self.feedbackResultNotifications.count != 0 && self.feedbackResultNotifications.count == self.feedbackResultNotificationsCount {
                                // updating
                                if let index = self.feedbackResultNotifications.firstIndex(where: {$0.personId == item.personId}) {
                                    self.feedbackResultNotifications[index] = item
                                }
                            } else {
                                // populating
                                self.feedbackResultNotifications.append(item)
                            }
                        }
                    }
                })
            }
        })
    }

    func attributedText(withString string: String, boldString: String, font: UIFont) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: string, attributes: [NSAttributedString.Key.font: font])
        let boldFontAttribute: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: font.pointSize)]
        let range = (string as NSString).range(of: boldString)
        attributedString.addAttributes(boldFontAttribute, range: range)
        return attributedString
    }

    func preparePlaying() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true)
            audioSession.requestRecordPermission() { allowed in
                DispatchQueue.main.async { if !allowed { print("Permission denied") } }
            }
        } catch {
            print("Error when preparing audio recorder: \(error)")
        }
    }

}

extension NotificationsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedbackResultNotificationsCount + feedbackRequestNotificationsCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // the data could be give feedback (i.e. receive feedback request) or receive feedback
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GiveEvaluationTableViewCell", for: indexPath) as? GiveEvaluationTableViewCell else { return UITableViewCell() }

        let item = sortedItems[indexPath.row]

        let name = item.personName
        var message: String = ""
        switch item.category {
        case .giveFeedback:
            if item.result == .none {
                message = "\(name) practiced your name. Listen and give a feedback!"
            } else {
                message = "\(name) practiced your name. You already gave a feedback."
            }
        case .receiveFeedback:
            message = "\(name) listened to your pronunciation and gave a feedback."
        }
        cell.messageLabel.attributedText = attributedText(withString: message, boldString: name, font: .systemFont(ofSize: 15))

        cell.profileImageView.image = item.personImage

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy hh:mm"
        let timestamp = item.category == .giveFeedback ? item.practiceTimestamp! : item.evaluationTimestamp!
        let dateString = dateFormatter.string(from: Date(timeIntervalSince1970: timestamp))
        cell.dateTimeLabel.text = dateString

        switch item.category {
        case .giveFeedback:
            if item.result == .none {
                cell.goodEvaluationButton.disable()
                cell.badEvaluationButton.disable()
            } else if item.result == .good {
                cell.badEvaluationButton.disable()
            } else if item.result == .bad {
                cell.goodEvaluationButton.disable()
            }
        case .receiveFeedback:
            switch item.result {
            case .good:
                cell.badEvaluationButton.disable()
            case .bad:
                cell.goodEvaluationButton.disable()
            case .none: // should never reach here..
                cell.goodEvaluationButton.disable()
                cell.badEvaluationButton.disable()
            }
        }

        let backgroundView = UIView()
        backgroundView.backgroundColor = .systemGray6
        cell.selectedBackgroundView = backgroundView

        cell.delegate = self

        return cell
    }

}

extension NotificationsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

/// - TODO: udpate eval in both "practices" and "evaluations"; and update timestamp for eval

extension NotificationsViewController: NotificationTableViewCellDelegate {

    func shouldPlayPracticeAudio(from indexPath: IndexPath) {
        lightHapticGenerator.impactOccurred()
        lightHapticGenerator.prepare()
        let item = sortedItems[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath) as! GiveEvaluationTableViewCell
        cell.playButton.alpha = 0
        cell.audioLoadingActivityIndicator.startAnimating()
        var audioRef: StorageReference!
        switch item.category {
        case .giveFeedback:
            audioRef = self.storageRef.child("practice-audio-recordings/practice-\(item.personId)-\(User.currentUser!.id).m4a")
        case .receiveFeedback:
            audioRef = self.storageRef.child("practice-audio-recordings/practice-\(User.currentUser!.id)-\(item.personId).m4a")
        }
        audioRef.getData(maxSize: 1 * 1024 * 1024) { (data, error) in
            if let error = error {
                print("Error when downloading the audio recording: \(error.localizedDescription)")
            } else {
                cell.audioLoadingActivityIndicator.stopAnimating()
                cell.playButton.alpha = 1
                cell.playButton.tintColor = .lightGray
                self.playingCell = cell
                do {
                    self.audioPlayer = try AVAudioPlayer(data: data!)
                    self.audioPlayer.delegate = self
                    self.audioPlayer.play()
                    // add animation
                } catch {
                    print("play failed")
                }
            }
        }
    }

    func shouldSubmitEvaluation(result: FeedbackResult, from indexPath: IndexPath) {
        lightHapticGenerator.impactOccurred()
        lightHapticGenerator.prepare()
        let item = sortedItems[indexPath.row]

        if item.category != .giveFeedback {
            return
        } else if item.result != .none {
            showToast(message: "You already submitted your feedback.", font: .systemFont(ofSize: 15))
            return
        }

        let cell = tableView.cellForRow(at: indexPath) as! GiveEvaluationTableViewCell
        if result == .good {
            cell.badEvaluationButton.disable()
        } else {
            cell.goodEvaluationButton.disable()
        }

        let timestamp = Date().timeIntervalSince1970
        self.databaseRef.child("evaluations/\(User.currentUser!.id)/\(item.personId)").updateChildValues([
            "evaluationTimestamp" : timestamp,
            "result" : (result == .good ? "good" : "bad")
        ]) { (error, ref) in
            if let error = error {
                print("Error when uploading evaluation data: \(error.localizedDescription)")
            } else {
                self.databaseRef.child("practices/\(item.personId)/\(User.currentUser!.id)").updateChildValues([
                    "evaluationTimestamp" : timestamp,
                    "result" : (result == .good ? "good" : "bad")
                ]) { (error, ref) in
                    if let error = error {
                        print("Error when uploading practice data: \(error.localizedDescription)")
                    } else {
                        self.sortedItems[indexPath.row].result = result
                        // show toast message?
                        // remove this from tableview? or not?
                        // self.sortedItems.remove(at: indexPath.row)
                    }
                }
            }
        }
    }

}

extension NotificationsViewController: AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let cell = playingCell {
            cell.playButton.tintColor = .systemBlue
            guard let indexPath = tableView.indexPath(for: cell) else { return }
            if sortedItems[indexPath.row].category == .giveFeedback {
                cell.goodEvaluationButton.enable()
                cell.badEvaluationButton.enable()
            }
        }
    }

}

/// - TODO: some observers should be nuked after use

/// - TODO: maybe fetch notifications in home screen instead so that we can display a badge
