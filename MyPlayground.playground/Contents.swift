//: Playground - noun: a place where people can play

import UIKit
import XCTest

extension UIImage {
    class func decodedImage(_ image: UIImage) -> UIImage? {
        guard let newImage = image.cgImage else { return nil }
        
        let colorspace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil,
                                width: newImage.width,
                                height: newImage.height,
                                bitsPerComponent: 8,
                                bytesPerRow: newImage.width * 4,
                                space: colorspace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.draw(newImage, in: CGRect(x: 0, y: 0, width: newImage.width, height: newImage.height))
        
        guard let drawnImage = context?.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: drawnImage)
    }
}

class AsyncImageView: UIView {
    private var _image: UIImage?
    
    var image: UIImage? {
        get {
            return _image
        }
        
        set {
            _image = newValue
            
            layer.contents = nil
            
            guard let image = newValue else { return }
            
            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.main.sync { }
                let decodedImage = UIImage.decodedImage(image)
                DispatchQueue.main.async {
                    self.frame.size = (decodedImage?.size)!
                    self.layer.contents = decodedImage?.cgImage
                }
            }
        }
    }
}

// TEST

class DecodingImageTests: XCTestCase {
    override func setUp() {
        super.setUp()

    }
    
    func testStandardUIImageViewPerformance() {
        measure {
            let image = UIImage(named: "imageA.jpeg")
            _ = UIImageView(image: image)
        }
    }
    
    func testDecodeExtensionPerformance() {
        measure {
            let imageView = AsyncImageView()
            imageView.image = UIImage(named: "imageA.jpeg")

            // Expections are needed when you're testing asynchronus code.
            let expectation = keyValueObservingExpectation(for: imageView.layer, keyPath: "contents", handler: { (aaa, dic) -> Bool in
                return true
            })
            expectation.expectationDescription = "Not fulfilled expectation"
            wait(for: [expectation], timeout: 2.0)
        }
    }
}

class TestObserver: NSObject, XCTestObservation {
    func testCase(_ testCase: XCTestCase,
                  didFailWithDescription description: String,
                  inFile filePath: String?,
                  atLine lineNumber: Int) {
        assertionFailure(description, line: UInt(lineNumber))
    }
}

let testObserver = TestObserver()
XCTestObservationCenter.shared.addTestObserver(testObserver)

DecodingImageTests.defaultTestSuite.run()




