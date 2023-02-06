//
//  ARViewController.swift
//  AndClyde
//
//  Created by Anton Ivanov on 20.05.21.
//

import UIKit
import ARKit
import ReplayKit
import RealityKit

class ARViewController: UIViewController {
        
    lazy var arView: FocusARView = {
        let view = FocusARView(frame: view.frame)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var sessionIDObservation: NSKeyValueObservation?
    
    let recorder = RPScreenRecorder.shared()
    var isRecording: Bool = false {
        didSet {
            modelsCollection.isHidden = isRecording
            screenshot.isHidden = isRecording
            screenRecordBtn.tintColor = isRecording ? UIColor.systemRed.withAlphaComponent(0.5) : UIColor.white.withAlphaComponent(0.5)
        }
    }
    
    var selectedModel: Model? {
        didSet {
            arView.focusEntity?.isEnabled = self.selectedModel != nil
        }
    }

    private lazy var modelsCollection: PreviewCollectionView = {
        let view = PreviewCollectionView()
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var acceptModelBtn: UIButton = {
        let button = UIButton()
        
        button.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        button.layer.cornerRadius = 35
        button.tintColor = UIColor.white.withAlphaComponent(0.5)
        let config = UIImage.SymbolConfiguration(pointSize: 50)
        button.setPreferredSymbolConfiguration(config, forImageIn: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 70),
            button.widthAnchor.constraint(equalToConstant: 70)
        ])
        button.addTarget(self, action: #selector(acceptModel), for: .touchUpInside)
        return button
    }()
    
    private lazy var skipModelBtn: UIButton = {
        let button = UIButton()
        
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.layer.cornerRadius = 35
        button.tintColor = UIColor.white.withAlphaComponent(0.5)
        let config = UIImage.SymbolConfiguration(pointSize: 50)
        button.setPreferredSymbolConfiguration(config, forImageIn: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 70),
            button.widthAnchor.constraint(equalToConstant: 70)
        ])
        button.addTarget(self, action: #selector(skipModel), for: .touchUpInside)
        return button
    }()

    private lazy var modelPlaceControlStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.spacing = 100
        stack.addArrangedSubview(skipModelBtn)
        stack.addArrangedSubview(acceptModelBtn)
        stack.isHidden = true
        return stack
    }()
    
    private lazy var screenshot: UIButton = {
        let button = UIButton()
        
        button.setImage(UIImage(named: "camera-photo"), for: .normal)
        button.tintColor = UIColor.white.withAlphaComponent(0.5)
        let config = UIImage.SymbolConfiguration(pointSize: 30)
        button.setPreferredSymbolConfiguration(config, forImageIn: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(takeScreenshot), for: .touchUpInside)
        return button
    }()
    
    private lazy var screenRecordBtn: UIButton = {
        let button = UIButton()
        
        button.setImage(UIImage(named: "camera-video"), for: .normal)
        button.tintColor = UIColor.white.withAlphaComponent(0.5)
        let config = UIImage.SymbolConfiguration(pointSize: 30)
        button.setPreferredSymbolConfiguration(config, forImageIn: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(takeScreenRecord), for: .touchUpInside)
        return button
    }()
    
    private lazy var recordStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 20
        stack.addArrangedSubview(screenshot)
        stack.addArrangedSubview(screenRecordBtn)
        return stack
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
         
        setupARView()
        
        setupControlHandler()
                
        view.addSubview(arView)
        
        NSLayoutConstraint.activate([
            arView.topAnchor.constraint(equalTo: view.topAnchor),
            arView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            arView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        arView.session.delegate = self
    }
    
    private func setupARView() {
        arView.focusEntity?.isEnabled = false

        arView.automaticallyConfigureSession = false
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        config.isCollaborationEnabled = true
        
        arView.session.run(config)
    }
    
    func setupControlHandler() {
        arView.addSubview(modelsCollection)
        arView.addSubview(modelPlaceControlStack)
        arView.addSubview(recordStack)

        modelsCollection.items = Models().all
        
        NSLayoutConstraint.activate([
            modelsCollection.heightAnchor.constraint(equalToConstant: 130),
            modelsCollection.centerXAnchor.constraint(equalTo: arView.centerXAnchor),
            modelsCollection.leadingAnchor.constraint(equalTo: arView.leadingAnchor),
            modelsCollection.bottomAnchor.constraint(equalTo: arView.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            modelPlaceControlStack.centerXAnchor.constraint(equalTo: arView.centerXAnchor),
            modelPlaceControlStack.bottomAnchor.constraint(equalTo: arView.bottomAnchor, constant: -24),
            
            recordStack.trailingAnchor.constraint(equalTo: arView.trailingAnchor, constant: -16),
            recordStack.topAnchor.constraint(equalTo: arView.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
    }
    
    func placeObject(named entityName: String, for anchor: ARAnchor) {
        let model = Model(entityName)
        model.asyncLoadModelEntity()
        
        if let entity = model.modelEntity {
            
            let clonedEntity = entity.clone(recursive: true)
            
            clonedEntity.generateCollisionShapes(recursive: true)
            arView.installGestures([.translation, .rotation, .scale], for: clonedEntity)
            
            let anchorEntity = AnchorEntity(anchor: anchor)
            anchorEntity.addChild(clonedEntity)
            arView.scene.addAnchor(anchorEntity)
        }
    }
    
    func placeObject(_ model: Model) {
        model.asyncLoadModelEntity()

        let location = CGPoint(x: arView.bounds.maxX / 2, y: arView.bounds.maxY / 2)

        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)


        if let firstResult = results.first {
            let anchor = ARAnchor(name: model.name, transform: firstResult.worldTransform)

            arView.session.add(anchor: anchor)
            
            selectedModel = nil
            collectionIsEnabled(true)

        } else {
            print("Object placement failed - couldn't find surface.")
        }
    }
    
    @objc
    func acceptModel() {
        collectionIsEnabled(false)
        
        guard let model = selectedModel else { return }
        placeObject(model)
    }
    
    @objc
    func skipModel() {
        collectionIsEnabled(true)
        selectedModel = nil
    }
    
    @objc
    func takeScreenshot() {
        //1. Create A Snapshot
        self.arView.snapshot(saveToHDR: false) { image in
            guard let image = image else { return }
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc
    func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {

        if let error = error {
            print("Error Saving ARKit Scene \(error)")
        } else {
            print("ARKit Scene Successfully Saved")
            
            UIView.animate(withDuration: 1, animations: {
                self.screenshot.tintColor = UIColor.systemGreen
            }, completion: { _ in
                self.screenshot.tintColor = UIColor.white.withAlphaComponent(0.5)

            })
        }
    }
    
    @objc
    func takeScreenRecord() {
        isRecording = !isRecording
        if isRecording {
            recorder.startRecording { (error) in
                if let error = error {
                    self.isRecording = !self.isRecording
                    print(error)
                }
            }
            
        } else {
            recorder.stopRecording { (previewVC, error) in
                if let previewVC = previewVC {
                    previewVC.previewControllerDelegate = self
                    self.present(previewVC, animated: true, completion: nil)
                }
                
                if let error = error {
                    print(error)
                }
            }
        }
    }
    
    func collectionIsEnabled(_ isEnabled: Bool) {
        arView.focusEntity?.isEnabled = !isEnabled
        modelsCollection.isHidden = !isEnabled
        modelPlaceControlStack.isHidden = isEnabled
    }
}

extension ARViewController: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let anchorname = anchor.name {
                placeObject(named: anchorname, for: anchor)
            }
        }
    }
}

extension ARViewController: PreviewCollectionViewDelegate {
    func collectionView(_ collectionView: PreviewCollectionView, didSelect item: Model) {
        collectionIsEnabled(false)

        selectedModel = item
    }
}

extension ARViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true, completion: nil)
    }
}
