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

    let manager = PHImageManager.default()
    var rows = [PHAsset]()
    var highlightRows = [PHAsset]()
    var callback: ((PHAsset) -> Void)?
    var cellSize = CGSize(width: 80, height: 80)

    override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
    }

    func configureView() {
        let nib = UINib(nibName: "ImageCell", bundle: nil)
        self.register(nib, forCellWithReuseIdentifier: "ImageCell")
        self.delegate = self
        self.dataSource = self
        let width = (UIScreen.main.bounds.size.width / 4)
        self.cellSize = CGSize(width: width, height: width)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // swiftlint:disable:next force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        let row = rows[indexPath.row]
        cell.tag = indexPath.row
        cell.asset = row

        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return cell
        }
        let itemSize = layout.itemSize

        manager.requestImage(for: row,
            targetSize: itemSize,
            contentMode: .aspectFill,
            options: nil) { (image, info) -> Void in
                if cell.tag == indexPath.row {
                    cell.imageView.alpha = self.isHighlight(row) ? 0.3 : 1
                    cell.imageView.contentMode = .scaleAspectFill
                    cell.imageView.image = image
                }
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rows.count
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = rows[indexPath.row]
        callback?(row)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize
    }

    func isHighlight(_ asset: PHAsset) -> Bool {
        for highlightRow in highlightRows {
            if highlightRow == asset {
                return true
            }
        }
        return false
    }

    func reloadHighlight() {
        for cell in visibleCells as? [ImageCell] ?? [] {
            if let asset = cell.asset {
                cell.imageView.alpha = self.isHighlight(asset) ? 0.3 : 1
            }
        }
    }
}
