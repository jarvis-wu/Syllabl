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

class UserDetailViewController: UIViewController {

    var user: User!
    let lightHapticGenerator = UIImpactFeedbackGenerator(style: .light)
    var audioPlayer: AVAudioPlayer!
    var audioSession: AVAudioSession!
    var storageRef = Storage.storage().reference()

    @IBOutlet weak var profileCardBackgroundView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var secondaryInfoLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var flagImageView: UIImageView!

    @IBOutlet weak var playerCardBackgroundView: UIView!
    @IBOutlet weak var playerButton: UIButton!
    @IBOutlet weak var waveformView: FDWaveformView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        preparePlaying()
        loadAudio()
    }

    func setupUI() {
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.image = user?.profilePicture
        fullNameLabel.text = user?.getFullName()
        secondaryInfoLabel.text = user?.getSecondaryLabel()
        profileCardBackgroundView.layer.cornerRadius = 12
        profileCardBackgroundView.layer.masksToBounds = true
        playerCardBackgroundView.layer.cornerRadius = 12
        if let countryCode = user.country?.countryCode {
            flagImageView.layer.cornerRadius = 4
            flagImageView.clipsToBounds = true
            flagImageView.contentMode = .scaleAspectFill
            flagImageView.image = Country(countryCode: countryCode).flag
        } else {
            flagImageView.removeFromSuperview()
        }
        waveformView.wavesColor = UIColor.systemGray4
        waveformView.progressColor = UIColor.systemBlue
        playerButton.isEnabled = false
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func loadAudio() {
        print("retrieve recording and play for user \(user.id).")
        lightHapticGenerator.prepare()
        lightHapticGenerator.impactOccurred()

        let localUrl = getDocumentsDirectory().appendingPathComponent("\(user.id).m4a")
        let audioRef = self.storageRef.child("audio-recordings/\(user.id).m4a")

        let _ = audioRef.write(toFile: localUrl) { (url, error) in
            if let error = error {
                print("Error when downloading the audio: \(error.localizedDescription)")
            } else {
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
        lightHapticGenerator.prepare()
        lightHapticGenerator.impactOccurred()
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

}
