//
//  GiveEvaluationTableViewCell.swift
//  Syllable
//
//  Created by Jarvis Zhaowei Wu on 2021-04-06.
//  Copyright © 2021 jarviswu. All rights reserved.
//

import UIKit
import TinyConstraints

protocol NotificationTableViewCellDelegate {
    func shouldPlayPracticeAudio(from indexPath: IndexPath)
    func shouldSubmitEvaluation(result: FeedbackResult, from indexPath: IndexPath)
}

class GiveEvaluationTableViewCell: UITableViewCell {

    var delegate: NotificationTableViewCellDelegate?

    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var goodEvaluationButton: SButton!
    @IBOutlet weak var badEvaluationButton: SButton!
    @IBOutlet weak var audioLoadingActivityIndicator: UIActivityIndicatorView!

    override func awakeFromNib() {
        super.awakeFromNib()
        profileImageView.height(40)
        profileImageView.layer.cornerRadius = 20
        badEvaluationButton.layer.cornerRadius = 8
        goodEvaluationButton.layer.cornerRadius = 8
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func didTapPlayButton(_ sender: UIButton) {
        guard let delegate = delegate,
              let tableView = self.superview as? UITableView,
              let indexPath = tableView.indexPath(for: self) else { return }
        delegate.shouldPlayPracticeAudio(from: indexPath)
    }

    @IBAction func didTapGoodButton(_ sender: SButton) {
        guard let delegate = delegate,
              let tableView = self.superview as? UITableView,
              let indexPath = tableView.indexPath(for: self) else { return }
        delegate.shouldSubmitEvaluation(result: .good, from: indexPath)
    }

    @IBAction func didTapBadButton(_ sender: SButton) {
        guard let delegate = delegate,
              let tableView = self.superview as? UITableView,
              let indexPath = tableView.indexPath(for: self) else { return }
        delegate.shouldSubmitEvaluation(result: .bad, from: indexPath)
    }

}
