//
//  TodayTopicResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct TodayTopicResponseDTO: Decodable {
    let data: [TodayTopicItemDTO]?
}

struct TodayTopicItemDTO: Decodable {
    let title: String?
    let content: String?
    let date: String?
    let link: String?
}
