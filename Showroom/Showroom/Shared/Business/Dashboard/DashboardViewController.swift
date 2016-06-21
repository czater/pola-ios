import Foundation
import UIKit
import RxSwift

class DashboardViewController: UIViewController, DashboardViewDelegate {
    private let model: DashboardModel
    private var castView: DashboardView { return view as! DashboardView }
    
    private let disposeBag = DisposeBag()
    
    init(resolver: DiResolver) {
        self.model = resolver.resolve(DashboardModel.self)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = DashboardView(modelState: model.state)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        castView.delegate = self
        
        castView.switcherState = .Loading
        castView.recommendationViewSwitcherState = .Loading
        
        fetchContentPromo()
        fetchRecommendations()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        castView.contentInset = UIEdgeInsets(top: topLayoutGuide.length, left: 0, bottom: bottomLayoutGuide.length, right: 0)
    }
    
    private func fetchContentPromo() {
        model.fetchContentPromo().subscribeNext { [weak self] fetchResult in
            guard let strongSelf = self else { return }
            switch fetchResult {
            case .Success(let contentPromoResult):
                logInfo("Fetched content promo: \(contentPromoResult)")
                strongSelf.castView.switcherState = .Success
            case .CacheError(let cacheError):
                logError("Error during fetching content promo, cacheError: \(cacheError)")
            case .NetworkError(let networkError):
                logInfo("Error during fetching content promo, networkError: \(networkError)")
                if strongSelf.model.state.contentPromoResult == nil {
                    strongSelf.castView.switcherState = .Error
                }
            }
            }.addDisposableTo(disposeBag)
    }
    
    private func fetchRecommendations() {
        model.fetchRecommendations().subscribeNext { [weak self] fetchResult in
            guard let strongSelf = self else { return }
            switch fetchResult {
            case .Success(let productRecommendationResult):
                logInfo("Fetched product recommendations: \(productRecommendationResult)")
                strongSelf.castView.recommendationViewSwitcherState = .Success
            case .CacheError(let cacheError):
                logError("Error during fetching product recommendations, cacheError: \(cacheError)")
            case .NetworkError(let networkError):
                logInfo("Error during fetching product recommendations, networkError: \(networkError)")
                if strongSelf.model.state.recommendationsResult == nil {
                    strongSelf.castView.recommendationViewSwitcherState = .Error
                }
            }
            }.addDisposableTo(disposeBag)
    }
    
    // MARK: - DashboardViewDelegate
    
    func dashboardView(dashboardView: DashboardView, didSelectContentPromo contentPromo: ContentPromo) {
//        sendNavigationEvent(ShowProductDetailsEvent()) // TODO: - Change to proper event
    }
    
    func dashboardView(dashboardView: DashboardView, didSelectRecommendation productRecommendation: ProductRecommendation) {
        let imageWidth = dashboardView.recommendationImageWidth
        let context = model.createProductDetailsContext(forRecommendation: productRecommendation, withImageWidth: imageWidth)
        sendNavigationEvent(ShowProductDetailsEvent(context: context))
    }
    
    func dashboardViewDidTapRetryRecommendation(dashboardView: DashboardView) {
        castView.recommendationViewSwitcherState = .Loading
        fetchRecommendations()
    }
    
    // MARK: - ViewSwitchedDelegate
    
    func viewSwitcherDidTapRetry(view: ViewSwitcher) {
        castView.switcherState = .Loading
        fetchContentPromo()
    }
}