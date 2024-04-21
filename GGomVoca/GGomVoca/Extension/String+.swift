//
//  String+.swift
//  GGomVoca
//
//  Created by tae on 2023/01/30.
//

import Foundation

extension String {
    /// CSV에서 여러 개의 뜻을 하나로 인식하도록 재구성
    var reformForCSV: String {
        return "\"\(self)\""
    }

    /// UIKit 부분 localization
    var localized: String {
        return NSLocalizedString(self, tableName: "Localizable", value: self, comment: "")
     }
}
