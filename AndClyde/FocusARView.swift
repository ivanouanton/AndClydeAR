//
//  FocusARView.swift
//  AndClyde
//
//  Created by Anton Ivanov on 21.05.21.
//

import RealityKit
import ARKit
import FocusEntity

class FocusARView: ARView {
    var focusEntity: FocusEntity?
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        
        setupInit()
    }
    
    @objc required dynamic init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        setupInit()
    }
    
    func setupInit() {
        focusEntity = FocusEntity(on: self, focus: .classic)
        
        configure()
    }
    
    private func configure() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.vertical, .horizontal]
        session.run(config)
    }
}
