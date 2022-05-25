//
//  WriteDiaryViewController.swift
//  Diary
//
//  Created by qualson on 2022/02/18.
//

import UIKit

// 일기장 상세에서 수정버튼을 선택 시 WriteDiaryViewController에 수정할 다이어리 객체를 전달받을 수 있게 프로퍼티를 하나 추가
enum DiaryEditorMode {
    case new
    case edit(IndexPath, Diary)
}

//델리게이트를 통해서 일기장에 리스트에 일기가 작성된  다이어리 객체를 전달하려고 함
protocol WriteDiaryViewDelegate: AnyObject {
    func didSelectReigster(diary: Diary) //이 메서드에 일기가 작성된 다이어리 객체를 전달
    
}

class WriteDiaryViewController: UIViewController {

    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var contentsTextView: UITextView!
    //@IBOutlet var dateTextView: UITextView!
  
    @IBOutlet var confirmButton: UIBarButtonItem!
    @IBOutlet var dateTextField: UITextField!
    
    private let datePicker = UIDatePicker()
    private var diaryDate: Date? //datePicker에서 선택된 date를 저장하는 프로퍼티
    weak var delegate: WriteDiaryViewDelegate?
    //DiaryEditorMode 타입을 저장하는 프로퍼티
    var diaryEditorMode: DiaryEditorMode = .new
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureContentsTextView()
        self.configureDatePicker()
        self.configureInputField()
        self.configureEditMode()
        self.confirmButton.isEnabled = false //등록버튼이 비활성화 되게 => 이유는 제목 내용 날짜를 모두 선택해야 등록버튼이 활성화 되어야 되기 때믄

    }
    
    // 일기장 상세에서 수정버튼을 선택 시 이동되는 화면
    private func configureEditMode() {
        switch self.diaryEditorMode {
         case let .edit(_, diary):
            self.titleTextField.text = diary.title
            self.contentsTextView.text = diary.contents
            self.dateTextField.text = self.dateToString(date: diary.date)
            self.diaryDate = diary.date
            self.confirmButton.title = "수정"
        
        default:
            break
        }
    }
    
    private func dateToString(date: Date) -> String {
      let formatter = DateFormatter()
      formatter.dateFormat = "yy년 MM월 dd일(EEEEE)"
      formatter.locale = Locale(identifier: "ko_KR")
      return formatter.string(from: date)
    }
    
    //일기 내용을 작성하는 텍스트필드에 보더값 주기
    private func configureContentsTextView() {
        let borderColr = UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1.0)
        self.contentsTextView.layer.borderColor = borderColr.cgColor
        self.contentsTextView.layer.borderWidth = 0.5
        self.contentsTextView.layer.cornerRadius = 5.0
    }
    
    private func configureDatePicker() {
        self.datePicker.datePickerMode = .date
        self.datePicker.preferredDatePickerStyle = .wheels
        //addTarget에는 UIViewController 객체가 이벤트에 응답하는 방식을 설정하는 메서드
        //첫번째 타켓 파라미터: 해당 뷰컨트롤러에서 처리할거기때문에 self, 두번째 액션에는 이벤트에 발생했을 때 그에 맞춰 호출할 메서드
        self.datePicker.addTarget(self, action: #selector(dataPickerValueDidChange(_:)), for: .valueChanged)
        //datePicker의 값이 바뀔 때 마다 dataPickerValueDidChange를 호출하고 해당 메서드 파라미터를 통해 변경된 datePicker의 상태를 UIDatePicker로 전달을 하게되는 구조
        self.datePicker.locale = Locale(identifier: "ko-KR")
        self.dateTextField.inputView = self.datePicker //dateTextView 키보드가 아닌 datePicker가 노출
    }
    
    //제목/날짜 텍스트필드 역시 텍스트가 입력될 때마다 validateInputField()을 호출해서 등록 버튼 활성화 여부 판단
    private func configureInputField() {
        self.contentsTextView.delegate = self
        self.titleTextField.addTarget(self, action: #selector(titleTextFieldDidChange(_:)), for: .editingChanged) //제목 텍스트 필드에 텍스트가 입력 될 때 마다 titleTextFieldDidChange가 호출
        self.dateTextField.addTarget(self, action: #selector(dateTextFieldDidChange(_:)), for: .editingChanged)
        
    }
    //tabConfirmButton 액션이 호출될 떄 다이어리 객체를 생성하고 delegate에 정의한 didSelectReigster 호출해서 메서드 파라미터에 생성된 다이어리 객체를 전달
    @IBAction func tabConfirmButton(_ sender: UIBarButtonItem) {
        guard let title = self.titleTextField.text else { return }
        guard let contents = self.contentsTextView.text else { return }
        guard let date = self.diaryDate else { return }
        
        //무조건 수정이 일어나도 isStar가 false로 선언되서 즐겨찾기에서 수정 시 즐겨찾기가 풀려버림
        //let diary = Diary(title: title, contents: contents, date: date, isStar: false)
        
        // 일기장 수정에서 수정버튼을 눌렀을 때 일기장 상세화면에서 수정된 화면으로 변경될 수 있도록 구현
        //  수정된 내용을 전달하는 노티피케이트 센터를 구현.  수정이 일어나면 수정된 다이어리 객체를 노티피케이트 센터에 전달하고 노티피케이트 센터를 구독하고 있는 화면에서 수정된 다이어리 객체를 전달받고 뷰에도 수정된 내용이 갱신되도록 구현
        // 노티피케이트 센터?: 등록된 이벤트가 발생하면 해당 이벤트들에 대한 행동을 취하는 것 ex) 한마디로 앱 내에서 아무데서나 메세지를 던지면 앱 내에서 이 매세지를 받을 수 있도록 하는게 이 역할이다. 이벤트버스라고 생각하면 된다. 이벤트는 포스트라는 메서드를 통해 적용하고 이벤트를 받으려면 옵저버를 등록해서 포스트를 전달 받을 수 있다.
        // 1. 노티피케이트 센터의 포스트 메서드를 통해 일기 내용이 수정된 다이어리 객체를 노티피케이트 센터를 옵저빙하는 곳에 전달하도록 구현
        switch self.diaryEditorMode {
        case .new: //일기를 등록하는 행위를 해야하니
            //새로만들땐 즐겨찾기가 false상태로 넣어준다.
            let diary = Diary(uuidString: UUID().uuidString, title: title, contents: contents, date: date, isStar: false)
            self.delegate?.didSelectReigster(diary: diary)
            
        case let .edit(IndexPath, diary)://일기를 수정해야 하는 행위를 해야함 케이스 문안에 포스트 메서드를 통해 수정된 다이어리 객체를 전달하는 코드를 구현
            //에딧에서는 현재 즐겨찾기 상태를 넣어준다.
            let diary = Diary(uuidString: UUID().uuidString, title: title, contents: contents, date: date, isStar: diary.isStar)
            NotificationCenter.default.post(
                name: NSNotification.Name("editDiary"), //name: 이 이름을 가지고 NotificationCenter 옵저버에서 설정한 이름의 이벤트가 발생하였는지 관찰
                object: diary, // NotificationCenter Center를 통해 전달할 객체
                userInfo: nil
                //userInfo: ["indexPath.row" : IndexPath.row] //NotificationCenter과 관련된 값, 수정이 일어나면 콜렉션뷰리스트에도 수정이 일어나야 하기 때문에 배열 형태로
            )
            //수정버튼을 눌렀을 떄 NotificationCenter가 editDiary라는 Notificationkey를 옵저빙하는 곳에 수정된 다이어리 객체를 전달하게 된다.
        }
        
        
        //self.delegate?.didSelectReigster(diary: diary)
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func dataPickerValueDidChange(_ datePicker: UIDatePicker) {
        let formmater = DateFormatter() //DateFormatter()객체는 날짜와 텍스트를 반환해주는 역할 => 데이트타입을 사람이 읽을 수 있는 형식으로 변환시켜주거나, 반대로 날짜형태의 문자열에서 데이터타입으로 변환을 시켜주는 역할
        formmater.dateFormat = "yyyy년 MM월 dd일(EEEEE)"
        formmater.locale = Locale(identifier: "ko_KR")
        self.diaryDate = datePicker.date
        self.dateTextField.text = formmater.string(from: datePicker.date)
        self.dateTextField.sendActions(for: .editingChanged) //날짜가 변경될 때마다 .editingChanged를 발생
    }
    
    @objc private func titleTextFieldDidChange(_ textField: UITextField) {
        self.validateInputField() //제목이 입력될 때마다 등록버튼 활성화여부를 판단
    }
    
    @objc private func dateTextFieldDidChange(_ textField: UITextField) {
        self.validateInputField()
    }
    
    //datePicker나 키보드가 활성화 시 화면 터치 시 사라지도록 설정하는 메서드
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true) //유저가 화면을 터치 시 실행
    }
    
    //내용이 입력될 때마다 어떤 메소드를 호출해서 등록 버튼 활성화 여부를 판단하는 메서드
    private func validateInputField() {
        self.confirmButton.isEnabled = !(self.titleTextField.text?.isEmpty ?? true) && !(self.dateTextField.text?.isEmpty ?? true) && !self.contentsTextView.text.isEmpty
    }
}

extension WriteDiaryViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) { //텍스트뷰의 텍스트가 입력될 때마다 호출되는 메서드 = 일기장 내용을 입력할 때마다
        //텍스트뷰에 입력이 될 때마다 validateInputField()메서드를 호출되게 만들어서 등록버튼 활성화를 판단할 수 있게 만든다.
        self.validateInputField()
    }
}





    /*
      
     */
