//
//  ViewController.swift
//  TFLiteDemoApp
//
//  Created by Himanshu on 12/05/25.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private let imageView = UIImageView()
    private let captureButton = UIButton(type: .system)
    private let picker = UIImagePickerController()
    private let label = UILabel()
    
    var faceDetector: FaceDetectionHelper?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupImageView()
        setupButton()
        setupPicker()
        faceDetector = FaceDetectionHelper(modelName: "model_float32")
    }

    private func setupImageView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.layer.borderWidth = 1
        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ])
    }

    private func setupButton() {
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.setTitle("Capture Selfie", for: .normal)
        captureButton.addTarget(self, action: #selector(openCamera), for: .touchUpInside)
        view.addSubview(captureButton)

        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 30)
        ])
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Test"
        label.textColor = .black
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: captureButton.bottomAnchor, constant: 30)
        ])
    }

    private func setupPicker() {
        picker.delegate = self
        picker.sourceType = .camera
        picker.cameraDevice = .front
        picker.allowsEditing = false
    }

    @objc private func openCamera() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        self.present(self.picker, animated: true, completion: nil)
                    } else {
                        self.showAlert("Camera not available.")
                    }
                } else {
                    self.showAlert("Camera access is denied. Please enable it in Settings.")
                }
            }
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)

        if let image = info[.originalImage] as? UIImage {
            imageView.image = image
            let text = faceDetector?.detectAndShow(image: image)
            self.label.text = text
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
