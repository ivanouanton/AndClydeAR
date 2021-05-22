//
//  ViewController.swift
//  AndClyde
//
//  Created by Anton Ivanov on 20.05.21.
//

import UIKit
import RealityKit
import ARKit
import MultipeerSession

class ViewController: UIViewController {
    
    @IBOutlet var arView: FocusARView!
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
        return view
    }()
    
    var multipeerSession: MultipeerSession?
    var sessionIDObservation: NSKeyValueObservation?
    
    private lazy var acceptModelBtn: UIButton = {
        let button = UIButton()
        
        button.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        button.layer.cornerRadius = 35
        button.tintColor = UIColor(named: "gold")
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
        button.tintColor = UIColor(named: "gold")
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupARView()
        
        setupControlHandler()
        
        setupMultipeerSession()
        
        arView.session.delegate = self
        
//        let tabGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(tapHandled(recognizer:)))
//        arView.addGestureRecognizer(tabGestureRecogniser)
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
        arView.addSubview(connectionStatusView)
        arView.addSubview(modelPlaceControlStack)
        arView.addSubview(logoLabel)
        
        modelsCollection.items = Models().all
        
        NSLayoutConstraint.activate([
            modelsCollection.heightAnchor.constraint(equalToConstant: 120),
            modelsCollection.centerXAnchor.constraint(equalTo: arView.centerXAnchor),
            modelsCollection.leadingAnchor.constraint(equalTo: arView.leadingAnchor),
            modelsCollection.bottomAnchor.constraint(equalTo: arView.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            modelPlaceControlStack.centerXAnchor.constraint(equalTo: arView.centerXAnchor),
            modelPlaceControlStack.bottomAnchor.constraint(equalTo: arView.bottomAnchor, constant: -24),
            
            logoLabel.topAnchor.constraint(equalTo: arView.safeAreaLayoutGuide.topAnchor, constant: 8),
            logoLabel.leadingAnchor.constraint(equalTo: arView.leadingAnchor, constant: 24),

            connectionStatusView.heightAnchor.constraint(equalToConstant: 8),
            connectionStatusView.widthAnchor.constraint(equalToConstant: 8),
            connectionStatusView.centerYAnchor.constraint(equalTo: logoLabel.centerYAnchor),
            connectionStatusView.trailingAnchor.constraint(equalTo: arView.trailingAnchor, constant: -24),
        ])
    }
    
    private func setupMultipeerSession() {
        
        // Use key-value observation to monitor your ARSession's ids
        sessionIDObservation = observe(\.arView.session.identifier, options: [.new], changeHandler: { object, change in
            print("SessionID changed to: \(change.newValue!)")
            
            // Tell all other peers about your ARSession's changed ID, so
            // that thay can keep track of which ARAnchors are yours
            guard let multipeerSession = self.multipeerSession else { return }
            self.sendARSessionIDTo(peers: multipeerSession.connectedPeers)
        })
        
        // Start looking for the other players via MultiPeerConnectivity
        multipeerSession = MultipeerSession(serviceName: "multiuser-ar",
                                                receivedDataHandler: self.receivedData,
                                                peerJoinedHandler: self.peerJoined,
                                                peerLeftHandler: self.peerLeft,
                                                peerDiscoveredHandler: self.peerDiscovered)
    }
    
//    @objc
//    private func tapHandled(recognizer: UITapGestureRecognizer) {
//
//        let location = recognizer.location(in: arView)
//
//        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
//
//        if let firstResult = results.first {
//            let anchor = ARAnchor(name: "shell", transform: firstResult.worldTransform)
//
//            arView.session.add(anchor: anchor)
//        } else {
//            print("Object placement failed - couldn't find surface.")
//        }
//    }
    
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
    
//    @objc
//    func addModelHandled(sender: UIButton) {
//
//        collectionIsEnabled(false)
//
//        let model = Models().all[0]
//        selectedModel = model
//    }
    
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
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let anchorname = anchor.name {
                placeObject(named: anchorname, for: anchor)
            }
            
            if let participantAnchor = anchor as? ARParticipantAnchor {
                print("Successfully connected to another user")
                connectionStatusView.layer.backgroundColor = UIColor.systemGreen.cgColor
                let anchorEntity = AnchorEntity(anchor: participantAnchor)

                let mesh = MeshResource.generateSphere(radius: 0.03)
                let color = UIColor.red
                let material = SimpleMaterial(color: color, isMetallic: false)
                let coloredSphere = ModelEntity(mesh: mesh, materials: [material])

                anchorEntity.addChild(coloredSphere)

                arView.scene.addAnchor(anchorEntity)
            }
        }
    }
}
