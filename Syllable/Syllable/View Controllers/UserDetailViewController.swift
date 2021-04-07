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
import TinyConstraints

class UserDetailViewController: UIViewController, AVAudioRecorderDelegate {

    var user: User!

    let lightHapticGenerator = UIImpactFeedbackGenerator(style: .light)
    let mediumHapticGenerator = UIImpactFeedbackGenerator(style: .medium)

    var audioPlayer: AVAudioPlayer!
    var audioRecorder: AVAudioRecorder!
    var audioSession: AVAudioSession!

    var storageRef = Storage.storage().reference()
    var databaseRef = Database.database().reference()
    var refHandle: DatabaseHandle!

    var practiceMode = RecordPlayMode.record {
        didSet {
            if practiceMode == .play {
                requestEvaluationButton.enable()
                discardButton.isEnabled = true
                discardButton.isHidden = false
            } else {
                requestEvaluationButton.disable()
                discardButton.isEnabled = false
                discardButton.isHidden = true
            }
        }
    }

    /// - TODO: should allow the user to listen to their last practice audio

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

    @IBOutlet weak var lastPracticeBackgroundView: UIView!
    @IBOutlet weak var playLastPracticeButton: UIButton!
    @IBOutlet weak var lastPracticeLabel: UILabel!
    @IBOutlet weak var deleteLastPracticeButton: UIButton!
    @IBOutlet weak var evaluationResultLabel: UILabel!

    /// - TODO: put a spinner on the last practice play button

    var navbarBackgroundImage: UIImage?
    var navbarShadowImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        navbarBackgroundImage = navigationController?.navigationBar.backgroundImage(for: UIBarMetrics.default)
        navbarShadowImage = navigationController?.navigationBar.shadowImage
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        setupUI()
        setPracticeMode(mode: practiceMode)
        addGestures()
        preparePlaying()
        lightHapticGenerator.prepare()
        loadAudio()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(navbarBackgroundImage, for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = navbarShadowImage
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
        discardButton.isHidden = true
        recordButton.adjustsImageWhenHighlighted = false
        learnedButton.adjustsImageWhenHighlighted = false
        needPracticeButton.adjustsImageWhenHighlighted = false

        lastPracticeBackgroundView.layer.cornerRadius = 12

        configureStatus()
        configureLastPractice()

        if user.id == User.currentUser!.id {
            practiceTitleLabel.text = "To edit your own profile and name pronunciation, go to Settings."
            threeButtonsStackView.isHidden = true
            discardButton.isHidden = true
            requestEvaluationButton.isHidden = true
            recordButtonBackgroundView.isHidden = true
        }
    }

    func addGestures() {
        let holdGesture = UILongPressGestureRecognizer(target: self, action: #selector(didTapHoldRecordButton))
        holdGesture.minimumPressDuration = 0.3
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapRecordButton))
        recordButton.addGestureRecognizer(holdGesture)
        recordButton.addGestureRecognizer(tapGesture)
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

    func configureLastPractice() {
        refHandle = self.databaseRef.child("practices/\(User.currentUser!.id)/\(self.user.id)").observe(DataEventType.value, with: { (snapshot) in
            if let dataDict = snapshot.value as? [String : AnyObject] {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "M/d/yyyy hh:mm"
                let practiceTimestamp = dataDict["practiceTimestamp"] as? TimeInterval
                let dateString = dateFormatter.string(from: Date(timeIntervalSince1970: practiceTimestamp!))
                self.lastPracticeLabel.text = "Last practice \(dateString)"
                self.databaseRef.child("evaluations/\(self.user.id)/\(User.currentUser!.id)").observe(DataEventType.value) { (snapshot) in
                    if let dataDict = snapshot.value as? [String : AnyObject] {
                        let evaluationResult = dataDict["result"] as? String
                        var evaluationResultString = "\(self.user.firstName!) hasn't submitted a feedback yet."
                        switch evaluationResult {
                        case "good":
                            evaluationResultString = "\(self.user.firstName!) thinks this is on spot!"
                        case "bad":
                            evaluationResultString = "\(self.user.firstName!) thinks you need more practice."
                        default: // no evaluation yet
                            break
                        }
                        self.evaluationResultLabel.text = evaluationResultString
                    }
                }
            } else {
                self.lastPracticeBackgroundView.isHidden = true
            }
        })
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
        } completion: { (completed) in
            self.waveformView.highlightedSamples = Range<Int>(0...0)
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

    @IBAction func didTapDiscardButton(_ sender: UIButton) {
        let currentUser = User.currentUser!
        let fileName = "practice-\(currentUser.id)-\(user.id).m4a"
        let audioFilename = getDocumentsDirectory().appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: audioFilename)
        setPracticeMode(mode: .record)
    }

    @IBAction func didTapRequestEvaluationButton(_ sender: UIButton) {
        requestEvaluationButton.disable()
        let currentUser = User.currentUser!
        let fileName = "practice-\(currentUser.id)-\(user.id).m4a"
        let audioURL = getDocumentsDirectory().appendingPathComponent(fileName)
        let audioRef = Storage.storage().reference().child("practice-audio-recordings/\(fileName)")
        let metadata = StorageMetadata()
        metadata.contentType = "audio/m4a"
        audioRef.putFile(from: audioURL, metadata: metadata) { (metadata, error) in
            if let error = error {
                print("Error when uploading practice recording: \(error.localizedDescription)")
            } else {
                self.setPracticeMode(mode: .record)
                let timestamp = Date().timeIntervalSince1970
                self.databaseRef.child("practices/\(User.currentUser!.id)/\(self.user.id)").setValue([
                    "practiceTimestamp" : timestamp,
                    "result" : "none"
                ]) { (error, ref) in
                    if let error = error {
                        print("Error when uploading practice timestamp: \(error.localizedDescription)")
                    } else {
                        self.configureLastPractice()
                        self.lastPracticeBackgroundView.isHidden = false // show practice card
                        // push notificatios to the other user?
                        self.databaseRef.child("evaluations/\(self.user.id)/\(User.currentUser!.id)").setValue([
                            "practiceTimestamp" : timestamp,
                            "result" : "none"
                        ]) { (error, ref) in
                            if let error = error {
                                print("Error when uploading evaluation data: \(error.localizedDescription)")
                            } else {
                                // show toast message?
                            }
                        }
                    }
                }
            }
        }
    }

    @IBAction func didTapPlayLastPracticeButton(_ sender: UIButton) {
        lightHapticGenerator.prepare()
        lightHapticGenerator.impactOccurred()
        let currentUser = User.currentUser!
        let fileName = "practice-\(currentUser.id)-\(user.id).m4a"
        let audioRef = Storage.storage().reference().child("practice-audio-recordings/\(fileName)")
        audioRef.getData(maxSize: 1 * 1024 * 1024) { (data, error) in
            if let error = error {
                print("Error when downloading the practice recording: \(error.localizedDescription)")
            } else {
                do {
                    self.audioPlayer = try AVAudioPlayer(data: data!)
                    // self.audioPlayer.delegate = self
                    self.audioPlayer.play()
                    // add animation
                } catch {
                    print("play failed")
                }
            }
        }
    }

    @IBAction func didTapDeleteLastPracticeButton(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Do you want to delete the submitted practice audio?", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
            // delete audio from storage; delete practice data from database
            let currentUser = User.currentUser!
            let fileName = "practice-\(currentUser.id)-\(self.user.id).m4a"
            let audioRef = Storage.storage().reference().child("practice-audio-recordings/\(fileName)")
            audioRef.delete { (error) in
                if let error = error {
                    print("Error when deleting last practice audio from storage: \(error.localizedDescription)")
                } else {
                    self.databaseRef.child("practices/\(User.currentUser!.id)/\(self.user.id)").removeValue { (error, databaseRef) in
                        if let error = error {
                            print("Error when deleting last practice info from database: \(error.localizedDescription)")
                        } else {
                            self.lastPracticeBackgroundView.isHidden = true
                        }
                    }
                }
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    @objc func didTapHoldRecordButton(sender : UIGestureRecognizer) {
        guard practiceMode == .record else { return }
        if sender.state == .began {
            guard audioRecorder == nil else { return }
            startRecording()
            // Begin animation
            UIView.animate(withDuration: 0.8, delay: 0, options: [.repeat, .curveEaseInOut], animations: {
                self.recordButtonBackgroundView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                self.recordButtonBackgroundView.backgroundColor = .clear
            })
        } else if sender.state == .ended {
            // End animation
            self.recordButtonBackgroundView.layer.removeAllAnimations()
            UIView.animate(withDuration: 0.8, delay: 0, options: [.curveEaseIn], animations: {
                self.recordButtonBackgroundView.backgroundColor = .clear
            }) { (_) in
                self.recordButtonBackgroundView.layer.removeAllAnimations()
                self.recordButtonBackgroundView.transform = .identity
                self.recordButtonBackgroundView.backgroundColor = .systemBlue
            }
            finishRecording(success: true)
        }
    }

    @objc func didTapRecordButton(sender : UIGestureRecognizer) {
        guard practiceMode == .play else { return }
        let currentUser = User.currentUser!
        let fileName = "practice-\(currentUser.id)-\(user.id).m4a"
        let audioURL = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            lightHapticGenerator.prepare()
            lightHapticGenerator.impactOccurred()
            UIView.animate(withDuration: 0.8, delay: 0, options: [.curveEaseInOut], animations: {
                self.recordButtonBackgroundView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                self.recordButtonBackgroundView.backgroundColor = .clear
            }) { (_) in
                self.recordButtonBackgroundView.transform = .identity
                self.recordButtonBackgroundView.backgroundColor = .systemBlue
            }
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer.play()
            // add animation
        } catch {
            print("play failed")
        }
    }

    func setPracticeMode(mode: RecordPlayMode) {
        let animationDuration = self.practiceMode == mode ? 0 : 0.3
        self.practiceMode = mode
        switch mode {
        case .record:
            UIView.animate(withDuration: animationDuration) {
                self.recordButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
                // self.startOverButton.isHidden = true
            }
        case .play:
            UIView.animate(withDuration: animationDuration) {
                self.recordButton.setImage(UIImage(systemName: "headphones"), for: .normal)
                // self.startOverButton.isHidden = false
            }
        }
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }

    func startRecording() {
        let currentUser = User.currentUser!
        let fileName = "practice-\(currentUser.id)-\(user.id).m4a"
        let audioFilename = getDocumentsDirectory().appendingPathComponent(fileName)

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        mediumHapticGenerator.prepare()
        mediumHapticGenerator.impactOccurred()

        // need to have this delay, otherwise the haptic is not fired (yes super weird I know)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                self.audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
                self.audioRecorder.delegate = self
                self.audioRecorder.record()
            } catch {
                self.finishRecording(success: false)
            }
        }
    }

    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil

        lightHapticGenerator.prepare()
        lightHapticGenerator.impactOccurred()

        if success {
            setPracticeMode(mode: .play)
        } else {
            setPracticeMode(mode: .record) // or error mode?
        }
    }

}
