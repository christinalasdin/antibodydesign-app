//
//  SceneDelegate.swift
//  testtt
//
//  Created by Anna Vladimirskaya on 6/28/23.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        print("Opened via SceneDelegate with URL: \(url)")

        // Decode the URL string
        let decodedURLString = url.absoluteString.removingPercentEncoding ?? ""

        // Use the absolute string of the URL
        let path = decodedURLString.replacingOccurrences(of: "testtt://", with: "")
        
        // Splitting using "|"
        let segments = path.split(separator: "|")
        
        // Debug Printing
        print("Extracted Path: \(path)")
        print("Number of Segments: \(segments.count)")
        for (index, segment) in segments.enumerated() {
            print("Segment \(index): \(segment)")
        }
        
        // Ensure there's content after the pipe
        guard segments.count > 1 else {
            print("URL doesn't contain enough data segments.")
            return
        }
        
        // The first segment after the scheme and the first "|" should be the model type
        let modelTypeString = String(segments[0])
        switch modelTypeString {
        case "influenza":
            QRCodeDataManager.shared.modelType = .influenza
        case "pregnancy":
            QRCodeDataManager.shared.modelType = .pregnancy
        default:
            print("Invalid model type in URL.")
            return
        }
        
        // Update the extractedData in the singleton
        QRCodeDataManager.shared.extractedData = Array(segments.map { String($0) }.dropFirst())
        NotificationCenter.default.post(name: Notification.Name("ModelChanged"), object: nil)

        
        // Debug printing the extracted data
        print("Extracted Data stored in DataManager: \(QRCodeDataManager.shared.extractedData)")
        
        // If you're updating some UI component based on this data, make sure to dispatch it on the main thread.
        DispatchQueue.main.async {
            // Update your UI here
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        if let windowScene = scene as? UIWindowScene {
            if let rootVC = windowScene.windows.first?.rootViewController as? ViewController {
                rootVC.view.setNeedsLayout()
                rootVC.updateUIWithQRDetails() // Add this line
            }
        }
    }




}

