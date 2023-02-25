//
//  ContributorsView.swift
//  GGomVoca
//
//  Created by do hee kim on 2023/02/23.
//

import SwiftUI

struct TempNAWR: Identifiable {
    var id = UUID().uuidString
    var name: String
    var image: String
    var github: String
    var email: String
    var task: String
}

extension TempNAWR {
    static let members: [TempNAWR] = [
        TempNAWR(
            name: "고정민",
            image: "https://avatars.githubusercontent.com/u/68258365?v=4",
            github: "https://github.com/eigen98",
            email: "ko_su@naver.com",
            task: "iOS Client Developer"
        ),
        TempNAWR(
            name: "고도현",
            image:"https://avatars.githubusercontent.com/u/33795856?v=4",
            github: "https://github.com/k906506",
            email: "k906506@gmail.com",
            task: "iOS Client Developer"
        ),
        TempNAWR(
            name: "김도희",
            image:"https://avatars.githubusercontent.com/u/57763334?v=4",
            github: "https://github.com/ehvkddl",
            email: "ehvkddl@gmail.com",
            task: "iOS Client Developer"
        ),
        TempNAWR(
            name: "백수민",
            image: "https://avatars.githubusercontent.com/u/73203944?v=4",
            github: "https://github.com/steady-on",
            email: "whitebsm93@gmail.com",
            task: "PM, iOS Client Developer"
        ),
        TempNAWR(
            name: "유승태",
            image: "https://avatars.githubusercontent.com/u/69609972?v=4",
            github: "https://github.com/gxdxt",
            email: "yxxsxxny@gmail.com",
            task: "iOS Client Developer"
        )
    ]
}

struct ContributorsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        
        ScrollView(showsIndicators: false) {
            VStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .foregroundColor(.gray)
                .padding([.trailing, .top] , 20)
                .horizontalAlignSetting(.trailing)
                
                ForEach(TempNAWR.members) { member in
                    HStack {
                        VStack(alignment: .center) {
                            AsyncImage(
                                url: URL(string: member.image),
                                content: { image in
                                    image.resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: 60, maxHeight: 60)
                                        .clipShape(Circle())
                                },
                                placeholder: {
                                    ProgressView()
                                }
                            )
                            Text("TheVoca")
                                .font(.caption2)
                            Text(member.name)
                                .bold()
                        }
                        
                        Divider()
                            .frame(height: 100)
                            .padding(.horizontal, 5)
                        
                        VStack(alignment: .leading) {
                            HStack(spacing: 5) {
                                Image("github-mark")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Link(destination: URL(string: member.github)!) {
                                    Text(member.github)
                                }
                                .foregroundColor(.black)
                            }
                            HStack(spacing: 5) {
                                Image(systemName: "envelope.fill")
                                    .frame(width: 20, height: 20)
                                Text(member.email)
                            }
                            
                            HStack(spacing: 5) {
                                Image(systemName: "person.fill")
                                    .frame(width: 20, height: 20)
                                Text(member.task)
                            }
                        }
                    }
                    .frame(width: 351, height: 195)
                    .background {
                        Rectangle()
                            .foregroundColor(.white)
                            .shadow(radius: 5, x: 5, y: 5)
                    }
                }
                .padding(20)
            }
        }
        .background {
            Color("fourseason")
        }
    }
}

struct ContributorsView_Previews: PreviewProvider {
    static var previews: some View {
        ContributorsView()
    }
}
