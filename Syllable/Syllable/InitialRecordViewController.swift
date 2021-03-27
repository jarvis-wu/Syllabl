//
//  InitialRecordViewController.swift
//  Syllable
//
//  Created by Jarvis Zhaowei Wu on 2021-03-10.
//  Copyright © 2021 jarviswu. All rights reserved.
//

import UIKit
import AVFoundation
import FirebaseStorage

class InitialRecordViewController: UIViewController, AVAudioRecorderDelegate {

    enum Mode {
        case record
        case play
    }

    var newUser: User!

    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var mode = Mode.record {
        didSet {
            if mode == .play {
                continueButton.enable()
            } else {
                continueButton.disable()
            }
        }
    }

    let lightHapticGenerator = UIImpactFeedbackGenerator(style: .light)
    let mediumHapticGenerator = UIImpactFeedbackGenerator(style: .medium)

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var recordButtonBackgroundView: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var startOverButton: UIButton!
    @IBOutlet weak var continueButton: SButton!

    @IBAction func didTapStartOverButton(_ sender: UIButton) {
        setMode(mode: .record)
    }

    @IBAction func didTapContinueButton(_ sender: SButton) {
        /// - TODO: start activity indicator
        let audioURL = getDocumentsDirectory().appendingPathComponent("\(newUser.id).m4a")
        let storageRef = Storage.storage().reference().child("audio-recordings/\(newUser.id).m4a")
        let metadata = StorageMetadata()
        metadata.contentType = "audio/m4a"
        storageRef.putFile(from: audioURL, metadata: metadata) { (metadata, error) in
            /// - TODO: end activity indicator
            if let error = error {
                print("Error when uploading audio recording: \(error.localizedDescription)")
            } else {
                self.performSegue(withIdentifier: "ShowHomeViewController", sender: self)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        continueButton.disable()
        startOverButton.isHidden = true
        recordButton.adjustsImageWhenHighlighted = false
        recordButton.layer.cornerRadius = recordButton.frame.height / 2
        recordButtonBackgroundView.layer.cornerRadius = recordButtonBackgroundView.frame.height / 2
        let holdGesture = UILongPressGestureRecognizer(target: self, action: #selector(didTapHoldRecordButton))
        holdGesture.minimumPressDuration = 0.3
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapRecordButton))
        recordButton.addGestureRecognizer(holdGesture)
        recordButton.addGestureRecognizer(tapGesture)
        setMode(mode: self.mode)
        prepareRecording()
    }

    func prepareRecording() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async { if !allowed { self.audioPermissionDenied() } }
            }
        } catch {
            self.audioPermissionDenied()
        }
    }

    func audioPermissionDenied() {
        // display some error msg
    }

    func setMode(mode: Mode) {
        let animationDuration = self.mode == mode ? 0 : 0.3
        self.mode = mode
        switch mode {
        case .record:
            recordButtonBackgroundView.backgroundColor = .systemBlue
            UIView.animate(withDuration: animationDuration) {
                self.recordButton.backgroundColor = .systemBlue
                self.recordButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
                self.startOverButton.isHidden = true
            }
            UIView.transition(with: messageLabel,
                              duration: animationDuration,
                              options: .transitionCrossDissolve) {
                self.messageLabel.text = "Tap and hold the button, say your name as normal, then release."
            }
        case .play:
            recordButtonBackgroundView.backgroundColor = .systemGreen
            UIView.animate(withDuration: animationDuration) {
                self.recordButton.backgroundColor = .systemGreen
                self.recordButton.setImage(UIImage(systemName: "headphones"), for: .normal)
                self.startOverButton.isHidden = false
            }
            UIView.transition(with: messageLabel,
                              duration: animationDuration,
                              options: .transitionCrossDissolve) {
                self.messageLabel.text = "Tap the button to listen to your recording, or discard to start over."
            }
        }
    }

    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(newUser.id).m4a")

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
            setMode(mode: .play)
        } else {
            setMode(mode: .record) // or error mode?
        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }

    @objc func didTapHoldRecordButton(sender : UIGestureRecognizer) {
        guard mode == .record else { return }
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
        guard mode == .play else { return }
        let audioURL = getDocumentsDirectory().appendingPathComponent("\(newUser.id).m4a")
        recordButtonBackgroundView.backgroundColor = .systemGreen

        do {
            lightHapticGenerator.prepare()
            lightHapticGenerator.impactOccurred()
            UIView.animate(withDuration: 0.8, delay: 0, options: [.curveEaseInOut], animations: {
                self.recordButtonBackgroundView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                self.recordButtonBackgroundView.backgroundColor = .clear
            }) { (_) in
                self.recordButtonBackgroundView.transform = .identity
                self.recordButtonBackgroundView.backgroundColor = .systemGreen
            }
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer.play()
            // add animation
        } catch {
            print("play failed")
        }
    }

}
