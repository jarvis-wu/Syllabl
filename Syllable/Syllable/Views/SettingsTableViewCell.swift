//
//  SettingsTableViewCell.swift
//  Syllable
//
//  Created by Jarvis Zhaowei Wu on 2021-03-28.
//  Copyright © 2021 jarviswu. All rights reserved.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var labelView: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        iconImageView.layer.cornerRadius = 6
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
