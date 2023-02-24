//
//  Order.swift
//  GGomVoca
//
//  Created by tae on 2023/02/24.
//

import Foundation

enum Order : String, CaseIterable {
    case byRegistered = "등록순 정렬"
    case byAlphabetic = "사전순 정렬"
    case byRandom = "랜덤 정렬"
}
