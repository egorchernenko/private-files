//
//  DetailMediaViewController.swift
//  Private Files
//
//  Created by Egor on 14.04.2018.
//  Copyright © 2018 Chernenko Inc. All rights reserved.
//

import UIKit
import Photos
import AVKit

class DetailMediaViewController: UIViewController{
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    class var segueIdentifier: String {
        return String(describing: self)
    }
    var media = [Media]()
    var scrollToIndexPath: IndexPath?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let indexPath = self.scrollToIndexPath{
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            self.scrollToIndexPath = nil
            
        }
    }
    
    
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        
        guard let media = (self.collectionView.visibleCells[self.collectionView.visibleCells.count/2] as? MediaCollectionViewCell)?.media, let urlStr = media.urlStr else {return}
        let url = URL.documentDirectory.appendingPathComponent(urlStr)
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activityViewController.excludedActivityTypes = [UIActivityType.addToReadingList, UIActivityType.openInIBooks, UIActivityType.print]
            self.present(activityViewController, animated: true, completion: nil)
        case .restricted, .denied:
            let libraryRestrictedAlert = UIAlertController(title: "Photos access denied",
                                                           message: "Please enable Photos access for this application in Settings > Privacy to allow saving screenshots.",
                                                           preferredStyle: UIAlertControllerStyle.alert)
            libraryRestrictedAlert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            self.present(libraryRestrictedAlert, animated: true, completion: nil)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (authorizationStatus) in
                if authorizationStatus == .authorized {
                    let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    activityViewController.excludedActivityTypes = [UIActivityType.addToReadingList, UIActivityType.openInIBooks, UIActivityType.print]
                    self.present(activityViewController, animated: true, completion: nil)
                }
            })
        }
    }
    
    @IBAction func deleteButtonPressed(_ sender: UIBarButtonItem) {
        
    }
    
}

extension DetailMediaViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.media.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaCollectionViewCell.identifier, for: indexPath) as! MediaCollectionViewCell
        let mediaItem = media[indexPath.item]
        
        if let imageKey = mediaItem.urlStr as NSString?{
            if let image = Cache.shared.imageCache.object(forKey: imageKey){
                cell.previewImageView.image = image
            } else {
                //TODO: - FIX BUG HERE
                mediaItem.getPreviewImage { image in
                    if let img = image{
                        Cache.shared.imageCache.setObject(img, forKey: imageKey)
                        cell.previewImageView.image = img
                    }
                }
            }
        }
        
        cell.configureCell(withMedia: mediaItem)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.media[indexPath.item].assetType == AssetType.video.rawValue{
            if let urlStr = self.media[indexPath.item].urlStr{
                let url = URL.documentDirectory.appendingPathComponent(urlStr)
                let videoPlayer = AVPlayer(url: url)
                let videoController = AVPlayerViewController()
                videoController.player = videoPlayer
                
                self.present(videoController, animated: true, completion: {
                    videoPlayer.play()
                })
            }
        } else {
            self.navigationController!.navigationBar.isHidden = !self.navigationController!.navigationBar.isHidden
            self.tabBarController!.tabBar.isHidden = !self.tabBarController!.tabBar.isHidden
            self.view.backgroundColor = self.view.backgroundColor == .white ? .black : .white
            
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let cell = collectionView.visibleCells[collectionView.visibleCells.count/2]
        let indexPath = collectionView.indexPath(for: cell)
        NotificationCenter.default.post(name: .cellDidChange, object: nil, userInfo: ["indexPath" : indexPath])
    }
}

extension DetailMediaViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.collectionView.bounds.size
    }
}

extension DetailMediaViewController: UIViewControllerTransitioningDelegate{
    
}
