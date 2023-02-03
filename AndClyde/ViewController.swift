//
//  ViewController.swift
//  AndClyde
//
//  Created by Anton Ivanov on 20.05.21.
//

import UIKit
import ARKit
import ReplayKit
import RealityKit

class ViewController: UIViewController {
    
    @IBOutlet var arView: FocusARView!
    
    var sessionIDObservation: NSKeyValueObservation?
    
    let recorder = RPScreenRecorder.shared()
    var isRecording: Bool = false {
        didSet {
            modelsCollection.isHidden = isRecording
            screenshot.isHidden = isRecording
            occlusionBtn.isHidden = isRecording
            connectionStatusView.isHidden = isRecording
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
    
    private lazy var logoLabel: UILabel = {
        let label = UILabel()
        label.text = "&Clyde"
        label.textColor = UIColor(named: "black")
        label.font = UIFont(name: "Berlindah", size: 50)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var connectionStatusView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.layer.backgroundColor = UIColor.systemRed.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 8),
            view.widthAnchor.constraint(equalToConstant: 8)
        ])
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
        
        button.setImage(UIImage(systemName: "camera.circle"), for: .normal)
        button.tintColor = UIColor.white.withAlphaComponent(0.5)
        let config = UIImage.SymbolConfiguration(pointSize: 30)
        button.setPreferredSymbolConfiguration(config, forImageIn: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(takeScreenshot), for: .touchUpInside)
        return button
    }()
    
    private lazy var screenRecordBtn: UIButton = {
        let button = UIButton()
        
        button.setImage(UIImage(systemName: "record.circle"), for: .normal)
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
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 20
        stack.addArrangedSubview(connectionStatusView)
        stack.addArrangedSubview(screenRecordBtn)
        stack.addArrangedSubview(screenshot)
        stack.addArrangedSubview(occlusionBtn)
        return stack
    }()
    
    private lazy var occlusionBtn: UIButton = {
        let button = UIButton()
        
        button.setImage(UIImage(systemName: "eye.fill"), for: .normal)
        button.tintColor = UIColor.white.withAlphaComponent(0.5)
        let config = UIImage.SymbolConfiguration(pointSize: 30)
        button.setPreferredSymbolConfiguration(config, forImageIn: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(setupOcclusion), for: .touchUpInside)
        return button
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
         
        setupARView()
        
        setupControlHandler()
                
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
        arView.addSubview(logoLabel)
        arView.addSubview(recordStack)

        modelsCollection.items = Models().all
        
        NSLayoutConstraint.activate([
            modelsCollection.heightAnchor.constraint(equalToConstant: 130),
            modelsCollection.centerXAnchor.constraint(equalTo: arView.centerXAnchor),
            modelsCollection.leadingAnchor.constraint(equalTo: arView.leadingAnchor),
            modelsCollection.bottomAnchor.constraint(equalTo: arView.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            modelPlaceControlStack.centerXAnchor.constraint(equalTo: arView.centerXAnchor),
            modelPlaceControlStack.bottomAnchor.constraint(equalTo: arView.bottomAnchor, constant: -24),
            
            logoLabel.topAnchor.constraint(equalTo: arView.safeAreaLayoutGuide.topAnchor, constant: 8),
            logoLabel.leadingAnchor.constraint(equalTo: arView.leadingAnchor, constant: 24),
            
            recordStack.trailingAnchor.constraint(equalTo: arView.trailingAnchor, constant: -24),
            recordStack.centerYAnchor.constraint(equalTo: logoLabel.centerYAnchor)
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
    
    @objc
    func setupOcclusion() {
        guard ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth),
              ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification),
              let configuration = arView.session.configuration as? ARWorldTrackingConfiguration
        else {
            let alert = UIAlertController(title: "Error", message: "Scene reconstruction requires a device with a LiDAR Scanner.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if configuration.frameSemantics.contains(.personSegmentation) {
            configuration.frameSemantics.remove(.personSegmentation)
        } else {
            configuration.frameSemantics.insert(.personSegmentation)
        }
        
        if arView.environment.sceneUnderstanding.options.contains(.occlusion) {
            arView.environment.sceneUnderstanding.options.remove(.occlusion)
            occlusionBtn.tintColor = UIColor.white.withAlphaComponent(0.5)
        } else {
            arView.environment.sceneUnderstanding.options.insert(.occlusion)
            occlusionBtn.tintColor = .systemGreen
        }
    }
    
    func collectionIsEnabled(_ isEnabled: Bool) {
        arView.focusEntity?.isEnabled = !isEnabled
        modelsCollection.isHidden = !isEnabled
        modelPlaceControlStack.isHidden = isEnabled
    }
}

extension ViewController: PreviewCollectionViewDelegate {
    func collectionView(_ collectionView: PreviewCollectionView, didSelect item: Model) {
        collectionIsEnabled(false)

        selectedModel = item
    }
    
    func collectionView( _ collectionView: PreviewCollectionView, didSelectStore item: Model) {
        if let url = URL(string: "https://www.andclyde.com") {
            UIApplication.shared.open(url)
        }
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let anchorname = anchor.name {
                placeObject(named: anchorname, for: anchor)
            }
            
            if anchor is ARParticipantAnchor {
                print("Successfully connected to another user")
                connectionStatusView.layer.backgroundColor = UIColor.systemGreen.cgColor
            }
        }
    }
}

extension ViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true, completion: nil)
    }
}
