//
//  ViewController.swift
//  Diary
//
//  Created by Gunter on 2021/09/10.
//

import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var collectionView: UICollectionView!

  private var diaryList = [Diary]() {
    didSet {
      self.saveDiaryList()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.configureCollectionView()
    self.loadDiaryList()
      //1.수정버튼을 선택하여 수정 후 상세페이지에 수정한 내용 확인
      //2. 상세페이지에서 뒤로가기 버튼 시 뷰컨트롤러에서도 수정된 내용이 보이게 하도록 NotificationCenter 옵저버를 설정
    
      NotificationCenter.default.addObserver(self, selector: #selector(editDiaryNotification(_:)), name: NSNotification.Name("editDiary"), object: nil)
       
      NotificationCenter.default.addObserver(self, selector: #selector(starDiaryNotification(_:)), name: NSNotification.Name("starDiary"), object: nil)
      
      NotificationCenter.default.addObserver(self, selector: #selector(deleteDiaryNotification(_:)), name:NSNotification.Name("deleteDiary"), object: nil)
  }
    

    //콜렉션뷰의 속성을 설정하는 메서드
  private func configureCollectionView() {
    self.collectionView.collectionViewLayout = UICollectionViewFlowLayout()
    // 콜레션뷰의 컨텐츠뷰의 좌우 간격 10만큼 설정
    self.collectionView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    self.collectionView.delegate = self
    self.collectionView.dataSource = self
  }
    
    @objc func editDiaryNotification(_ notification: Notification) {
        guard let diary = notification.object as? Diary else { return }
        //userInfo?["indexPath.row"]로 배열의 요소에 일기가 수정된걸 업데이트하는게 아니라 전달받은 uuid 값이 있는지 확인하고 있으면 그 해당하는 인덱스로 배열에 수정된 일기가 업데이트 되;도록 바꿔서 구현
        guard let index = self.diaryList.firstIndex(where: { $0.uuidString == diary.uuidString }) else { return }
        //guard let row = notification.userInfo?["indexPath.row"] as? Int else { return }
        //self.diaryList[row] = diary //다이어리리스트배열에 로우 값으로 요소애 접근을 하고 해당 배열의 요소를 수정된 다이어리 객체로 변환
        self.diaryList[index] = diary
        self.diaryList = self.diaryList.sorted(by: { //값이 변경되면서 날짜가 변경되어 날짜 내림차순이 변경될 수 도 있어 구현
            $0.date.compare($1.date) == .orderedDescending
        })
        self.collectionView.reloadData()
    }

    @objc func starDiaryNotification(_ notification: Notification) {
        //딕셔너리상태로 값을 전달하기 때문에 [String:Any]
        guard let starDiary = notification.object as? [String:Any] else { return }
        guard let isStar = starDiary["isStar"] as? Bool else { return }
        //guard let indexPath = starDiary["indexPath"] as? IndexPath else { return }
        guard let uuidString = starDiary["uuidString"] as? String else { return }
        guard let index = self.diaryList.firstIndex(where: { $0.uuidString == uuidString }) else { return }
        //self.diaryList[indexPath.row].isStar = isStar
        self.diaryList[index].isStar = isStar
        
    }
    
    @objc func deleteDiaryNotification(_ notification: Notification) {
       // guard let indexPath = notification.object as? IndexPath else { return }
        guard let uuidString = notification.object as? String else { return }
        guard let index = self.diaryList.firstIndex(where: { $0.uuidString == uuidString }) else { return }
        self.diaryList.remove(at: index)
        //단일 섹션이라서 0
        self.collectionView.deleteItems(at:[IndexPath(row:index, section: 0)])
        //self.diaryList.remove(at: indexPath.row) //전달받은 인덱스패치 로우값이 삭제되도록
        //self.collectionView.deleteItems(at:[indexPath]) //전달받은 인덱스패치를 넘겨줘서 콜렉션뷰에 일기가 삭제되도록
    }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let wireDiaryViewContoller = segue.destination as? WriteDiaryViewController {
      wireDiaryViewContoller.delegate = self
    }
  }

  private func saveDiaryList() {
    let date = self.diaryList.map {
      [
        "uuidString": $0.uuidString,
        "title": $0.title,
        "contents": $0.contents,
        "date": $0.date,
        "isStar": $0.isStar
      ]
    }
    let userDefaults = UserDefaults.standard
    userDefaults.set(date, forKey: "diaryList")
  }

  private func loadDiaryList() {
    let userDefaults = UserDefaults.standard
    guard let data = userDefaults.object(forKey: "diaryList") as? [[String: Any]] else { return }
    self.diaryList = data.compactMap {
        guard let uuidString = $0["uuidString"] as? String else { return nil}
      guard let title = $0["title"] as? String else { return nil }
      guard let contents = $0["contents"] as? String else { return nil }
      guard let date = $0["date"] as? Date else { return nil }
      guard let isStar = $0["isStar"] as? Bool else { return nil }
        return Diary(uuidString: uuidString, title: title, contents: contents, date: date, isStar: isStar)
    }
    self.diaryList = self.diaryList.sorted(by: {
      $0.date.compare($1.date) == .orderedDescending
    })
  }

//데이터타입을 전달받으면 문자열로 변환해주는 메서드
  private func dateToString(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yy년 MM월 dd일(EEEEE)"
    formatter.locale = Locale(identifier: "ko_KR")
    return formatter.string(from: date)
  }
}

//콜렉션뷰로 보여주는 컨텐츠를 관리하는 객체
extension ViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.diaryList.count
  }
    // 컬렉션 뷰에 지정된 위치에 표시할 셀의 위치
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiaryCell", for: indexPath) as? DiaryCell else { return UICollectionViewCell() } //다운캐스팅에 실패하면 빈 UICollectionViewCell 반환
    //dequeueReusableCell을 통해 재사용할 셀을 가져오면 셀의 제목과 날짜가 표시되도록 작성
    let diary = self.diaryList[indexPath.row] //배열의 저장되어있는 일기를 가죠옴
    cell.titleLabel.text = diary.title
    cell.dateLabel.text = self.dateToString(date: diary.date)
    return cell
  }
}

//UICollectionViewDelegateFlowLayout채택해서 CollectionView의 레이아웃을 구성
extension ViewController: UICollectionViewDelegateFlowLayout {
    //셀의 사이즈를 설정하는 역할을 하는 메서드 cg사이즈로 설정하고 리턴
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
      //셀이 행에 2개씩이라 셀의 width 값을 아이폰 화면의 너비 값으 2로 나눈 값으로 설정, left,right 행간 간격이 각 10이기 때문에 - 20
    return CGSize(width: (UIScreen.main.bounds.width / 2) - 20, height: 200)
  }
}

extension ViewController: WriteDiaryViewDelegate {
  func didSelectReigster(diary: Diary) { //일기가 작성이 되면 didSelectReigster의 파라미터를 통해 작성된 일기의 내용이 담겨져있는 다이어리 객체가 전달이 됨
    self.diaryList.append(diary) //일기 작성화면에서 등록될 때 마다 다이어리 배열에 등록된 일기가 추가가 된다.
    self.diaryList = self.diaryList.sorted(by: {
      $0.date.compare($1.date) == .orderedDescending
    })
    self.collectionView.reloadData() //일기를 추가할 때 마다 콜렉션뷰의 일기 목록이 표시되게 된다.

  }
}

//일기장 리스트에서 일기를 선택하였을 때 일기 상세로 이동하는 코드작성하기 위한 콜랙션뷰델리게이트
extension ViewController: UICollectionViewDelegate  {
   // 특정 셀이 선택되었음을 알리는 메서드, 다이어리디테일 뷰컨트롤러가 푸시되도록 구현
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 스토리보드에 있는 뷰컨트롤러를 인스턴스화
        guard let viewContoller = self.storyboard?.instantiateViewController(withIdentifier: "DiaryDetailViewController") as? DiaryDetailViewController else { return }
        let diary = self.diaryList[indexPath.row] //선탟된 일기가 먼지 다이어리 상수에 대입
        viewContoller.diary = diary
        viewContoller.indexPath = indexPath
        //viewContoller.delegate = self
        self.navigationController?.pushViewController(viewContoller, animated: true)
    }
    
}


/*
extension ViewController : DiaryDetailViewDelegate {
    func didSelectDelete(indexPath: IndexPath) {
        self.diaryList.remove(at: indexPath.row) //전달받은 인덱스패치 로우값이 삭제되도록
        self.collectionView.deleteItems(at:[indexPath]) //전달받은 인덱스패치를 넘겨줘서 콜렉션뷰에 일기가 삭제되도록
    }
*/
    
    /*
    func didSelectStar(indexPath: IndexPath, isStar: Bool) {
    // 파라미터로 전달된 즐겨찾기 여부를 다이어리 리스트 배열에 업데이트
        self.diaryList[indexPath.row].isStar = isStar
    }

}
*/




