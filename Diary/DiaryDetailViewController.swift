//
//  DiaryDetailViewController.swift
//  Diary
//
//  Created by qualson on 2022/02/18.
//

import UIKit

//델리게이트를 통해 일기장 상세에서 삭제버튼을 선택 시 메서드를 통해 일기장 리스트화면의 인덱스 패치를 전달하여 다이어리 리스트 배열과 콜랙션 뷰에 일기가 삭제되도록 구현
/*protocol DiaryDetailViewDelegate: AnyObject {
    func didSelectDelete(indexPath: IndexPath)
    //func didSelectStar(indexPath: IndexPath, isStar: Bool)
}
*/

class DiaryDetailViewController: UIViewController {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var contentsTextView: UITextView!
    @IBOutlet var dateLabel: UILabel!
    //우측 상단 즐겨찾기 버튼
    var starButton: UIBarButtonItem?
    //weak var delegate: DiaryDetailViewDelegate?
    
    // 일기잘 리스트 화면에서 전달 받을 프로퍼티
    var diary: Diary?
    var indexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*
         1. 일기장 리스트 화면에서 일기장을 선택했을 때 다이어리 프로퍼티에 다이어리 객체를 넘겨주게 되면 일기장 상세화면에 제목 날짜 내용이 표시되게 된다.
         2. 일기장 리스트에서 일기를 선택하였을 때 일기 상세로 이동하는 코드
         */
        self.configureView()
        //각 탭에서 일기장 상세 페이지의 싱크가 맞지 않는 부분 수정하는 코드
        //즐겨찾기 토글이 일어날때 옵저빙을 통해 셀렉트 함수가 호출되도록 구현
        NotificationCenter.default.addObserver(self, selector: #selector(starDiaryNotification(_:)), name: NSNotification.Name("starDiary"), object: nil)
    }
    
    //프로퍼티를 통해 전달받은 다이어리 객체를 뷰에 초기화 시킴
    
    private func configureView() {
        guard let diary = self.diary else { return }
        self.titleLabel.text = diary.title
        self.contentsTextView.text = diary.contents
        self.dateLabel.text = self.dateToString(date: diary.date) //파라미터에 diary.date를 넘겨줘서 몇년몇월요일 형태로 데이트에 표시되도록
        
        //즐겨찾기 버튼
        self.starButton = UIBarButtonItem(image: nil, style: .plain, target: self, action: #selector(tapStarbutton))
        //즐겨찾기가 등록되어있으면 속이 꽉찬 스타, 아니면 텅빈 스타
        self.starButton?.image = diary.isStar ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
        self.starButton?.tintColor = .orange
        self.navigationItem.rightBarButtonItem = self.starButton
        
    }
    
    //데이터타입을 전달받으면 문자열로 변환해주는 메서드
      private func dateToString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy년 MM월 dd일(EEEEE)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
          
      }
    
    @objc func editDiaryNotification(_ notification :NSNotification) {
        //수정된 다이어리 객체를 전달받아 뷰에 업데이트 되도록 코드 작성
        // editDiaryNotification에서 포스트해서 보낸 수정된 다이어리 객체를 가져오는 코드
        guard let diary = notification.object as? Diary else { return }
        //guard let row = notification.userInfo?["indexPath.row"] as? Int else { return }
        self.diary = diary
        self.configureView()
        //각 탭에서 일기장 상세 페이지의 싱크가 맞지 않는 부분 수정하는 코드
        //즐겨찾기 토글이 일어날때 옵저빙을 통해 셀렉트 함수가 호출되도록 구현

    }
    
    @objc func starDiaryNotification(_ Notification: Notification) {
        guard let starDiary = Notification.object as? [String: Any] else { return }
        guard let isStar = starDiary["isStar"] as? Bool else { return }
        guard let uuidString = starDiary["uuidString"] as? String else { return }
        guard let diary = self.diary else { return }
        //현재 일기상세페이지의 uuidString가 전달받은 uuidString와 같다면
        if diary.uuidString == uuidString {
            //isStar를 전달받은 isStar로 변경
            self.diary?.isStar = isStar
            self.configureView()
        }
    }
    
    @IBAction func tapEditButton(_ sender: UIButton) {
        //수정버튼을 누르면 WriteDiaryViewController이 푸시되도록 구현
        guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "WriteDiaryViewController") as? WriteDiaryViewController else { return }
        // DiaryEditorMode 프로퍼티를 통해서 수정할 다이어리 객체를 전달
        guard let indexPath = self.indexPath else { return }
        guard let diary = self.diary else { return }
        //DiaryEditorMode 프로퍼티의 열거형 값 edit을 전달하고 연관값으로 indexPath, diary
        viewController.diaryEditorMode = .edit(indexPath, diary)
        //Notification을 옵저빙하는 코드
        NotificationCenter.default.addObserver(self, selector: #selector(editDiaryNotification(_:)), name: NSNotification.Name("editDiary"), object: nil)


        self.navigationController?.pushViewController(viewController, animated: true)
    
    }
    
    @IBAction func tapDeleteButton(_ sender: UIButton) {
        //guard let indexPath = self.indexPath else { return }
        guard let uuidString = self.diary?.uuidString else { return }
        //self.delegate?.didSelectDelete(indexPath: indexPath)
        //NotificationCenter.default.post(name:NSNotification.Name("deleteDiary"), object: indexPath, userInfo: nil)
        NotificationCenter.default.post(name:NSNotification.Name("deleteDiary"), object: uuidString, userInfo: nil)
        self.navigationController?.popViewController(animated: true)
    }
    
    //즐겨찾기를 토글하는 기능을 구현
    @objc func tapStarbutton() {
       guard let isStar = self.diary?.isStar else { return }
        //guard let indexPath = self.indexPath else { return }
        
        if isStar { //즐겨찾기 된 상태에서 tap했을 땐 텅 빈 스타
            self.starButton?.image = UIImage(systemName:  "star")
        } else { // 즐겨찾기가 안된 상태에서 tap했을 땐 꽉찬 스타
            self.starButton?.image = UIImage(systemName: "star.fill")
        }
        //true면 false가 대입 false면 true가 대입
        //이코드를 주석처리하고 돌렸을 때 텅빈 스타에서 꽉찬스타로 변경 후 꽉찬 스타에서 텅빈스타로 변경이 안댐
        //즉 2번째 눌렀을때
        self.diary?.isStar = !isStar
        NotificationCenter.default.post(name: NSNotification.Name("starDiary"),
        object: [
            // "diary": self.diary <<- 즐겨찾기 화면에 즐겨찾기 추가한 항목이 추가되도록 구현하기 위해 즐겨찾기가 된 다이어리 객체를 전달
            "diary": self.diary,
            "isStar": self.diary?.isStar ?? false,
            "uuidString": diary?.uuidString
            //"indexPath": indexPath
        ],
        userInfo: nil)
        //기존의 델리게이트 삭제 방식은 1대1방식이기때문에 즐겨찾기 상세에서 삭제/수정가 안댐 그러므로 노티피케이트 로직으로 변경
        //self.delegate?.didSelectStar(indexPath: indexPath, isStar: self.diary?.isStar ?? false)
    }
    
    deinit {
        //관찰이 필요 없을 때 옵저버 제거
        NotificationCenter.default.removeObserver(self)
    }
}

