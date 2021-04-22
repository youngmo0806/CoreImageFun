/*
 1. CIImage 객체를 만든다.
 2. CIContext 를 만든다.
 3. CIFilter 를 만든다.
 4. 필터를 적용한 아웃풋을 얻는다.
 */
import UIKit
import Foundation
import CoreImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageOriginal: UIImageView!
    @IBOutlet weak var amountSilder: UISlider!
    
    var context: CIContext!
    var filter: CIFilter!
    var beginImage: CIImage!
    var orientation: UIImage.Orientation = .up
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //1. 이미지 파일 경로를 가지고 있는 URL 객체를 만드는 부분.
        guard let fileUrl = Bundle.main.url(forResource: "life", withExtension: "png") else {
            //이미지가 안뜨고 있네요
            print("~~fileUrl is nil~~")
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
        
        allFilters()
    }
    
    //MARK: - ACTION
    //slider Action
    @IBAction func amountSliderValueChanged(_ sender: UISlider) {
        
        let sliderValue = sender.value
        
//        self.filter.setValue(sliderValue, forKey: kCIInputIntensityKey)
//        guard let outputImage = self.filter.outputImage else { return }
        
        let outputImage = self.oldPhoto(img: beginImage, withAmount: sliderValue)
        
        guard let cgimg = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        
        let newImage = UIImage(cgImage: cgimg, scale: 1, orientation: orientation)
        self.imageView.image = newImage
    }
    
    
    @IBAction func loadPhoto(_ sender: Any) {
        //UIImagePickerController의 인스턴스를 생성
        let imagePickController = UIImagePickerController()
        //UIImagePickerController의 델리게이트를 viewController(=self)로 지정
        imagePickController.delegate = self
        //imagePickerController를 present
        present(imagePickController, animated: true, completion: nil)
    }
    
    @IBAction func savePhoto(_ sender: Any) {
        // 1 - 필터로 부터 CIImage 아웃풋을 얻습니다.
        let imageToSave = filter.outputImage
        
        // 2 - 새로운 소프트웨어 기반의 CIContext 를 생성합니다. 이 CIContext 는 CPU renderer 를 사용합니다.
        let softwareContext = CIContext(options: [CIContextOption.useSoftwareRenderer: true])
        
        // 3 - CGImage 를 생성합니다.
        let cgImg = softwareContext.createCGImage(imageToSave!, from: imageToSave!.extent )
        
        // 4 - 사진 앨범에 CGImage 를 저장합니다.
        let selectedImage = UIImage(cgImage: cgImg!)
        UIImageWriteToSavedPhotosAlbum(selectedImage, nil, nil, nil)
    }
    
    //MARK: - func
    func allFilters()  {
        let allFilter = CIFilter.filterNames(inCategory: kCICategoryBuiltIn)
        
//        print("allFIlter", allFilter)
        
        for filterName in allFilter {
            guard let fltr = CIFilter(name: filterName as String) else {return}
            //print(fltr.attributes)
        }
        
    }
    
    ///oldPhoto 파라미터로 이미지와 감도값을 받는다.
    func oldPhoto(img: CIImage, withAmount intensity: Float) -> CIImage {
        //CIImage를 찍어
        //오래된 사진 처럼 보이게 필터를 입히고,
        //수정된 CIImage를 리턴하겠습니다.
        
        
        //1. 세피아 필터를 앞에서 간단한 시나리오에서 했던 것과 같은 방식처럼 설정합니다.
        //   여러분은 세피아 효과의 강도를 설정하기 위한 메소드 내에 Float 타입의 값을 전달합니다.
        //   이 값은 slider 에 의해서 제공될 것입니다.
        // ym:넘어온 이미지에 세피아 필터를 입히고 필터 감도 값을 세팅한다.
        let sepia = CIFilter(name: "CISepiaTone")
        sepia?.setValue(img, forKey: kCIInputImageKey)
        sepia?.setValue(intensity, forKey: "inputIntensity")
        
        
        //2. 다음의 그림과 같게 보이는 랜덤 노이즈 패턴(+ 지지직 패턴?)을 만드는 필터를 설정합니다.
        //   얘는 어떠한 파라미터도 갖지 않아요. (It doesn't take any parameters.)
        //   여러분은 이 노이즈 패턴을 여러분의 가장 "오래된 사진" 처럼 보이도록 텍스쳐(texture) 효과를 더하기 위해 사용할 것입니다.
        let random = CIFilter(name: "CIRandomGenerator")
        
        //3. 랜덤 노이즈 발생기(generator)의 출력(output)을 바꿔보죠.
        //   여러분은 이 출력을 grayscale(이미지를 회색으로 변경) 으로 바꾸고 싶고, 조금 더 밝게 만들면 효과(회색빛이 얼마나 강한가?)는 덜 드라마틱하게 보일 거에요.
        //   여러분은 인풋 이미지 키(kCInputImageKey)로 "random.outputImage" 프로퍼티가 설정된 것을 주목해야하는데,
        //   이것은 하나의 필터의 출력을 다음 필터의 인풋으로 전달하는 편리한 방식이기 때문이에요..
        //   (업데이트로 인해 메소드 이름이 원문과 다른 부분입니다)
        let lighten = CIFilter(name: "CIColorControls")
        lighten?.setValue(random?.outputImage, forKey: kCIInputImageKey)
        lighten?.setValue(1 - intensity, forKey: "inputBrightness")
        lighten?.setValue(0, forKey: "inputSaturation")
        
        //4. "cropped(to:)" 메소드는 CIImage 출력(output)을 가지며 이 이미지를 제공된 사각형으로 잘라(crop)냅니다. 이 경우에서 여러분은 CIRandomGenerator 필터의 출력을 잘라내야할 필요가 있는데,
        //이 (랜덤 제너레이터) 필터 친구는 무한히 타일링을 하기 때문입니다.
        //(+ 타일링이란 말이 좀 어려울 수 있는데, 쉽게 필터의 크기가 무한하기 때문에 우리 필터를 적용하길 원하는 이미지의 크기에 맞게 잘라내는 과정이라고 생각하시면 되겠습니다.)
        //만약 여러분이 어떤 지점에서 이 친구를 잘라내주지 않는다면, 우리는 필터가 무한한 크기를 가진다고 말하는 에러를 얻게 될 것입니다.
        //CIImage 는 실제로 이미지 데이터를 포함하지 않으며, 이미지를 만들어내기 위한 '레시피(recipe)' 를 설명하고 있습니다. CIContext 상에서 메소드를 호출할 때까지 데이터는 실제로 프로세싱 되는 것은 아니에요.
        let croppedImage = lighten?.outputImage?.cropped(to: beginImage.extent)
        
        //5. 세피아 필터의 출력물을 CIRandomGenerator 필터의 출력물(output)과 결합합니다.
        //이 필터는 포토샵 레이어 내에서 수행되는 'Hard Light'  설정과 정확히 같은 동작을 수행합니다. (이 말은 다시 말해서) 포토샵에서의 대부분의 필터 옵션은 Core Image 를 사용해서 구현할 수 있다는 것이죠.
        let composite = CIFilter(name: "CIHardLightBlendMode")
        composite?.setValue(sepia?.outputImage, forKey: kCIInputImageKey)
        composite?.setValue(croppedImage, forKey: kCIInputBackgroundImageKey)
        
        //6. 사진의 가장자리에 어둡게 만드는 효과를 주는 비네트 필터를 위의 과정을 통해 합쳐진 출력물(output)에 적용하고 있어요.
        //여러분은 이 효과(effect)의 intensity 와 radius 를 설정하는 slider 로부터 값을 사용하는 것이죠.
        let vignette = CIFilter(name: "CIVignette")
        vignette?.setValue(composite?.outputImage, forKey: kCIInputImageKey)
        vignette?.setValue(intensity * 2, forKey: "inputIntensity")
        vignette?.setValue(intensity, forKey: "inputRadius")
        
        //7. 마지막으로 마지막 필터의 출력물을 리턴합니다.
        return (vignette?.outputImage)!
    }
    
    //MARK: - DelegateMethod
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        print("info : \(info)")
        
        self.dismiss(animated: true, completion: nil)
        
        let gotImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage  //UIImage로 강제 캐스팅
         
        orientation = gotImage.imageOrientation
        
        beginImage = CIImage(image: gotImage)
        filter.setValue(beginImage, forKey: kCIInputImageKey)
        self.amountSliderValueChanged(amountSilder)
        
    }
    
    
//    pjtcns0!@
    
}
