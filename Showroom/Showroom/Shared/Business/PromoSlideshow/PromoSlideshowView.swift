import Foundation
import UIKit

protocol PromoSlideshowViewDelegate: ViewSwitcherDelegate {
    func promoSlideshowDidTapClose(promoSlideshow: PromoSlideshowView)
    func promoSlideshowWillBeginPageChanging(promoSlideshow: PromoSlideshowView)
    func promoSlideshowDidEndPageChanging(promoSlideshow: PromoSlideshowView)
}

enum PromoSlideshowCloseButtonState {
    case Close
    case Dismiss
    case Play
}

final class PromoSlideshowView: UIView, UICollectionViewDelegate, ModalPanDismissable {
    private let closeButton = UIButton(type: .Custom)
    private let viewSwitcher: ViewSwitcher
    private let contentView = UIView()
    private let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
    private let progressView = PromoSlideshowProgressView()
    
    private let dataSource: PromoSlideshowDataSource
    var pageHandler: PromoSlideshowPageHandler? {
        set { dataSource.pageHandler = newValue }
        get { return dataSource.pageHandler }
    }
    var currentPageIndex: Int { return collectionView.currentPageIndex }
    private(set) var closeButtonState: PromoSlideshowCloseButtonState = .Close {
        didSet {
            switch closeButtonState {
            case .Close:
                closeButton.setImage(UIImage(asset: .Ic_close), forState: .Normal)
            case .Dismiss:
                closeButton.setImage(UIImage(asset: .Ic_chevron_down), forState: .Normal)
            case .Play:
                closeButton.setImage(UIImage(asset: .Play_back), forState: .Normal)
            }
        }
    }
    var progressEnded = false {
        didSet {
            progressView.alpha = shouldProgressBeVisible ? 1 : 0
            collectionView.scrollEnabled = (!progressEnded && viewState == .Close)
        }
    }
    var viewState: PromoPageViewState = .Close {
        didSet {
            if viewState == .Close || viewState == .Dismiss {
                closeButtonState = viewState == .Close ? .Close : .Dismiss
            } else if viewState.isPausedState {
                closeButtonState = .Play
            }
            
            closeButton.alpha = viewState == .FullScreen ? 0 : 1
            progressView.alpha = shouldProgressBeVisible ? 1 : 0
            collectionView.scrollEnabled = (!progressEnded && viewState == .Close)
        }
    }
    var pageCount: Int { return dataSource.pageCount }
    var viewSwitcherAnimationDuration: Double { return viewSwitcher.animationDuration }
    var shouldProgressBeVisible: Bool {
        if progressEnded {
            return false
        } else if let pausedProgressViewVisible = viewState.isPausedProgressViewVisible {
            return pausedProgressViewVisible
        } else {
            return viewState == .Close
        }
    }
    private var panGestureRecognizer: UIPanGestureRecognizer {
        return gestureRecognizers!.find { $0 is UIPanGestureRecognizer } as! UIPanGestureRecognizer
    }
    weak var delegate: PromoSlideshowViewDelegate? {
        didSet {
            viewSwitcher.switcherDelegate = delegate
        }
    }
    weak var modalPanDismissDelegate: ModalPanDismissDelegate?
    
    init() {
        viewSwitcher = ViewSwitcher(successView: contentView)
        dataSource = PromoSlideshowDataSource(with: collectionView)
        super.init(frame: CGRectZero)
        
        viewSwitcher.switcherDataSource = self
        
        backgroundColor = UIColor(named: .White)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didReceivePanGesture))
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
        
        collectionView.backgroundColor = backgroundColor
        collectionView.dataSource = dataSource
        collectionView.delegate = self
        collectionView.configureForPaging(withDirection: .Horizontal)
        
        closeButton.setImage(UIImage(asset: .Ic_close), forState: .Normal)
        closeButton.applyCircleStyle()
        closeButton.addTarget(self, action: #selector(PromoSlideshowView.onCloseButtonTapped), forControlEvents: .TouchUpInside)
        
        contentView.addSubview(collectionView)
        contentView.addSubview(progressView)
        
        addSubview(viewSwitcher)
        addSubview(closeButton)
        
        configureCustomConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func changeSwitcherState(switcherState: ViewSwitcherState, animated: Bool = true) {
        viewSwitcher.changeSwitcherState(switcherState, animated: animated)
    }
    
    func update(with promoSlideshow: PromoSlideshow) {
        collectionView.contentOffset = CGPoint(x: 0, y: 0)
        dataSource.pageCount = promoSlideshow.video.steps.count + 1
        progressView.update(with: promoSlideshow.video)
    }
    
    func update(with progress: ProgressInfoState) {
        progressView.update(with: progress)
    }
    
    func update(with newState: PromoPageViewState, animationDuration: Double?) {
        guard viewState != newState else { return }
        
        layoutIfNeeded()
        UIView.animateWithDuration(animationDuration ?? 0, delay: 0, options: [.CurveEaseInOut], animations: {
            self.viewState = newState
            self.layoutIfNeeded()
            }, completion: nil)
    }
    
    func moveToNextPage() {
        logInfo("move to next page")
        userInteractionEnabled = false
        self.delegate?.promoSlideshowWillBeginPageChanging(self)
        let indexPath = NSIndexPath(forItem: currentPageIndex + 1, inSection: 0)
        collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Left, animated: true)
    }
    
    func pageIndex(forView view: UIView) -> Int? {
        return dataSource.pageIndex(forView: view)
    }
    
    private func configureCustomConstraints() {
        closeButton.snp_makeConstraints { make in
            make.leading.equalToSuperview().offset(Dimensions.defaultMargin)
            make.top.equalToSuperview().offset(Dimensions.modalTopMargin)
            make.width.equalTo(Dimensions.circleButtonDiameter)
            make.height.equalTo(closeButton.snp_width)
        }
        
        viewSwitcher.snp_makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        collectionView.snp_makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        progressView.snp_makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }
    }
    
    @objc private func onCloseButtonTapped(button: UIButton) {
        delegate?.promoSlideshowDidTapClose(self)
    }
    
    @objc private func didReceivePanGesture(gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translationInView(self)
        let velocity = gestureRecognizer.velocityInView(self)
        modalPanDismissDelegate?.modalPanDidMove(withTranslation: translation, velocity: velocity, state: gestureRecognizer.state)
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let size = collectionView.bounds.size
        return CGSize(width: size.width, height: size.height)
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        logInfo("scroll view will begin dragging")
        userInteractionEnabled = false
        self.delegate?.promoSlideshowWillBeginPageChanging(self)
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        logInfo("scroll view did end decelerating")
        self.delegate?.promoSlideshowDidEndPageChanging(self)
        userInteractionEnabled = true
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        logInfo("scoll view did end scrolling animation")
        self.delegate?.promoSlideshowDidEndPageChanging(self)
        userInteractionEnabled = true
    }
}

extension PromoSlideshowView: ViewSwitcherDataSource {
    func viewSwitcherWantsErrorView(view: ViewSwitcher) -> UIView? {
        return ErrorView(errorText: tr(.CommonError), errorImage: UIImage(asset: .Error))
    }
    
    func viewSwitcherWantsEmptyView(view: ViewSwitcher) -> UIView? { return nil }
}

extension PromoSlideshowView: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == panGestureRecognizer && otherGestureRecognizer == collectionView.panGestureRecognizer
    }
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer.isEqual(panGestureRecognizer) else { return false }
        guard gestureRecognizer.numberOfTouches() > 0 else { return false }
        
        let translation = panGestureRecognizer.velocityInView(self.collectionView)
        return fabs(translation.y) > fabs(translation.x) && translation.y > 0
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == panGestureRecognizer && otherGestureRecognizer == collectionView.panGestureRecognizer
    }
}
