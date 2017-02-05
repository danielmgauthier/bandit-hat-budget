//
//  TopLevelViewController.swift
//  Budget
//
//  Created by Daniel Gauthier on 2017-02-01.
//  Copyright © 2017 Bandit Hat Apps. All rights reserved.
//

import UIKit

class TopLevelViewController: UIViewController {
  
  weak var interactivePresenter: InteractivePresenter?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let panGestureRecognizer = OneWayPanGestureRecognizer(target: self, action: #selector(handleDrag(recognizer:)))
    view.addGestureRecognizer(panGestureRecognizer)
    
    
    if let tableViewController = self as? TableViewController {
      
      let scrollGestureRecognizer = OneWayPanGestureRecognizer(target: self, action: #selector(handleDrag(recognizer:)))
      scrollGestureRecognizer.delegate = self
      
      tableViewController.tableView.addGestureRecognizer(scrollGestureRecognizer)
      tableViewController.tableView.panGestureRecognizer.require(toFail: scrollGestureRecognizer)
      tableViewController.tableView.layer.allowsEdgeAntialiasing = true
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  func handleDrag(recognizer: UIPanGestureRecognizer) {
    
    if recognizer.state == .began {
      
      view.endEditing(true)
      interactivePresenter?.interactiveDismissalBegan()
      
    } else if recognizer.state == .changed {
      
      var progress = recognizer.translation(in: view).y / Utilities.screenHeight
      
      if progress < 0.0 {
        progress = progress / (4.0 * (1.0 - progress))
      }
      
      interactivePresenter?.interactiveDismissalChanged(withProgress: progress)
      
      let xTranslation = recognizer.translation(in: view).x
      var xTranslationPercent = xTranslation / 100.0
      
      let yPosition = recognizer.location(in: view).y
      
      let normalizedYPosition = (yPosition - Utilities.screenHeight / 2.0) / (Utilities.screenHeight / 2.0) * -1.0
      xTranslationPercent *= normalizedYPosition
      
      view.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_4 / 10.0) * xTranslationPercent)
      
    } else if recognizer.state == .ended {
      var progress = recognizer.translation(in: view).y / Utilities.screenHeight
      progress = min(1.0, max(0.0, progress))
      var velocity = recognizer.velocity(in: view).y
      
      if (progress > 0.5 || velocity > 300) && velocity > -300 {
        var distanceToTravel = (1.0 - progress) * Utilities.screenHeight
        if distanceToTravel < 0 {
          distanceToTravel *= -1.0
          velocity *= -1
        }
        interactivePresenter?.interactiveDismissalFinished(withDistanceToTravel: distanceToTravel, velocity: velocity)
        
        UIView.animate(withDuration: 0.45, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: { () -> Void in
          self.view.transform = CGAffineTransform.identity
        }, completion: nil)
        
      } else {
        var distanceToTravel = progress * Utilities.screenHeight
        if distanceToTravel < 0 {
          distanceToTravel *= -1.0
          velocity *= -1
        }
        
        interactivePresenter?.interactiveDismissalCanceled(withDistanceToTravel: distanceToTravel, velocity: -velocity)
        
        UIView.animate(withDuration: 0.45, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: { () -> Void in
          self.view.transform = CGAffineTransform.identity
        }, completion: nil)
      }
    }
  }
}

// MARK: - Gesture Recognizer Delegate Methods
extension TopLevelViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    
    if let tableViewController = self as? TableViewController {
      if tableViewController.tableView.contentOffset.y <= 0 {
        return true
      } else {
        return false
      }
    }
    return true
  }
}