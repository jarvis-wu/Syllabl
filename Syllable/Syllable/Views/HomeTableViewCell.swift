//
//  HomeTableViewCell.swift
//  Syllable
//
//  Created by Jarvis Zhaowei Wu on 2021-02-26.
//  Copyright © 2021 jarviswu. All rights reserved.
//

import UIKit

protocol HomeTableViewCellDelegate {
    func shouldPlayPronunciation(withId id: String, from indexPath: IndexPath)
}

class HomeTableViewCell: UITableViewCell {

    var delegate: HomeTableViewCellDelegate?
    var userId: String?
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var secondaryInfoLabel: UILabel!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var audioLoadingActivityIndicator: UIActivityIndicatorView!

    @IBAction func didTapPlayButton(_ sender: UIButton) {
        guard let delegate = delegate,
              let userId = userId,
              let tableView = self.superview as? UITableView,
              let indexPath = tableView.indexPath(for: self) else { return }
        delegate.shouldPlayPronunciation(withId: userId, from: indexPath)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        statusView.layer.cornerRadius = statusView.frame.height / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    

}
