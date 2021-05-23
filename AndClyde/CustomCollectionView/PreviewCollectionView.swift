//
//  PreviewCollectionView.swift
//  AndClyde
//
//  Created by Anton Ivanov on 22.05.21.
//

import UIKit

protocol PreviewCollectionViewDelegate: AnyObject {
    func collectionView( _ collectionView: PreviewCollectionView, didSelect item: Model)
    func collectionView( _ collectionView: PreviewCollectionView, didSelectStore item: Model)
}

class PreviewCollectionView: UIView {
    
    weak var delegate: PreviewCollectionViewDelegate?
            
    var items: [Model] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    private lazy var flowLayout: ZoomAndSnapFlowLayout = {
        let layout = ZoomAndSnapFlowLayout()
        return layout
    }()
    
    private lazy var collectionView: UICollectionView = {
        let collection = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = false
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.dataSource = self
        collection.delegate = self
        collection.contentInsetAdjustmentBehavior = .always
        collection.register(CollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        return collection
    }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }

    private func setupView() {
        addSubview(collectionView)
        setupConstarints()
    }
    
    private func setupConstarints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}

//MARK: Collection delegate&ds methods
extension PreviewCollectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CollectionViewCell
        cell.imageView.image = UIImage(named: items[indexPath.item].name)
        cell.handler = { index in
            self.delegate?.collectionView(self, didSelect: self.items[index])
        }
        cell.handlerStore = { index in
            self.delegate?.collectionView(self, didSelectStore: self.items[index])
        }
        cell.index = indexPath.item
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.collectionView(self, didSelect: items[indexPath.row])
    }
}


class CollectionViewCell: UICollectionViewCell {
    
    var index: Int = 0
    var handler: (_ index: Int) -> Void = { index in }
    var handlerStore: (_ index: Int) -> Void = { index in }

    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var button: UIButton = {
        let view = UIButton()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(selectItem), for: .touchUpInside)
        return view
    }()
    
    lazy var storeBtn: UIButton = {
        let view = UIButton()
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        view.setTitle("view in the store", for: .normal)
        view.titleLabel?.font = view.titleLabel?.font.withSize(8)
        view.setTitleColor(.white, for: .normal)
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(viewStore), for: .touchUpInside)
        return view
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        index = 0
        imageView.image = nil
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        contentView.layer.cornerRadius = 10
        
        contentView.addSubview(imageView)
        contentView.addSubview(button)
        contentView.addSubview(storeBtn)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            button.topAnchor.constraint(equalTo: contentView.topAnchor),
            
            storeBtn.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            storeBtn.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            storeBtn.topAnchor.constraint(equalTo: button.bottomAnchor),
            storeBtn.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            storeBtn.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func selectItem() {
        handler(index)
    }
    
    @objc
    func viewStore() {
        handlerStore(index)
    }
}
