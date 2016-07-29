import UIKit
import CoreLocation
import RxSwift

protocol EditKioskViewControllerDelegate: class {
    func editKioskViewControllerDidChooseKiosk(viewController: EditKioskViewController)
}

class EditKioskViewController: UIViewController, EditKioskViewDelegate {
    private let model: EditKioskModel
    private let disposeBag = DisposeBag()
    
    private var castView: EditKioskView { return view as! EditKioskView }
    
    weak var delegate: EditKioskViewControllerDelegate?
    
    init(with resolver: DiResolver, and checkoutModel: CheckoutModel) {
        self.model = resolver.resolve(EditKioskModel.self, argument: checkoutModel)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = EditKioskView(kioskSearchString: model.checkoutModel.state.selectedAddress?.displayAddress )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        castView.delegate = self
        
        if let searchString = castView.searchString {
            fetchKiosks(withAddressString: searchString)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        logAnalyticsShowScreen(.CheckoutKioskSelection)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        castView.registerOnKeyboardEvent()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        castView.unregisterOnKeyboardEvent()
    }
    
    func fetchKiosks(withAddressString addressString: String) {
        castView.internalSwitcherState = .Loading
        castView.selectedIndex = nil
        
        model.fetchKiosks(withAddressString: addressString)
            .subscribe {[weak self] (kiosksResult: Event<KioskResult>) in
                guard let `self` = self else { return }
                switch kiosksResult {
                case .Error(let error):
                    logInfo("fetched kiosks error: \(error)")
                    if let error = error as? CLError {
                        switch error {
                        case .GeocodeFoundNoResult:
                            self.castView.internalSwitcherState = .Empty
                            self.castView.geocodingErrorVisible = true
                        case .Network:
                            self.castView.internalSwitcherState = .Error
                            self.castView.geocodingErrorVisible = false
                        case .GeocodeCanceled:
                            break
                        default:
                            self.castView.internalSwitcherState = .Success
                            self.castView.geocodingErrorVisible = true
                        }
                    } else {
                        self.castView.internalSwitcherState = .Error
                    }
                case .Next(let result):
                    logInfo("fetched kiosks: \(result.kiosks)")
                    self.castView.updateKiosks(result.kiosks)
                    self.castView.internalSwitcherState = .Success
                    self.castView.geocodingErrorVisible = false
                default: break
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    // MARK: EditKioskViewDelegate
    
    func editKioskView(view: EditKioskView, didReturnSearchString searchString: String) {
        fetchKiosks(withAddressString: searchString)
    }
    
    func editKioskView(view: EditKioskView, didChooseKioskAtIndex kioskIndex: Int) {
        guard let kiosks = model.kiosks else { return }
        
        castView.switcherState = .ModalLoading
        
        let kiosk = kiosks[kioskIndex]
        model.checkoutModel.update(withSelected: kiosk).subscribe { [weak self] event in
            guard let `self` = self else { return }
            
            self.castView.switcherState = .Success
            
            switch event {
            case .Next():
                logInfo("Updated selected kiosk \(kiosk)")
                self.delegate?.editKioskViewControllerDidChooseKiosk(self)
            case .Error(let error):
                logError("Couldn't updated kiosk \(kiosk) with error \(error)")
            default: break
            }
        }.addDisposableTo(disposeBag)
    }
    
    // MARK: ViewSwitcherDelegate
    
    func viewSwitcherDidTapRetry(view: ViewSwitcher) {
        guard let searchString = castView.searchString else { return }
        fetchKiosks(withAddressString: searchString)
    }
}

extension UserAddress {
    private var displayAddress: String {
        return "\(streetAndAppartmentNumbers), \(city)"
    }
}


