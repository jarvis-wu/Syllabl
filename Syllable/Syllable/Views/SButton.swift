//
//  SButton.swift
//  Syllable
//
//  Created by Jarvis Zhaowei Wu on 2021-02-25.
//  Copyright © 2021 jarviswu. All rights reserved.
//

import UIKit

class SButton: UIButton {

    private func commonInit() {
        backgroundColor = UIColor.systemBlue
        layer.cornerRadius = 15
        titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        setTitleColor(.white, for: .normal)
        setTitleColor(.systemGray2, for: .disabled)
    }

    func disable() {
        isEnabled = false
        backgroundColor = UIColor.systemGray5
    }

    func enable() {
        isEnabled = true
        backgroundColor = UIColor.systemBlue
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

}
