//
//  TopicUIModel.swift
//  KickIn
//
//  Created by 서준일 on 12/22/25.
//

import Foundation

struct TopicUIModel: Identifiable, Hashable {
    let id = UUID()
    let title: String?
    let content: String?
    let date: String?
    let link: String?
}

extension TodayTopicItemDTO {
    func toUIModel() -> TopicUIModel {
        return TopicUIModel(
            title: self.title,
            content: self.content,
            date: self.date,
            link: self.link
        )
    }
}
