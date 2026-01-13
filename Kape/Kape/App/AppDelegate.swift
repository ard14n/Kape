import UIKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    
    /// Global lock for orientation. Defaults to .all.
    static var orientationLock = UIInterfaceOrientationMask.all
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}
