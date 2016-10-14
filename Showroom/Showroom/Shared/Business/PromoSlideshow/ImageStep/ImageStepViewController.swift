import Foundation
import UIKit

final class ImageStepViewController: UIViewController, PromoPageInterface, ImageStepViewDelegate {
    private let link: String
    private let duration: Int
    private lazy var timer: Timer = {
        let timer = Timer(duration: self.duration, stepInterval: Constants.promoSlideshowTimerStepInterval)
        timer.delegate = self
        return timer
    }()
    private var castView: ImageStepView { return view as! ImageStepView }
    private var firstLayoutSubviewsPassed = false
    var focused: Bool = false {
        didSet {
            logInfo("focused did set: \(focused)")
            if focused && castView.isImageDownloaded {
                timer.play()
            } else {
                timer.pause()
            }
        }
    }
    var shouldShowProgressViewInPauseState: Bool { return true }
    
    weak var pageDelegate: PromoPageDelegate?
    
    init(with resolver: DiResolver, link: String, duration: Int) {
        self.link = link
        self.duration = duration
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = ImageStepView(link: link)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        castView.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !firstLayoutSubviewsPassed {
            firstLayoutSubviewsPassed = true
            castView.loadImage()
        }
    }
    
    // MARK:- ImageStepViewDelegate
    
    func imageStepViewDidDownloadImage(view: ImageStepView) {
        logInfo("image step view did download image")
        pageDelegate?.promoPageDidDownloadAllData(self)
        if focused {
            timer.play()
        }
    }
    
    func imageStepViewDidTapImageView(view: ImageStepView) {
        logInfo("image step view did tap, timer.paused: \(timer.paused)")
        if timer.paused {
            timer.play()
            pageDelegate?.promoPage(self, willChangePromoPageViewState: .Close, animationDuration: Constants.promoSlideshowStateChangedAnimationDuration)
        } else {
            timer.pause()
            pageDelegate?.promoPage(self, willChangePromoPageViewState: .Paused(shouldShowProgressViewInPauseState), animationDuration: Constants.promoSlideshowStateChangedAnimationDuration)
        }
    }
    
    // MARK:- PromoPageInterface
    
    func didTapPlay() {
        logInfo("did tap play")
        timer.play()
        pageDelegate?.promoPage(self, willChangePromoPageViewState: .Close, animationDuration: Constants.promoSlideshowStateChangedAnimationDuration)
    }
    
    func didTapDismiss() { }
}

extension ImageStepViewController: TimerDelegate {
    func timer(timer: Timer, didChangeProgress progress: Double) {
        pageDelegate?.promoPage(self, didChangeCurrentProgress: progress)
    }
    
    func timerDidEnd(timer: Timer) {
        pageDelegate?.promoPageDidFinished(self)
    }
}