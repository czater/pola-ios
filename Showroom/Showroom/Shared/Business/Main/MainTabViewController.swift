import Foundation
import UIKit

enum TabBarAppearance { case Visible, Hidden }

class MainTabViewController: UITabBarController {
    static let tabBarItemImageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)  // Center vertically item without title
    static let basketItemImageInsets = UIEdgeInsets(top: 4, left: 0, bottom: -4, right: 0)
    static let hidingDuration = 0.3
    
    private let basketBadgeContainerView = TabBarItemBadgeContainerView()
    var basketBadgeValue: UInt {
        set { basketBadgeContainerView.badgeValue = newValue }
        get { return basketBadgeContainerView.badgeValue }
    }
    
    var iconsVersion: TabBarIconVersion = .Line {
        didSet {
            let newBarIcons: [TabBarIcon] = [.Dashboard(version: iconsVersion), .Search(version: iconsVersion), .Basket(version: iconsVersion), .Wishlist(version: iconsVersion), .Settings(version: iconsVersion)]
            
            for (viewController, newBarIcon) in zip(viewControllers!, newBarIcons) {
                viewController.tabBarItem = UITabBarItem(tabBarIcon: newBarIcon)
                switch newBarIcon {
                case .Basket: viewController.tabBarItem.imageInsets = MainTabViewController.basketItemImageInsets
                default: viewController.tabBarItem.imageInsets = MainTabViewController.tabBarItemImageInsets
                }
            }
            view.setNeedsLayout()
        }
    }
    
    private(set) var appearance: TabBarAppearance {
        didSet {            
            guard appearance != oldValue else { return }
            let height = self.tabBar.frame.height
            let offsetY = (appearance == .Hidden) ? height : -height
            tabBar.center.y += offsetY
            basketBadgeContainerView.center.y += offsetY
        }
    }
    
    let resolver: DiResolver
    
    init(resolver: DiResolver) {
        self.resolver = resolver
        appearance = .Visible
        super.init(nibName: nil, bundle: nil)
        
        tabBar.translucent = true
        tabBar.tintColor = UIColor(named: .Blue)
        
        viewControllers = [
            createDashboardViewController(),
            createSearchViewController(),
            createBasketViewController(),
            createWishlistViewController(),
            createSettingsViewController(),
        ]
        selectedIndex = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        view.addSubview(basketBadgeContainerView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        basketBadgeContainerView.frame = tabBar.frame
    }
    
    func updateTabBarAppearance(appearance: TabBarAppearance, animationDuration: Double = hidingDuration) {
        UIView.animateWithDuration(animationDuration, delay: 0.0, options: [.BeginFromCurrentState, .CurveEaseInOut], animations: {
            self.appearance = appearance
            }, completion: nil)
    }

    
    // MARK: - creating child view controllers
    func createDashboardViewController() -> DashboardPresenterController {
        let viewController = resolver.resolve(DashboardPresenterController.self)
        viewController.tabBarItem = UITabBarItem(tabBarIcon: .Dashboard(version: iconsVersion))
        viewController.tabBarItem.imageInsets = MainTabViewController.tabBarItemImageInsets
        return viewController
    }
    
    func createSearchViewController() -> SearchViewController {
        let viewController = resolver.resolve(SearchViewController.self)
        viewController.tabBarItem = UITabBarItem(tabBarIcon: .Search(version: iconsVersion))
        viewController.tabBarItem.imageInsets = MainTabViewController.tabBarItemImageInsets
        return viewController
    }
    
    func createBasketViewController() -> BasketNavigationController {
        let navigationController = resolver.resolve(BasketNavigationController.self)
        navigationController.tabBarItem = UITabBarItem(tabBarIcon: .Basket(version: iconsVersion))
        navigationController.tabBarItem.imageInsets = MainTabViewController.basketItemImageInsets
        return navigationController
    }
    
    func createWishlistViewController() -> WishlistViewController {
        let viewController = resolver.resolve(WishlistViewController.self)
        viewController.tabBarItem = UITabBarItem(tabBarIcon: .Wishlist(version: iconsVersion))
        viewController.tabBarItem.imageInsets = MainTabViewController.tabBarItemImageInsets
        return viewController
    }
    
    func createSettingsViewController() -> SettingsViewController {
        let viewController = resolver.resolve(SettingsViewController.self)
        viewController.tabBarItem = UITabBarItem(tabBarIcon: .Settings(version: iconsVersion))
        viewController.tabBarItem.imageInsets = MainTabViewController.tabBarItemImageInsets
        return viewController
    }
}