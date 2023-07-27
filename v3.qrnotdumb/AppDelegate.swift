//  AppDelegate.swift
//  testtt
// QR code Scan - not working (pre/covid test)
//  Created by Anna Vladimirskaya on 6/28/23.
//

enum ModelType {
    case covid
    case pregnancy
}

class ModelManager {
    static let shared = ModelManager()
    private(set) var currentModel: ModelType?

    private init() {}

    func setModel(_ model: ModelType) {
        self.currentModel = model
        // You can also post a notification here if you prefer
        NotificationCenter.default.post(name: Notification.Name("ModelChanged"), object: nil)
    }
}

import UIKit

@main

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }

        // Extract everything after the pipe "|"
        let segments = components.path.split(separator: "|")
        
        // Debug Printing
            print("Extracted segments from URL: \(segments)")
        
        // Ensure there's content after the pipe
        guard segments.count > 1 else {
            return false
        }
        
        let modelType = String(segments[1])
        print("Model type determined from URL: \(modelType)")

        switch modelType {
        case "covid":
            ModelManager.shared.setModel(.covid)
            NotificationCenter.default.post(name: Notification.Name("ModelChanged"), object: nil)
        case "pregnancy":
            ModelManager.shared.setModel(.pregnancy)
            NotificationCenter.default.post(name: Notification.Name("ModelChanged"), object: nil)
        default:
            return false
        }

        return true
        
        
    }



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle


}
