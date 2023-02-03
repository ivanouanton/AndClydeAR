//
//  Model.swift
//  AndClyde
//
//  Created by Anton Ivanov on 21.05.21.
//

import RealityKit
import UIKit

class Model {
    var name: String
    var thumbnails: UIImage
    var modelEntity: ModelEntity?
    var scaleCompensation: Float
        
    init(_ name: String, scaleCompensation: Float = 1.0) {
        self.name = name
        self.thumbnails = UIImage(named: name) ?? UIImage(systemName: "photo")!
        self.scaleCompensation = scaleCompensation
    }
    
    func asyncLoadModelEntity() {
        let filename = self.name + ".usdz"
        
        if let mEntity = try? ModelEntity.loadModel(named: filename) {
            self.modelEntity = mEntity
            self.modelEntity?.scale *= self.scaleCompensation
            
            print("modelEntity for \(self.name) has been loaded.")
        } else {
            print("Unable to load modelEntity for \(filename).")
        }
    }
}

struct Models {
    var all: [Model] = []
    
    init() {
        let earth   = Model("earth", scaleCompensation: 0.3)
        let lamp    = Model("lamp", scaleCompensation: 0.3)
        let conch   = Model("conch", scaleCompensation: 0.3)

        self.all += [earth, lamp, conch]
    }
}
