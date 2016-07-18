import UIKit

protocol BrandProductListViewDelegate: ProductListViewDelegate, ViewSwitcherDelegate {
    func brandProductListDidTapHeader(view: BrandProductListView)
}

class BrandProductListView: ViewSwitcher, ProductListViewInterface, ProductListComponentDelegate {
    let productListComponent: ProductListComponent
    let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
    weak var delegate: ProductListViewDelegate? {
        didSet {
            switcherDelegate = brandListDelegate
        }
    }
    weak var brandListDelegate: BrandProductListViewDelegate? {
        return delegate as? BrandProductListViewDelegate
    }
    var headerImageWidth: CGFloat? {
        return headerCell.imageWidth
    }
    private let headerCell = BrandHeaderCell()
    private var currentHeaderDescription: NSAttributedString?
    
    init() {
        productListComponent = ProductListComponent(withCollectionView: collectionView)
        super.init(successView: collectionView)
        
        backgroundColor = UIColor(named: .White)
        
        switcherDataSource = self
        
        productListComponent.delegate = self
        productListComponent.headerSectionInfo = HeaderSectionInfo(view: headerCell, wantsToReceiveScrollEvents: false) { 86 }
        
        headerCell.addTarget(self, action: #selector(BrandProductListView.didTapHeaderCell), forControlEvents: .TouchUpInside)
        
        collectionView.applyProductListConfiguration()
        collectionView.delegate = productListComponent
        collectionView.dataSource = productListComponent
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateBrandInfo(imageUrl: String, description: NSAttributedString) {
        currentHeaderDescription = description
        headerCell.updateData(withImageUrl: imageUrl, description: description)
    }
    
    func didTapHeaderCell() {
        brandListDelegate?.brandProductListDidTapHeader(self)
    }
}

extension BrandProductListView {
    func productListComponent(component: ProductListComponent, didReceiveScrollEventWithContentOffset contentOffset: CGPoint, contentSize: CGSize) {}
}

extension BrandProductListView: ViewSwitcherDataSource {
    func viewSwitcherWantsErrorInfo(view: ViewSwitcher) -> (ErrorText, ErrorImage?) {
        return (tr(.CommonError), UIImage(asset: .Error))
    }
    
    func viewSwitcherWantsEmptyView(view: ViewSwitcher) -> UIView? {
        let emptyView = ProductListEmptyView()
        emptyView.descriptionText = tr(.ProductListEmptyDescription)
        return emptyView
    }
}