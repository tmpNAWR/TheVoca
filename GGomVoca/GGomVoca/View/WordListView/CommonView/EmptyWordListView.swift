//
//  EmptyWordListView.swift
//  GGomVoca
//
//  Created by tae on 2023/01/30.
//

import SwiftUI

struct EmptyWordListView: View {
    
    var lang: String
    var langNationality: Nationality {
        switch lang {
        case Nationality.KO.rawValue:
            return .KO
        case Nationality.EN.rawValue:
            return .EN
        case Nationality.FR.rawValue:
            return .FR
        case Nationality.JA.rawValue:
            return .JA
        default:
            return .KO
        }
    }
    var emptyByLang: String {
        switch lang {
        case Nationality.KO.rawValue:
            return "비어 있는"
        case Nationality.EN.rawValue:
            return "empty"
        case Nationality.FR.rawValue:
            return "vide"
        case Nationality.JA.rawValue:
            return "空っぽの"
        default:
            return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 5) {
            if UIDevice.current.model == "iPhone" {
                Image(systemName: "tray")
                    .font(.system(size: 65))
                    .fontWeight(.light)
                    .padding(.bottom, 10)
                Text("\(emptyByLang)")
                    .font(.system(size: 35))
                Text("텅 빈, 비어있는")
                    .font(.system(size: 35))
            } else {
                Image(systemName: "tray")
                    .font(.system(size: 70))
                    .fontWeight(.light)
                    .padding(.bottom, 10)
                Text("\(emptyByLang)")
                    .font(.system(size: 40))
                Text("텅 빈, 비어있는")
                    .font(.system(size: 40))
            }
        }
        .foregroundColor(.secondary)
    }
}

struct EmptyWordListView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyWordListView(lang: "FR")
    }
}
