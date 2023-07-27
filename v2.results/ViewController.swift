import UIKit
import CoreML
import Vision
import CoreLocation

class ViewController: UIViewController, UINavigationControllerDelegate, CLLocationManagerDelegate {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var button: UIButton!

    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.backgroundColor = .white

        button.backgroundColor = .systemBlue
        button.setTitle("Scan Test", for: .normal)
        button.setTitleColor(.white, for: .normal)

        // Request location authorization
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reset the imageView to its original state
        imageView.image = nil
    }

    @IBAction func didTapButton() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }


    func classifyImage(_ image: UIImage, location: CLLocation?, date: Date) {
        guard let ciImage = CIImage(image: image) else {
            print("Failed to create CIImage from UIImage")
            return
        }

        guard let modelURL = Bundle.main.url(forResource: "antibody_preg1", withExtension: "mlmodelc") else {
            print("Failed to locate Core ML model in the app bundle")
            return
        }

        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            let request = try VNCoreMLRequest(model: VNCoreMLModel(for: mlModel)) { request, error in
                if let error = error {
                    print("Error classifying image: \(error.localizedDescription)")
                    return
                }

                guard let results = request.results as? [VNClassificationObservation],
                      let topResult = results.first else {
                    print("Unable to classify image.")
                    return
                }

                let predictedLabel = topResult.identifier

                DispatchQueue.main.async {
                    // Display results on a new view controller
                    let resultVC = ResultViewController()
                    resultVC.predictedLabel = predictedLabel
                    resultVC.location = location
                    resultVC.date = date
                    resultVC.image = image

                    self.present(resultVC, animated: true, completion: nil)
                }
            }

            let handler = VNImageRequestHandler(ciImage: ciImage)
            try handler.perform([request])
        } catch {
            print("Error performing classification request: \(error.localizedDescription)")
        }
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
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
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

import CoreLocation

class ResultViewController: UIViewController {
    var predictedLabel: String?
    var location: CLLocation?
    var date: Date?
    var image: UIImage?

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

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.addArrangedSubview(logoImageView)
        stackView.addArrangedSubview(imageView)
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

        // Display the symbol based on the classification result
        if let predictedLabel = predictedLabel {
            symbolLabel.text = getSymbolForClassificationResult(predictedLabel)
        }

        getLocationString { [] locationString in
            DispatchQueue.main.async {
                locationLabel.text = locationString
            }
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
