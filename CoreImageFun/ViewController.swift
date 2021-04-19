/*
 1. CIImage 객체를 만든다.
 2. CIContext 를 만든다.
 3. CIFilter 를 만든다.
 4. 필터를 적용한 아웃풋을 얻는다.
 */
import UIKit
import Foundation
import CoreImage

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageOriginal: UIImageView!
    
    var context: CIContext!
    var filter: CIFilter!
    var beginImage: CIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("in~~")
        
//        let bundle = Bundle.main
//        print(bundle.bundleURL)
//        print(bundle.bundleIdentifier)
        
        
        //1. 이미지 파일 경로를 가지고 있는 URL 객체를 만드는 부분.
        guard let fileUrl = Bundle.main.url(forResource: "life", withExtension: "png") else {
            print("~~fileUrl is nil~~")
            //이미지가 안뜨고 있네요 ;; 왜 nil이 넘어 올까 흠.
            return
        }

        print("fileUrl : \(fileUrl)")
        
        //2. 사용자의 CIImage를 CIImage(contentsOfURL:)생성자로 만들어낸다.
        self.beginImage = CIImage(contentsOf: fileUrl)
        print("beginImage : \(self.beginImage)")
        
        //3. 다음으로 사용자의 CIFilter 객체를 생성할 것입니다.
        //   CIFilter 생성자는 필터의 이름과 이 필터를 위한 키와 값을 특정짓는 딕셔너리를 가지고 있습니다.
        //   각 필터는 자신의 고유의 값과 유효한 범위의 값의 설정을 가지게 될 것이죠.
        //   "CISepiaTone" 필터는 오직 두 개의 값을 가지는데,
        //   "kCIInputImageKey" (CIImage) 와 "kCIInputIntensityKey" (0과 1사이의 float 타입의 값) 이 있습니다.
        //    여기서는 0.5의 값을 주었죠. 대부분의 필터는 받아오는 값이 없을 경우에 사용될 기본 값을 가지고 있습니다.
        //    하나의 예외는 CIImage 인데, 이것은 기본값이 없으므로 값이 제공되어야만 합니다.
        self.filter = CIFilter(name: "CISepiaTone")
        self.filter.setValue(self.beginImage, forKey: kCIInputImageKey)
        self.filter.setValue(0.5, forKey: kCIInputIntensityKey)
        
        guard let filterOutputImage = self.filter.outputImage else { return }
        
        //4. 필터에서 CIImage 를 다시 가져오는 것은 "outputImage" 프로퍼티를 사용하는 것만큼이나 쉽습니다.
        //일단 출력할 CIImage 가 있으면, 그것을 UIImage 로 변환해야 할 것입니다.
        //UIImage(CIImage:) 생성자는 CIImage 로부터 UIImage 를 만들어내죠.
        //일단 사용자가 UIImage 로 변환하면, 사용자는 그냥 그것을 이미지 뷰에 쉽게 더해줌으로서 표시할 수 있어요.

        //->Delete 이렇게 하면 자신이 사용될 때마다 새로운 CIContext를 만들어 낸다. 그래서 아래(new1) 로 변경
        //let newImage = UIImage(ciImage: filterOutputImage)
        //self.imageView.image = newImage
        
        //new 1
        //여기에 CIContext 객체를 설정하고 CGImage 를 그리기 위해 사용합니다.
        //"CIContext(options:)" 생성자는 컬러 포맷과 같은 옵션들을 지정하는 NSDictionary 를 가지며,
        //context 가 CPU 혹은 GPU 상에서 작동하는지 여부를 지정합니다. 이번 앱에서 기본 값은 괜찮으니 argument 로 nil 을 전달하겠습니다.
        self.context = CIContext(options: nil)
        
        //new 2
        //"createCGImage(_ :, from:)" 을 CIImage 와 함께 문맥 상에서 호출하는 것은 새로운 CGImage 인스턴스를 리턴할 것입니다.
        guard let cgimg = context.createCGImage(filterOutputImage, from: filterOutputImage.extent) else {return}
        
        //new 3
        //다음으로 "UIImage(cgImage:)" 생성자를 전처럼 CIImage 로부터 직접 생성하는 것 대신 새롭게 생성된 CGImage 로 부터 UIImage 를 생성하기 위해 사용합니다.
        //(+ 추가 : 이 부분에서, 오브젝티브-C 에서는 메모리 관리 문제가 있었는데, 스위프트에서는 ARC 가 자동적으로 코어 파운데이션 객체들을 릴리즈 해줄 수 있으니 걱정 마세요)
        let newImage = UIImage(cgImage: cgimg)
        self.imageView.image = newImage
        
    }
    
    @IBAction func amountSliderValueChanged(_ sender: UISlider) {
        
        let sliderValue = sender.value
        
        self.filter.setValue(sliderValue, forKey: kCIInputIntensityKey)
        
        guard let outputImage = self.filter.outputImage else { return }
        
        guard let cgimg = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        
        let newImage = UIImage(cgImage: cgimg)
        self.imageView.image = newImage
    }
    
}
