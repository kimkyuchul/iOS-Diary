//
//  starViewController.swift
//  Diary
//
//  Created by qualson on 2022/02/18.
//

import UIKit

class starViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    private var diaryList = [Diary]()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureCollectionView()
        self.loadStarDiaryLsit()
        //즐겨찾기 수정 삭제 Notification 이벤트를 즐겨찾기 화면에 옵저빙해서 이벤트가 일어나면 일기장화면과 즐겨찾기 화면 모두가 동기화 되도록 구현
        NotificationCenter.default.addObserver(self, selector: #selector(editDiaryNotification(_:)), name: NSNotification.Name("editDiary"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(starDiaryNotification(_:)), name: NSNotification.Name("starDiary"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deleteDiaryNotification(_:)), name: NSNotification.Name("deleteDiary"), object: nil)
        
        

    }
    //앱의 초기화 작업은 viewDidLoad에서 해도 되겠지만, 다른뷰에서 갔다가 다시 돌아오는 상황에 해주고 싶은 처리가 있겠죠? 이때는 viewWillAppear에서 처리한다. 왜냐 viewDidLoad는 탭 첫진입 시 로드되고 그뒤로 다른탭 이동 후 현재 탭으로 이동 시 에는 viewWillAppear만 호출댐
    /*override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadStarDiaryLsit()
    }
    */
    //콜렉션뷰의 속성을 정의하는 메서드
    private func configureCollectionView() {
        self.collectionView.collectionViewLayout = UICollectionViewFlowLayout()
        self.collectionView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        //delegate는 어떤 행동에 대한 "동작"을 제시합니다. DataSource는 "보여주는" 것들 담당했다면, delegate는 사용자가 그 보이는 부분중 어떤것을 클릭하거나 어떤 행동을 했을 때, 그 행동에 대한 동작을 수행하게 됩니다. 출처: https://zeddios.tistory.com/137 [ZeddiOS]
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
    
    private func dateToString(date: Date) -> String {
      let formatter = DateFormatter()
      formatter.dateFormat = "yy년 MM월 dd일(EEEEE)"
      formatter.locale = Locale(identifier: "ko_KR")
      return formatter.string(from: date)
    }
    
    private func loadStarDiaryLsit() {
        //사용자의 defaults 데이터베이스에 Key-Value 형태의 데이터를 저장할 수 있는 방법입니다. Foundation framework 에 포함되어 기본으로 제공되는 클래스로 간단하게 데이터를 저장할 수 있습니다.
        //defaults 라고 부르는 이유는 일반적으로 앱 시작시 기본 상태 또는 기본 작동 방식을 결정하는 데 사용되기 때문이라고 합니다.
        let userDeaults = UserDefaults.standard
        guard let data = userDeaults.object(forKey: "diaryList") as? [[String: Any]] else { return }
        self.diaryList = data.compactMap {
            guard let uuidString = $0["uuidString"] as? String else { return nil }
            guard let title = $0["title"] as? String else { return nil }
            guard let contents = $0["contents"] as? String else { return nil }
            guard let date = $0["date"] as? Date else { return nil }
            guard let isStar = $0["isStar"] as? Bool else { return nil }
            return Diary(uuidString: uuidString, title: title, contents: contents, date: date, isStar: isStar)
        }.filter({
            $0.isStar == true
        }).sorted(by: {
            $0.date.compare($1.date) == .orderedDescending
        })
        //viewDidLoad로 호출을 변경함
        //self.collectionView.reloadData()
    }

    @objc func editDiaryNotification(_ notification: Notification) {
        guard let diary = notification.object as? Diary else { return }
        guard let index = self.diaryList.firstIndex(where: { $0.uuidString == diary.uuidString }) else { return }
        //guard let row = notification.userInfo?["indexPath.row"] as? Int else { return }
        //self.diaryList[row] = diary
        self.diaryList[index] = diary
        self.diaryList = self.diaryList.sorted(by: {
            $0.date.compare($1.date) == .orderedDescending
        })
        self.collectionView.reloadData()
    }
    
    @objc func starDiaryNotification(_ notification: Notification) {
        guard let starDiary = notification.object as? [String:Any] else { return }
        guard let diary = starDiary["diary"] as? Diary else { return }
        guard let isStar = starDiary["isStar"] as? Bool else { return }
        //guard let indexPath = starDiary["indexPath"] as? IndexPath else { return }
        guard let uuidString = starDiary["uuidString"] as? String else { return }
        if isStar {
            self.diaryList.append(diary)
            self.diaryList = self.diaryList.sorted(by: {
                $0.date.compare($1.date) == .orderedDescending
            })
            self.collectionView.reloadData()
        } else {
            //self.diaryList.remove(at: indexPath.row)
            //self.collectionView.deleteItems(at: [indexPath])
            //이 guard문이 if문 위에서 호출이 된다면 즐겨찾기를 했을때 즐겨찾기 화면에 추가되지 않는다. 해당하는 일기가 없으면 리턴을 통해서 함수가 조기종료되기 때문에 요부분은 즐겨찾기가 해제 될때 즉 삭제될때만 실행이 되야한다.
            guard let index = self.diaryList.firstIndex(where: { $0.uuidString == uuidString }) else { return }
            self.diaryList.remove(at: index)
            self.collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
        }
    }
    
    @objc func deleteDiaryNotification(_ notification: Notification) {
        //guard let indexPath = notification.object as? IndexPath else { return }
        guard let uuidString = notification.object as? String else { return }
        guard let index = self.diaryList.firstIndex(where: { $0.uuidString == uuidString }) else { return }
        //self.diaryList.remove(at: indexPath.row)
        //self.collectionView.deleteItems(at: [indexPath])
        self.diaryList.remove(at: index)
        self.collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
    }
    
}


extension starViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StarCell", for: indexPath) as? StarCell else { return UICollectionViewCell() }
        let diary = self.diaryList[indexPath.row]
        cell.titleLabel.text = diary.title
        cell.dateLabel.text = self.dateToString(date: diary.date)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //즐겨찾기된 다이어리 리스트배열의 갯수만큼 셀이 표시되도록 구현
        return self.diaryList.count
    }
}
//콜렉션뷰의 레이아웃설정
extension starViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width - 20 , height: 80)
    }
}


extension starViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "DiaryDetailViewController") as? DiaryDetailViewController else { return }
        let diary = self.diaryList[indexPath.row]
        viewController.diary = diary
        viewController.indexPath = indexPath
        self.navigationController?.pushViewController(viewController, animated: true)
        
    }
}
