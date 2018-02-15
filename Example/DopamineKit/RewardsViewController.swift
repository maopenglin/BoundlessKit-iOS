//
//  RewardsViewController.swift
//  DopamineKit_Example
//
//  Created by Akash Desai on 2/14/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

class RewardsViewController : UICollectionViewController {
    
    fileprivate let reuseIdentifier = "RewardTypeCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    fileprivate let itemsPerRow: CGFloat = 3
    
    var collectionObjects = ["one", "two", "three"]
    
    @objc class func instance() -> RewardsViewController {
        let _ = ViewController.setReward
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RewardsViewController") as! RewardsViewController
    }
    
    override func viewDidLoad() {
        
        collectionView?.backgroundColor = .orange
    }
    
    
    
}

extension RewardsViewController {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionObjects.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! RewardTypeCell
        
        cell.backgroundColor = .gray
        cell.label.text = collectionObjects[indexPath.row]
        
        return cell
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
