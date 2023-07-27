import UIKit

enum ModelType {
    case influenza
    case pregnancy
    // Add other model types as needed
}

// Singleton class to manage the extracted QR code data.
class QRCodeDataManager {
    static let shared = QRCodeDataManager()
    
    // Variables to store the extracted data from the QR code
    var extractedData: [String] = []
    var modelType: ModelType? = nil

    private init() {}
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("triggered")
            
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("Invalid URL format.")
            return false
        }

        // Extract everything after the pipe "|"
        let segments = components.path.split(separator: "|")
            
        // Debug Printing
        print("Scanned QR Code URL: \(url)")
        print("Extracted segments from URL: \(segments)")
            
        // Ensure there's content after the pipe
        guard segments.count > 1 else {
            print("URL doesn't contain enough data segments.")
            return false
        }
            
        let modelTypeString = String(segments[1])
        print("Model type determined from URL: \(modelTypeString)")

        switch modelTypeString {
        case "influenza":
            QRCodeDataManager.shared.modelType = .influenza
        case "pregnancy":
            QRCodeDataManager.shared.modelType = .pregnancy
        default:
            print("Invalid model type in URL.")
            return false
        }

        // Update the extractedData in the singleton
        QRCodeDataManager.shared.extractedData = Array(segments.map { String($0) }.dropFirst())
        
        // Debug printing the extracted data
        print("Extracted Data stored in DataManager: \(QRCodeDataManager.shared.extractedData)")
                
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            let url = userActivity.webpageURL!
            print("App opened with URL from userActivity: \(url)")
            // Process the URL further, if it's your URL
            return true
        }
        return false
    }
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        print("App opened with handleOpen method.")
        return true
    }
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        print("URL opened from: \(sourceApplication ?? "Unknown source")")
        return true
    }


}
