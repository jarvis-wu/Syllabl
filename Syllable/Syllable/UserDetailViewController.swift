//
//  UserDetailViewController.swift
//  Syllable
//
//  Created by Jarvis Zhaowei Wu on 2021-03-30.
//  Copyright © 2021 jarviswu. All rights reserved.
//

import UIKit

class UserDetailViewController: UIViewController {

    var user: User!

    @IBOutlet weak var profileCardBackgroundView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var secondaryInfoLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.image = user?.profilePicture
        fullNameLabel.text = user?.getFullName()
        secondaryInfoLabel.text = user?.getSecondaryLabel()
        profileCardBackgroundView.layer.cornerRadius = 12
        profileCardBackgroundView.layer.masksToBounds = true
    }

}
