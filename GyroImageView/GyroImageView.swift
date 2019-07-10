//
//  GyroImageView.swift
//  GyroImageView
//
//  Created by Don Bytyqi on 7/9/19.
//  Copyright © 2019 Don Bytyqi. All rights reserved.
//

import UIKit
import CoreMotion

enum StartPoint {
    case left
    case middle
    case right
}


// Network codet to download an image
extension GyroImageView {
    func startURLSession(with url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func downloadImage(from url: URL) {
        startURLSession(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async() {
                self.image = UIImage(data: data)
                self.layoutSubviews()
            }
        }
    }
}

class GyroImageView: UIScrollView {
    
    private let motionManager = CMMotionManager()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    /// Motion manager starts capturing gyroscope data only when the image is set.
    var image: UIImage? = nil {
        didSet {
            guard let image = image else { return }
            if imageView.contentMode == .scaleAspectFit  {
                print("Scale aspect fit isn't recommended, use scaleAspectFill for best results.")
            }
            imageView.image = image
            animateFor(image: image)
        }
    }
    
    var imageUrl: String? = nil {
        didSet {
            guard let iu = imageUrl, let url = URL(string: iu) else { return }
            downloadImage(from: url)
        }
    }
    
    /// Where the scrollView will point at when the image is first loaded. Default is MIDDLE.
    var startPoint: StartPoint = .middle
    
    /// Speed of scrolling animation. Default is 70.0.
    var speed: Double = 70.0
    
    /// Enabling this will allow for scrolling the image in both the X and Y axis.
    var fullScroll: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let image = image else { return }
        
        if imageView.frame != self.bounds && imageView.frame.width != image.size.width {
            if fullScroll {
                imageView.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            } else {
                imageView.frame = CGRect(x: 0, y: 0, width: image.size.width, height: self.frame.height)
            }
            setStartPoint()
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func animateFor(image: UIImage) {
        
        motionManager.gyroUpdateInterval = 0.1
        
        let highestScrollPointX = image.size.width - UIScreen.main.bounds.width
        let highestScrollPointY = image.size.height - UIScreen.main.bounds.height
        let lowestScrollPoint: CGFloat = 0.0
        
        let mainOperationQueue = OperationQueue.main
        
        motionManager.startGyroUpdates(to: mainOperationQueue, withHandler: { (data, error) in
            guard let data = data else { return }
            
            let yRotationRate = data.rotationRate.y
            let xRotationRate = data.rotationRate.x
            var currentScrollX = self.contentOffset.x - CGFloat(yRotationRate * self.speed)
            var currentScrollY = self.contentOffset.y - CGFloat(xRotationRate * self.speed)
            
            if (currentScrollX > highestScrollPointX) {
                currentScrollX = highestScrollPointX
            } else if (currentScrollX < lowestScrollPoint) {
                currentScrollX = lowestScrollPoint
            }
            
            if (currentScrollY > highestScrollPointY) {
                currentScrollY = highestScrollPointY
            } else if (currentScrollY < lowestScrollPoint) {
                currentScrollY = lowestScrollPoint
            }
            
            UIView.animate(withDuration: 0.5, delay: 0.0, options: [.allowUserInteraction], animations: {
                if self.fullScroll {
                    self.contentOffset = CGPoint(x: currentScrollX, y: currentScrollY)
                } else {
                    self.contentOffset = CGPoint(x: currentScrollX, y: 0.0)
                }
                self.layoutIfNeeded()
            }, completion: nil)
            
        })
    }
    
    fileprivate func setStartPoint() {
        guard let image = image else { return }
        
        switch startPoint {
        case .left:
            self.contentOffset = CGPoint(x: 0.0, y: 0.0)
        case .middle:
            self.contentOffset = CGPoint(x: image.size.width / 2, y: 0.0)
        case .right:
            self.contentOffset = CGPoint(x: image.size.width - (UIScreen.main.bounds.width), y: 0.0)
        }
        
    }
    
    func startMotionManager() {
        guard let image = image else { return }
        animateFor(image: image)
    }
    
    func stopMotionManager() {
        if motionManager.isGyroActive {
            motionManager.stopGyroUpdates()
        }
    }
    
}
