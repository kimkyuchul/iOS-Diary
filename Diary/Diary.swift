//
//  Diary.swift
//  Diary
//
//  Created by qualson on 2022/02/19.
//

import Foundation

//작성한 일기가 콜렉션뷰에 보여지도록 하기 위한 구조체 작성

struct Diary {
    //일기를 생성할 때마다 고유한 uuid값이 저장댐
    var uuidString: String
    var title: String //일기제목
    var contents: String //일기내용
    var date: Date //일기가 작성된 날짜
    var isStar: Bool //즐겨찾기 여부
} 
