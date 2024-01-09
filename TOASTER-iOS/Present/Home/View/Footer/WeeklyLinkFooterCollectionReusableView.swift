//
//  WeeklyLinkFooterCollectionReusableView.swift
//  TOASTER-iOS
//
//  Created by Gahyun Kim on 2024/01/10.
//

import UIKit

import SnapKit
import Then

// MARK: - 이주의 추천 사이트 footer

final class WeeklyLinkFooterCollectionReusableView: UICollectionReusableView {
    
    // MARK: - Properties
    
    private let divideView = UIView()
    
    // MARK: - Life Cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configure() {
        setupStyle()
        setupHierarchy()
        setupLayout()
    }
    
    // MARK: - set up Style
    
    private func setupStyle() {
        divideView.do {
            $0.backgroundColor = .gray50
        }
    }
    
    // MARK: - set up Hierarchy
    
    private func setupHierarchy() {
        addSubview(divideView)
    }
    
    // MARK: - set up Layout
    
    private func setupLayout() {
        divideView.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(2)
            $0.width.equalToSuperview()
            $0.height.equalTo(4)
        }
    }
}
