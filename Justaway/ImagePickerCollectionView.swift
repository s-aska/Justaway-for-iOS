//
//  ImagePickerCollectionView.swift
//  Justaway
//
//  Created by Shinichiro Aska on 9/12/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import Photos

class ImagePickerCollectionView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    let manager = PHImageManager.defaultManager()
    var rows = [PHAsset]()
    var highlightRows = [PHAsset]()
    var callback: (PHAsset -> Void)?
    var cellSize = CGSize(width: 80, height: 80)

    override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
    }

    func configureView() {
        let nib = UINib(nibName: "ImageCell", bundle: nil)
        self.registerNib(nib, forCellWithReuseIdentifier: "ImageCell")
        self.delegate = self
        self.dataSource = self
        let width = (UIScreen.mainScreen().bounds.size.width / 4)
        self.cellSize = CGSize(width: width, height: width)
    }


    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // swiftlint:disable:next force_cast
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ImageCell", forIndexPath: indexPath) as! ImageCell
        let row = rows[indexPath.row]
        cell.tag = indexPath.row
        cell.asset = row

        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return cell
        }
        let itemSize = layout.itemSize

        manager.requestImageForAsset(row,
            targetSize: itemSize,
            contentMode: .AspectFill,
            options: nil) { (image, info) -> Void in
                if cell.tag == indexPath.row {
                    cell.imageView.alpha = self.isHighlight(row) ? 0.3 : 1
                    cell.imageView.contentMode = .ScaleAspectFill
                    cell.imageView.image = image
                }
        }

        return cell
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rows.count
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let row = rows[indexPath.row]
        callback?(row)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return cellSize
    }
    
    func isHighlight(asset: PHAsset) -> Bool {
        for highlightRow in highlightRows {
            if highlightRow == asset {
                return true
            }
        }
        return false
    }

    func reloadHighlight() {
        for cell in visibleCells() as? [ImageCell] ?? [] {
            if let asset = cell.asset {
                cell.imageView.alpha = self.isHighlight(asset) ? 0.3 : 1
            }
        }
    }
}
