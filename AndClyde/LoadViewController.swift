//
//  LoadViewController.swift
//  AndClyde
//
//  Created by Anton Ivanou on 03/02/2023.
//

import UIKit

class LoadViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let arController = ARViewController()
            arController.modalPresentationStyle = .overFullScreen
            self.present(arController, animated: true)
        }
    }
}
