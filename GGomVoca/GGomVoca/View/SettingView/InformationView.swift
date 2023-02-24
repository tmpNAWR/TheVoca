//
//  InformationView.swift
//  GGomVoca
//
//  Created by do hee kim on 2023/02/24.
//

import SwiftUI

struct InformationView: View {
    var body: some View {
        NavigationStack {
            List {
                // 버전 정보
                HStack {
                    Text("버전")
                    Spacer()
                    Text("0.0.1")
                        .foregroundColor(.secondary)
                }
                
                // 라이선스
                NavigationLink {
                    LicenseView()
                } label: {
                    Text("라이선스")
                }

            }
            .navigationTitle("정보")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct InformationView_Previews: PreviewProvider {
    static var previews: some View {
        InformationView()
    }
}
