//
//  UIViewController+Toast.swift
//  Syllable
//
//  Created by Jarvis Zhaowei Wu on 2021-04-05.
//  Copyright © 2021 jarviswu. All rights reserved.
//

import Foundation
import UIKit
import TinyConstraints

/// - TODO: consider using this for toast msg instead: https://github.com/huri000/SwiftEntryKit

extension UIViewController {

    func showToast(message : String, font: UIFont) {
        var toastViewHeight: CGFloat = 60
        if let tabBarController = self as? UITabBarController {
            toastViewHeight = tabBarController.view.frame.maxY - tabBarController.tabBar.frame.minY
        }

        var safeAreaBottomInset: CGFloat = 0
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            safeAreaBottomInset = window?.safeAreaInsets.bottom ?? 0
        }
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows[0]
            safeAreaBottomInset = window.safeAreaInsets.bottom
        }

        let toastView = UIView(frame: CGRect(x: 0, y: self.view.frame.size.height - toastViewHeight, width: self.view.frame.size.width, height: toastViewHeight))
        toastView.backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        toastView.insertSubview(blurView, at: 0)
        blurView.edgesToSuperview()
        toastView.clipsToBounds = true

        let toastLabel = UILabel()
        toastView.addSubview(toastLabel)
        toastLabel.centerXToSuperview()
        if safeAreaBottomInset == 0 {
            toastLabel.centerYToSuperview()
        } else {
            toastLabel.centerYToSuperview(offset: -(safeAreaBottomInset / 2 - 10)) // 5 is a tiny offset tweak
        }
        toastLabel.centerYToSuperview()
        toastLabel.textColor = UIColor.black
        toastLabel.font = font
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 1.0
        self.view.addSubview(toastView)

        toastView.transform = CGAffineTransform(translationX: 0, y: 100)
        toastView.alpha = 0

        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn) {
            toastView.alpha = 1
            toastView.transform = .identity
        } completion: { (completed) in
            UIView.animate(withDuration: 0.5, delay: 2.0, options: .curveEaseOut, animations: {
                toastView.alpha = 0.0
                toastView.transform = CGAffineTransform(translationX: 0, y: 100)
            }, completion: {(isCompleted) in
                toastView.removeFromSuperview()
            })
        }
    }

    func featureNotAvailable() {
        showToast(message: "This feature is not available yet.", font: .systemFont(ofSize: 15))
    }

}
