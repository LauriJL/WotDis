//
//  ViewController.swift
//  WotDis
//
//  Created by Lauri Leskinen on 12.3.2024.
//

import UIKit
import CoreML
import Vision
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // IBOutlets
    @IBOutlet weak var robotLabel: UILabel!
    @IBOutlet weak var gotItRightLabel: UILabel!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var noButton: UIButton!
    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    // Image Picker
    let imagePicker = UIImagePickerController()
    
    // AV Player
    var player: AVAudioPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Wot Dis?"
        self.robotLabel.text = "Take a photo and I'll tell you what it is."
        
        // Hide got it right labels
        let stackItems = [gotItRightLabel,yesButton,noButton,emojiLabel]
        for item in stackItems {
            item?.isHidden = true
        }
        
        // Image picker
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
//        imagePicker.sourceType = .photoLibrary
    }
    
    // Camera button
    @IBAction func cameraPressed(_ sender: UIBarButtonItem) {
        present(imagePicker,animated: true,completion: nil)
        // Hide got it right labels
        let stackItems = [gotItRightLabel,yesButton,noButton,emojiLabel]
        for item in stackItems {
            item?.isHidden = true
        }
    }
    
    // Get image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // Downcast userPickedImage as UIImage...
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            // display image in imageView
            imageView.image = userPickedImage
            // convert image to CIImage
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert image to CIImage.")
            }
            // Detect image
            detect(image:ciImage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Image Detection
    func detect(image: CIImage) {
        
        // Load CoreML model
        guard let model = try? VNCoreMLModel(for: Resnet50(configuration: .init()).model) else {
            fatalError("Loading Resnet50 model failed.")
        }
        
        // Create VNCoreML request
        let request = VNCoreMLRequest(model: model) { request, error in
            // Process image
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image.")
            }
            
            // Robot guesses
            let robot_guess = results.first!.identifier
            let certainty = String(format: "%.2f", results.first!.confidence * 100)
            
            // Present robot's first guess
            let robot_guess_array = robot_guess.components(separatedBy: ", ")
            
            // Set indefinite article
            var indefinite_article = "a"
            let vowels: [Character] = ["a","e","i","o","u"]
            if vowels.contains(robot_guess_array[0].lowercased().first!) {
                indefinite_article = "an"
            }

            self.robotLabel.text = "I'm \(certainty)% confident that this is \(indefinite_article) \(robot_guess_array[0])."
            self.gotItRightLabel.isHidden = false
            self.gotItRightLabel.text = "Did I get it right?"
            self.yesButton.isHidden = false
            self.yesButton.isEnabled = true
            self.noButton.isHidden = false
            self.noButton.isEnabled = true

        }

        // Handler
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print("ERROR: \(error)")
        }
    }
    
    
    @IBAction func yesPressed(_ sender: UIButton) {
        self.emojiLabel.isHidden = false
        self.noButton.isEnabled = false
        self.emojiLabel.text = "😃"
        self.playSound(soundName: "correct")
    }
    
    
    @IBAction func noPressed(_ sender: UIButton) {
        self.emojiLabel.isHidden = false
        self.yesButton.isEnabled = false
        self.emojiLabel.text = "🥴"
        self.playSound(soundName: "wrong")
    }
    
    // MARK: - Player
    func playSound(soundName: String) {
        let url = Bundle.main.url(forResource: soundName, withExtension: "wav")
        player = try! AVAudioPlayer(contentsOf: url!)
        player.play()
    }
}

