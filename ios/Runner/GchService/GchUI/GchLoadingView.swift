//
//  GchLoadingView.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//

import UIKit

final class GchLoadingView: UIView {
    private let spinner = UIActivityIndicatorView(style: .large)

    private(set) var layoutProfile: GchLayoutProfile = .regular

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    func applyProfile(_ profile: GchLayoutProfile, in container: UIView) {
        layoutProfile = profile
        profile.apply(to: self, in: container)
    }

    func reveal(using profile: GchLayoutProfile? = nil, duration: TimeInterval = 0.3) {
        profile?.animateAppearance(of: self, duration: duration)
            ?? layoutProfile.animateAppearance(of: self, duration: duration)
    }

    private func setupViews() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 8
        clipsToBounds = true
    }
}
