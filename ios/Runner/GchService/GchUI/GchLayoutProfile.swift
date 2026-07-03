//
//  GchLayoutProfile.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//

import UIKit

enum GchLayoutProfile: String, CaseIterable {
    case compact, regular, expanded, floating

    var margin: CGFloat {
        switch self {
        case .compact: return 8
        case .regular: return 16
        case .expanded: return 24
        case .floating: return 12
        }
    }

    var minHeight: CGFloat {
        switch self {
        case .compact: return 36
        case .regular: return 44
        case .expanded: return 56
        case .floating: return 40
        }
    }

    var springDamping: CGFloat {
        switch self {
        case .compact: return 0.75
        case .regular: return 0.82
        case .expanded: return 0.88
        case .floating: return 0.7
        }
    }

    func apply(to view: UIView, in container: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: margin),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -margin),
            view.topAnchor.constraint(equalTo: container.topAnchor, constant: margin),
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight)
        ])
    }

    func animateAppearance(of view: UIView, duration: TimeInterval = 0.3) {
        view.alpha = 0
        view.transform = CGAffineTransform(translationX: 0, y: margin)
        UIView.animate(withDuration: duration, delay: 0,
                       usingSpringWithDamping: springDamping, initialSpringVelocity: 0.5) {
            view.alpha = 1
            view.transform = .identity
        }
    }
}
