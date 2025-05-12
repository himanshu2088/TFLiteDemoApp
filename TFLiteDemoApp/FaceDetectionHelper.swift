//
//  FaceDetectionHelper.swift
//  TFLiteDemoApp
//
//  Created by Himanshu on 12/05/25.
//

import UIKit
import TensorFlowLite

class FaceDetectionHelper {
    private var interpreter: Interpreter

    init?(modelName: String) {
        guard let modelPath = Bundle.main.path(forResource: modelName, ofType: "tflite") else {
            print("Failed to load model file.")
            return nil
        }

        do {
            interpreter = try Interpreter(modelPath: modelPath)
            try interpreter.allocateTensors()
        } catch {
            print("Failed to create interpreter: \(error)")
            return nil
        }
    }

    func detectAndShow(image: UIImage) -> String {
        guard let (detected, conf) = runFaceDetection(image: image) else { return "" }
        let msg = detected
            ? "Face detected (confidence=\(String(format: "%.2f", conf)))"
            : "No face (max_conf=\(String(format: "%.2f", conf)))"
        return msg
    }

    private func runFaceDetection(image: UIImage) -> (Bool, Float)? {
        let inputSize = 640

        // Resize and normalize image to [0,1]
        guard let resizedImage = image.resize(to: CGSize(width: inputSize, height: inputSize)),
              let inputBuffer = resizedImage.rgbData() else {
            print("Failed to prepare input image.")
            return nil
        }

        do {
            try interpreter.copy(inputBuffer, toInputAt: 0)
            try interpreter.invoke()

            let outputShape = try interpreter.output(at: 0).shape
            let outputData = try interpreter.output(at: 0).data

            let outputFloatArray = outputData.toArray(type: Float.self)
            let numDetections = outputShape.dimensions[1]  // e.g., 300

            // Output shape: [1, 300, 6] → loop through 300 detections
            var maxConf: Float = 0.0

            for i in 0..<numDetections {
                let baseIndex = i * 6
                let conf = outputFloatArray[baseIndex + 4]  // confidence score
                if conf > maxConf {
                    maxConf = conf
                }
            }

            return (maxConf >= 0.5, maxConf)  // Adjust threshold if needed

        } catch {
            print("Error during inference: \(error)")
            return nil
        }
    }
}

extension UIImage {
    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }

    func rgbData() -> Data? {
        guard let cgImage = self.cgImage else { return nil }

        let width = Int(size.width)
        let height = Int(size.height)
        let byteCount = width * height * 3 * MemoryLayout<Float32>.size

        var pixelBuffer = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: &pixelBuffer,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: width * 4,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }

        context.draw(cgImage, in: CGRect(origin: .zero, size: size))

        var floatBuffer = [Float32](repeating: 0, count: width * height * 3)

        for i in 0..<width * height {
            let offset = i * 4
            floatBuffer[i * 3]     = Float32(pixelBuffer[offset])     / 255.0  // R
            floatBuffer[i * 3 + 1] = Float32(pixelBuffer[offset + 1]) / 255.0  // G
            floatBuffer[i * 3 + 2] = Float32(pixelBuffer[offset + 2]) / 255.0  // B
        }

        return Data(buffer: UnsafeBufferPointer(start: &floatBuffer, count: floatBuffer.count))
    }
}

extension Data {
    func toArray<T>(type: T.Type) -> [T] {
        let count = self.count / MemoryLayout<T>.stride
        return self.withUnsafeBytes {
            Array(UnsafeBufferPointer<T>(start: $0.bindMemory(to: T.self).baseAddress, count: count))
        }
    }
}
