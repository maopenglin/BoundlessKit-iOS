//
//  RewardsViewController.swift
//  BoundlessKit_Example
//
//  Created by Akash Desai on 3/15/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

class RewardsViewController : UICollectionViewController {
    
    fileprivate let reuseIdentifier = "RewardTypeCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    fileprivate let itemsPerRow: CGFloat = 3
    
    static var current: RewardsViewController?
    
}

extension RewardsViewController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Reward.cases.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! RewardTypeCell
        
        cell.label.text = Reward.cases[indexPath.row].rawValue
        cell.layer.cornerRadius = 25
        cell.layer.borderWidth = 1
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Reward.cases[indexPath.item].test(
            viewController: self,
            view: collectionView.cellForItem(at: indexPath)!
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        RewardsViewController.current = self
    }
}


class RewardTypeCell : UICollectionViewCell {
    
    @IBOutlet weak var label: UILabel!
    
}

extension RewardsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
}
