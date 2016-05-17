import Foundation
import RxSwift
import RxCocoa

protocol NetworkClient {
    func request(withRequest urlRequest: NSURLRequest) -> Observable<NSData>
}

protocol NetworkActivityIndicatorController {
    var networkActivityIndicatorVisible: Bool { get set }
}

class HttpClient : NetworkClient {
    private var numberOfCallsToSetVisible = 0
    private let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    
    private(set) var activityIndicatorController: NetworkActivityIndicatorController
    
    init(activityIndicatorController: NetworkActivityIndicatorController) {
        self.activityIndicatorController = activityIndicatorController
    }
    
    var basePath: String {
        let path = NSBundle.mainBundle().pathForResource("Info", ofType: "plist")
        let plistContents = NSDictionary(contentsOfFile: path!)! as Dictionary
        let url = plistContents["BackendURL"]! as! String
        return url
    }
    
    func request(withRequest urlRequest: NSURLRequest) -> Observable<NSData> {
        return Observable.create {
            [unowned self] observer in
            
            logDebug("Sending request: \(urlRequest)")
            
            self.setNetworkActivityIndicatorVisible(true)
            
            let disposable = self.session.rx_data(urlRequest)
                .doOnNext({ _ in logDebug("Response received: \(urlRequest)") })
                .subscribe(onNext: observer.onNext, onCompleted: observer.onCompleted, onError: observer.onError, onDisposed: {
                    self.setNetworkActivityIndicatorVisible(false)
                })
                    
            return disposable
        }
    }
    
    private func setNetworkActivityIndicatorVisible(visible: Bool) {
        if visible {
            numberOfCallsToSetVisible += 1
        } else {
            numberOfCallsToSetVisible -= 1
        }
        activityIndicatorController.networkActivityIndicatorVisible = numberOfCallsToSetVisible > 0
    }
}