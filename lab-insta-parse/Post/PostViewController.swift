//
//  PostViewController.swift
//  lab-insta-parse
//

import UIKit
import PhotosUI
import ParseSwift

private enum SessionGate {
    static let key = "hasPostedThisSession"
}

class PostViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var captionTextField: UITextField!
    @IBOutlet weak var previewImageView: UIImageView!

    private var pickedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func onPickedImageTapped(_ sender: UIBarButtonItem) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.preferredAssetRepresentationMode = .current
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction func onShareTapped(_ sender: Any) {
        view.endEditing(true)

        guard let currentUser = User.current else {
            showAlert(description: "Please log in before sharing a post.")
            return
        }

        guard let image = pickedImage,
              let imageData = image.jpegData(compressionQuality: 0.1) else {
            showAlert(description: "Pick a photo first.")
            return
        }

        let imageFile = ParseFile(name: "image.jpg", data: imageData)

        var post = Post()
        post.user = currentUser          // link to user (required for gate)
        post.imageFile = imageFile
        post.caption = captionTextField.text

        post.save { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let saved):
                    print("✅ Post Saved. id=\(saved.objectId ?? "nil"), user=\(saved.user?.objectId ?? "nil")")

                    // Mark this session as having posted and notify the feed
                    UserDefaults.standard.set(true, forKey: SessionGate.key)
                    NotificationCenter.default.post(name: .didCreatePost, object: nil)

                    self?.navigationController?.popViewController(animated: true)

                case .failure(let error):
                    self?.showAlert(description: error.localizedDescription)
                }
            }
        }
    }

    @IBAction func onViewTapped(_ sender: Any) {
        view.endEditing(true)
    }

    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...",
                                                message: description ?? "Please try again...",
                                                preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}

// MARK: - Photo picker

extension PostViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let image = object as? UIImage else {
                self?.showAlert()
                return
            }
            if let error = error {
                self?.showAlert(description: error.localizedDescription)
                return
            }
            DispatchQueue.main.async {
                self?.previewImageView.image = image
                self?.pickedImage = image
            }
        }
    }
}

// MARK: - Cross-screen notification

extension Notification.Name {
    static let didCreatePost = Notification.Name("didCreatePost")
}
