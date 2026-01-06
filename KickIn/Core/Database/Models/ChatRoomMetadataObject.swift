//
//  ChatRoomMetadataObject.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import Foundation
import RealmSwift

final class ChatRoomMetadataObject: Object {
    @Persisted(primaryKey: true) var roomId: String
    @Persisted var lastCursor: String?
    @Persisted var hasMoreData: Bool = true
    @Persisted var lastSyncedAt: String?
}
