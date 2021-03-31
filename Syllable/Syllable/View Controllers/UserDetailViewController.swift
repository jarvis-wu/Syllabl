//
//  UserDetailViewController.swift
//  Syllable
//
//  Created by Jarvis Zhaowei Wu on 2021-03-30.
//  Copyright © 2021 jarviswu. All rights reserved.
//

import UIKit
import SKCountryPicker
import AVFoundation
import FirebaseStorage
import FirebaseDatabase

class UserDetailViewController: UIViewController {

    var user: User!
    let lightHapticGenerator = UIImpactFeedbackGenerator(style: .light)
    var audioPlayer: AVAudioPlayer!
    var audioSession: AVAudioSession!
    var storageRef = Storage.storage().reference()
    var databaseRef = Database.database().reference()

    /// - TODO: put everything in a scroll view

    @IBOutlet weak var profileCardBackgroundView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var secondaryInfoLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var flagImageView: UIImageView!

    @IBOutlet weak var playerCardBackgroundView: UIView!
    @IBOutlet weak var playerButton: UIButton!
    @IBOutlet weak var waveformView: FDWaveformView!
    @IBOutlet weak var waveformLoadingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var waveformLoadingLabel: UILabel!

    @IBOutlet weak var practiceCardBackgroundView: UIView!
    @IBOutlet weak var practiceTitleLabel: UILabel!
    @IBOutlet weak var threeButtonsStackView: UIStackView!
    @IBOutlet weak var recordButtonBackgroundView: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var learnedButton: UIButton!
    @IBOutlet weak var needPracticeButton: UIButton!
    @IBOutlet weak var discardButton: UIButton!
    @IBOutlet weak var requestEvaluationButton: SButton!
    @IBOutlet weak var learnedCheckmarkView: UIView!
    @IBOutlet weak var needPracticeCheckmarkView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        preparePlaying()
        lightHapticGenerator.prepare()
        loadAudio()
    }

    func setupUI() {
        profileCardBackgroundView.layer.cornerRadius = 12
        profileCardBackgroundView.layer.masksToBounds = true
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.image = user?.profilePicture
        fullNameLabel.text = user?.getFullName()
        secondaryInfoLabel.text = user?.getSecondaryLabel()
        bioLabel.text = user.getBio()
        if let countryCode = user.country?.countryCode {
            flagImageView.layer.cornerRadius = 4
            flagImageView.clipsToBounds = true
            flagImageView.contentMode = .scaleAspectFill
            flagImageView.image = Country(countryCode: countryCode).flag
        } else {
            flagImageView.removeFromSuperview()
        }

        playerCardBackgroundView.layer.cornerRadius = 12
        waveformView.wavesColor = UIColor.systemGray4
        waveformView.progressColor = UIColor.systemBlue
        playerButton.isEnabled = false
        waveformLoadingActivityIndicator.startAnimating()

        practiceCardBackgroundView.layer.cornerRadius = 12
        recordButtonBackgroundView.layer.cornerRadius = recordButtonBackgroundView.frame.height / 2
        recordButton.layer.cornerRadius = recordButton.frame.height / 2
        learnedButton.layer.cornerRadius = learnedButton.frame.height / 2
        needPracticeButton.layer.cornerRadius = needPracticeButton.frame.height / 2
        requestEvaluationButton.disable()
        discardButton.isEnabled = false

        configureStatus()

        if user.id == User.currentUser!.id {
            practiceTitleLabel.text = "To edit your own profile and name pronunciation, go to Settings."
            threeButtonsStackView.isHidden = true
            discardButton.isHidden = true
            requestEvaluationButton.isHidden = true
        }
    }

    func configureStatus() {
        // show current learning status, if any
        if user.status != .learned {
            learnedCheckmarkView.isHidden = true
        }
        if user.status != .needPractice {
            needPracticeCheckmarkView.isHidden = true
        }
        learnedCheckmarkView.layer.cornerRadius = learnedCheckmarkView.frame.height / 2
        learnedCheckmarkView.layer.borderColor = UIColor.systemGreen.cgColor
        learnedCheckmarkView.layer.borderWidth = 1.5
        needPracticeCheckmarkView.layer.cornerRadius = needPracticeCheckmarkView.frame.height / 2
        needPracticeCheckmarkView.layer.borderColor = UIColor.systemYellow.cgColor
        needPracticeCheckmarkView.layer.borderWidth = 1.5
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func loadAudio() {
        print("retrieve recording and play for user \(user.id).")
        lightHapticGenerator.impactOccurred()
        lightHapticGenerator.prepare()

        let localUrl = getDocumentsDirectory().appendingPathComponent("\(user.id).m4a")
        let audioRef = self.storageRef.child("audio-recordings/\(user.id).m4a")

        let _ = audioRef.write(toFile: localUrl) { (url, error) in
            if let error = error {
                print("Error when downloading the audio: \(error.localizedDescription)")
            } else {
                self.waveformLoadingActivityIndicator.stopAnimating()
                self.waveformLoadingLabel.isHidden = true
                self.playerButton.isEnabled = true
                self.waveformView.audioURL = localUrl
            }
        }
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

    @IBAction func didTapPlayButton(_ sender: UIButton) {
        let audioURL = getDocumentsDirectory().appendingPathComponent("\(user.id).m4a")
        let asset = AVURLAsset(url: audioURL, options: nil)
        let audioDuration = asset.duration
        let audioDurationSeconds = CMTimeGetSeconds(audioDuration)
        lightHapticGenerator.impactOccurred()
        lightHapticGenerator.prepare()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                self.audioPlayer.play()
            } catch {
                print("Play failed")
            }
        }
        self.waveformView.highlightedSamples = Range<Int>(0...0)
        UIView.animate(withDuration: audioDurationSeconds) {
            self.waveformView.highlightedSamples = Range<Int>(0...self.waveformView.totalSamples)
        }
    }

    @IBAction func didTapLearnedButton(_ sender: UIButton) {
        lightHapticGenerator.impactOccurred()
        lightHapticGenerator.prepare()
        if user.status == .learned {
            print("already learned")
            // should we provide a way to deselect a status here??
        } else {
            databaseRef.child("statuses/\(User.currentUser!.id)/\(user.id)").setValue("learned") { (error, reference) in
                if let error = error {
                    print("Error when updating status: \(error.localizedDescription)")
                } else {
                    self.learnedCheckmarkView.isHidden = false
                    self.needPracticeCheckmarkView.isHidden = true
                    self.user.setStatus(status: .learned)
                }
            }
        }
    }

    @IBAction func didTapNeedPracticeButton(_ sender: UIButton) {
        lightHapticGenerator.impactOccurred()
        lightHapticGenerator.prepare()
        if user.status == .needPractice {
            print("already needPractice")
            // should we provide a way to deselect a status here??
        } else {
            databaseRef.child("statuses/\(User.currentUser!.id)/\(user.id)").setValue("needPractice") { (error, reference) in
                if let error = error {
                    print("Error when updating status: \(error.localizedDescription)")
                } else {
                    self.learnedCheckmarkView.isHidden = true
                    self.needPracticeCheckmarkView.isHidden = false
                    self.user.setStatus(status: .needPractice)
                }
            }
        }
    }

    @IBAction func didTapRequestEvaluationButton(_ sender: UIButton) {

    }

}
