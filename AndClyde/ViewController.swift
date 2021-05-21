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

    private lazy var addModelButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Add Model", for: .normal)
        button.layer.cornerRadius = 10
        button.layer.backgroundColor = UIColor.black.withAlphaComponent(0.25).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addModelHandled(sender:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var connectionStatusView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 5
        view.layer.backgroundColor = UIColor.systemRed.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var multipeerSession: MultipeerSession?
    var sessionIDObservation: NSKeyValueObservation?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupARView()
        
        setupControlHandler()
        
        setupMultipeerSession()
        
        arView.session.delegate = self
        
        let tabGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(tapHandled(recognizer:)))
        arView.addGestureRecognizer(tabGestureRecogniser)
    }
    
    private func setupARView() {
        arView.automaticallyConfigureSession = false
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        config.isCollaborationEnabled = true
        
        arView.session.run(config)
    }
    
    func setupControlHandler() {
        arView.addSubview(addModelButton)
        arView.addSubview(connectionStatusView)

        NSLayoutConstraint.activate([
            addModelButton.heightAnchor.constraint(equalToConstant: 50),
            addModelButton.widthAnchor.constraint(equalToConstant: 150),
            addModelButton.centerXAnchor.constraint(equalTo: arView.centerXAnchor),
            addModelButton.bottomAnchor.constraint(equalTo: arView.bottomAnchor, constant: -50),
            
            connectionStatusView.heightAnchor.constraint(equalToConstant: 10),
            connectionStatusView.widthAnchor.constraint(equalToConstant: 10),
            connectionStatusView.topAnchor.constraint(equalTo: arView.safeAreaLayoutGuide.topAnchor, constant: 16),
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
    
    @objc
    private func tapHandled(recognizer: UITapGestureRecognizer) {
        
        let location = recognizer.location(in: arView)

        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)

        if let firstResult = results.first {
            let anchor = ARAnchor(name: "shell", transform: firstResult.worldTransform)

            arView.session.add(anchor: anchor)
        } else {
            print("Object placement failed - couldn't find surface.")
        }
    }
    
    func placeObject(named entityName: String, for anchor: ARAnchor) {
        let laserEntity = try! ModelEntity.load(named: entityName)
        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(laserEntity)
        arView.scene.addAnchor(anchorEntity)
    }
    
    @objc
    func addModelHandled(sender: UIButton) {
        print("Hello world")
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let anchorname = anchor.name, anchorname == "shell" {
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

// MARK: - Multipeer

extension ViewController {
    private func sendARSessionIDTo(peers: [PeerID]) {
        guard let multipeerSession = multipeerSession else { return }
        let idString = arView.session.identifier.uuidString
        let command = "SessionID:" + idString
        if let commandData = command.data(using: .utf8) {
            multipeerSession.sendToPeers(commandData, reliably: true, peers: peers)
        }
    }
    
    func receivedData(_ data: Data, from peer: PeerID) {
        guard let multipeerSession = multipeerSession else { return }
        
        if let collaborationData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARSession.CollaborationData.self, from: data) {
            arView.session.update(with: collaborationData)
            return
        }
        
        let sessionIDCommandString = "SessionID:"
        if let commandString = String(data: data, encoding: .utf8), commandString.starts(with: sessionIDCommandString) {
            let newSessionID = String(commandString[commandString.index(commandString.startIndex, offsetBy: sessionIDCommandString.count)...])
            
            // if this peer was using a different session ID before, remove all its assosiated anchors.
            // This will remove old participant anchor and its geometru from the scene.
            if let oldSessionID = multipeerSession.peerSessionIDs[peer] {
                removeAllAnchorsOriginatingFromARSessionWithID(oldSessionID)
            }
            
            multipeerSession.peerSessionIDs[peer] = newSessionID
        }
    }
    
    func peerDiscovered(_ peer: PeerID) -> Bool {
        guard let multipeerSession = multipeerSession else { return false }
        
        if multipeerSession.connectedPeers.count > 4 {
            // Do not accept more than four users in the experience.
            print("A fifth peer wants to join the experience.\nThis app is limited to four users.")
            return false
        } else {
            return true
        }
    }
    
    /// - Tag: PeerJoined
    func peerJoined(_ peer: PeerID) {
        print("""
            A peer wants to join the experience.
            Hold the phones next to each other.
            """)
        
        DispatchQueue.main.async {
            self.connectionStatusView.layer.backgroundColor = UIColor.systemYellow.cgColor
        }
        
        // Provide your session ID to the new user so they can keep track of your anchors.
        sendARSessionIDTo(peers: [peer])
    }
    
    func peerLeft(_ peer: PeerID) {
        guard let multipeerSession = multipeerSession else { return }

        print("A peer has left the shared experience.")
        DispatchQueue.main.async {
            self.connectionStatusView.layer.backgroundColor = UIColor.systemRed.cgColor
        }

        // Remove all ARAnchors associated with the peer that just left the experience.
        if let sessionID = multipeerSession.peerSessionIDs[peer] {
            removeAllAnchorsOriginatingFromARSessionWithID(sessionID)
            multipeerSession.peerSessionIDs.removeValue(forKey: peer)
        }
    }
    
    private func removeAllAnchorsOriginatingFromARSessionWithID(_ identifier: String) {
        guard let frame = arView.session.currentFrame else { return }
        for anchor in frame.anchors {
            guard let anchorSessionID = anchor.sessionIdentifier else { continue }
            if anchorSessionID.uuidString == identifier {
                arView.session.remove(anchor: anchor)
            }
        }
    }
    
    /// - Tag: DidOutputCollaborationData
    func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
        guard let multipeerSession = multipeerSession else { return }
        if !multipeerSession.connectedPeers.isEmpty {
            guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true)
            else { fatalError("Unexpectedly failed to encode collaboration data.") }
            // Use reliable mode if the data is critical, and unreliable mode if the data is optional.
            let dataIsCritical = data.priority == .critical
            multipeerSession.sendToAllPeers(encodedData, reliably: dataIsCritical)
        } else {
            print("Deferred sending collaboration to later because there are no peers.")
            let color = connectionStatusView.layer.backgroundColor
            UIView.animate(withDuration: 0.1) {
                self.connectionStatusView.layer.backgroundColor = UIColor.systemBlue.cgColor
            }
        }
    }
}
