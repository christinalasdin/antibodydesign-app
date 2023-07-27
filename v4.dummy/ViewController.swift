import UIKit
import CoreML
import Vision
import CoreLocation

enum QRCodeModelType: String {
    case influenza = "influenza Model"
    case other = "Other Model"
}

class ViewController: UIViewController, UINavigationControllerDelegate, CLLocationManagerDelegate {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var button: UIButton!
    @IBOutlet weak var qrDetailsLabel: UILabel!

    let locationManager = CLLocationManager()

    // Label to display QR Code extracted data
    let qrDataLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(qrDataLabel)

        imageView.backgroundColor = .white
        button.backgroundColor = .systemBlue
        button.setTitle("Scan Test", for: .normal)
        button.setTitleColor(.white, for: .normal)

        // Request location authorization
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()

        
        NotificationCenter.default.addObserver(self, selector: #selector(updateUIWithQRDetails), name: Notification.Name("ModelChanged"), object: nil)

        // Add the QR Data Label to the view
        view.addSubview(qrDataLabel)
        NSLayoutConstraint.activate([
            qrDataLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            qrDataLabel.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 20),
            qrDataLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            qrDataLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    @objc func updateUIWithQRDetails() {
        print("updateUIWithQRDetails called")
        let extractedData = QRCodeDataManager.shared.extractedData
        print("Extracted Data: \(extractedData)")

        guard extractedData.count > 1 else { return }

        let testType = extractedData[0]
        let batchNumber = extractedData[1]

        qrDataLabel.text = "Test type: \(testType) \nBatch#: \(batchNumber)"
    }



    @objc func modelChanged() {
        // Update the label with the extracted data
        let data = QRCodeDataManager.shared.extractedData.joined(separator: "| ")
        qrDataLabel.text = "Extracted Data: \(data)"
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        imageView.image = nil
        if QRCodeDataManager.shared.modelType == nil {
            QRCodeDataManager.shared.modelType = .influenza  // Use the  model as a default
        }
    }

    @IBAction func didTapButton() {
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            present(picker, animated: true)
        }

    func classifyImage(_ image: UIImage, location: CLLocation?, date: Date) {
            let predictedLabel = "positive"

            DispatchQueue.main.async {
                let resultVC = ResultViewController()
                resultVC.predictedLabel = predictedLabel
                resultVC.location = location
                resultVC.date = date
                resultVC.modelType = QRCodeDataManager.shared.modelType
                resultVC.image = image // Pass the captured image

                self.present(resultVC, animated: true, completion: nil)
            }
        }

    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    // CLLocationManagerDelegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
}

extension ViewController: UIImagePickerControllerDelegate {
    internal func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true, completion: nil)

            guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
                return
            }

            imageView.image = image

            // Get current location and date
            locationManager.startUpdatingLocation()
            let date = Date()

            classifyImage(image, location: locationManager.location, date: date)
        }
    }


import UIKit
import CoreLocation

class ResultViewController: UIViewController {
    var predictedLabel: String?
    var location: CLLocation?
    var date: Date?
    var image: UIImage?
    var modelType: ModelType?

    override func viewDidLoad() {
            super.viewDidLoad()

        view.backgroundColor = .white

        let logoImageView = UIImageView(image: UIImage(named: "logo"))
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let resultLabel = UILabel()
        resultLabel.text = "Classification Result: \(predictedLabel ?? "")"
        resultLabel.textAlignment = .center
        resultLabel.font = UIFont.boldSystemFont(ofSize: 20)
        resultLabel.numberOfLines = 0
        resultLabel.translatesAutoresizingMaskIntoConstraints = false

        let symbolLabel = UILabel()
        symbolLabel.textAlignment = .center
        symbolLabel.font = UIFont.systemFont(ofSize: 48)
        symbolLabel.translatesAutoresizingMaskIntoConstraints = false

        let locationLabel = UILabel()
        locationLabel.textAlignment = .center
        locationLabel.numberOfLines = 0
        locationLabel.translatesAutoresizingMaskIntoConstraints = false

        let dateLabel = UILabel()
        dateLabel.text = getFormattedDate()
        dateLabel.textAlignment = .center
        dateLabel.numberOfLines = 0
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let modelTypeLabel = UILabel()
        modelTypeLabel.textAlignment = .center
        modelTypeLabel.font = UIFont.boldSystemFont(ofSize: 20)
        modelTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        modelTypeLabel.text = "Model Used: \(getModelType())"

        let stackView = UIStackView()
                stackView.axis = .vertical
                stackView.spacing = 16
                stackView.translatesAutoresizingMaskIntoConstraints = false

                stackView.addArrangedSubview(modelTypeLabel)
                stackView.addArrangedSubview(logoImageView)
                stackView.addArrangedSubview(imageView) // Add the image view here
                stackView.addArrangedSubview(resultLabel)
                stackView.addArrangedSubview(symbolLabel)
                stackView.addArrangedSubview(locationLabel)
                stackView.addArrangedSubview(dateLabel)

                view.addSubview(stackView)
    

        NSLayoutConstraint.activate([
            logoImageView.heightAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 200),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            locationLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            dateLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])

        if let predictedLabel = predictedLabel {
            symbolLabel.text = getSymbolForClassificationResult(predictedLabel)
        }

        getLocationString { locationString in
            DispatchQueue.main.async {
                locationLabel.text = locationString
            }
        }
    }
    
    private func getModelType() -> String {
        switch modelType {
        case .influenza:
            return "Influenza"
        case .pregnancy:
            return "Pregnancy"
        case .none:
            return "Unknown"
        }
    }
    
    private func getLocationString(completion: @escaping (String) -> Void) {
        guard let location = location else {
            completion("Location: Unknown")
            return
        }

        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else {
                completion("Location: Unknown")
                return
            }

            var locationString = ""

            if let name = placemark.name {
                locationString += name
            }

            if let locality = placemark.locality {
                if !locationString.isEmpty {
                    locationString += ", "
                }
                locationString += locality
            }

            if let country = placemark.country {
                if !locationString.isEmpty {
                    locationString += ", "
                }
                locationString += country
            }

            if locationString.isEmpty {
                completion("Location: Unknown")
            } else {
                completion("Location: \(locationString)")
            }
        }
    }

    private func getFormattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy 'at' hh:mm a"

        return formatter.string(from: date ?? Date())
    }

    private func getSymbolForClassificationResult(_ result: String) -> String {
        switch result {
        case "positive":
            return "✅"
        case "negative":
            return "❌"
        case "invalid":
            return "❓"
        default:
            return "🤷‍♀️"
        }
    }
}
