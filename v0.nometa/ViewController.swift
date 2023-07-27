import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var button: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.backgroundColor = .secondarySystemBackground

        button.backgroundColor = .systemBlue
        button.setTitle("Scan Test", for: .normal)
        button.setTitleColor(.white, for: .normal)
    }

    @IBAction func didTapButton() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }

    func classifyImage(_ image: UIImage) {
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
                    // Update your app's UI with the predicted label
                    let alertController = UIAlertController(title: "Classification Result", message: predictedLabel, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            }

            let handler = VNImageRequestHandler(ciImage: ciImage)
            try handler.perform([request])
        } catch {
            print("Error performing classification request: \(error.localizedDescription)")
        }
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
        classifyImage(image)
    }
}
