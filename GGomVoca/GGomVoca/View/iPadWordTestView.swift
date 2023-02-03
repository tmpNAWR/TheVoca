//
//  iPadWordTestView.swift
//  GGomVoca
//
//  Created by Roen White on 2023/02/01.
//

import SwiftUI

// TODO: 아이패드 단어시험
// [] "word", "meaning"에 따라 switch로 분기
// [] isMemorized가 false면 못외운 단어만 시험 보기

struct TestWord: Identifiable {
    let id = UUID()
    var word: String
    var meaning: String
}

private var testWords: [TestWord] = [
    TestWord(word: "昇進", meaning: "승진"),
    TestWord(word: "嫌がる", meaning: "싫어하다"),
    TestWord(word: "宣伝", meaning: "선전"),
    TestWord(word: "こっそり", meaning: "몰래, 살짝, 가만히"),
    TestWord(word: "積む", meaning: "쌓다"),
    TestWord(word: "素敵", meaning: "멋있다, 훌륭하다")
]

struct iPadWordTestView: View {
    // MARK: SuperView Properties
    var testType: String = "word"
    //    var isMemorized: Bool
    
    // MARK: View Properties
    @State private var answers: [String] = Array(repeating: "", count: testWords.count)
    
    @State private var testTime: Int = 30 * testWords.count
    private var timeRemaining: String {
        testTime > 0 ? convertSecondsToTime(timeInSeconds: testTime) : "시험 종료!"
    }
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // MARK: 타이머 관련 메서드
    func convertSecondsToTime(timeInSeconds: Int) -> String {
            let hours = timeInSeconds / 3600
            let minutes = (timeInSeconds - hours * 3600) / 60
            let seconds = timeInSeconds % 60
            return String(format: "%02i:%02i:%02i", hours,minutes,seconds)
        }
    
    func calcRemain() {
        let calendar = Calendar.current
        let date = Date()
        let value = 30 * testWords.count
        let targetTime : Date = calendar.date(byAdding: .second, value: value, to: date, wrappingComponents: false) ?? Date()
        let remainSeconds = Int(targetTime.timeIntervalSince(date))
        self.testTime = remainSeconds
    }
    
    func cancelTimer() {
        self.timer.upstream.connect().cancel()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    Section {
                        ForEach(testWords.indices, id: \.self) { index in
                            VStack(spacing: 0) {
                                HStack(alignment: .center) {
                                    Text(testType == "meaning" ? testWords[index].word : testWords[index].meaning)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 200, height: 80)
                                    Divider()
                                    TextField("", text: $answers[index], axis: .vertical)
                                        .padding(.vertical)
                                }
                                Divider()
                            }
                        }
                    } header: {
                        VStack(spacing:10) {
                            Divider()
                            
                            HStack {
                                if testType == "word" {
                                    Text("입력 언어를 해당 하는 언어로 변경하고,")
                                }
                                
                                Text("펜슬로 빈 칸에 답을 적어주세요.")
                            }
                            
                            if testType == "word" {
                                Text("뜻이 여러 개인 경우 ,(쉼표)로 구분해 주세요.")
                            }
                            
                            Divider()
                        }
                        .background { Color("offwhite") }
                    } footer: {
                        VStack(spacing:0) {
                            Divider()
                            Text("우상단의 제출버튼을 눌러주세요.").padding(10)
                            Divider()
                        }
                    }
                }
            }
        }
        .background { Color("offwhite") }
        .navigationTitle("남은 시간 : \(timeRemaining)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { calcRemain() }
        .onReceive(timer) { _ in
            if testTime > 0 {
                testTime -= 1
            } else {
                cancelTimer()
            }
        }
        .onDisappear {
            cancelTimer()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("제출") {
                    print("제출")
                }
            }
        }
    }
}

struct iPadWordTestView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            iPadWordTestView()
        }
    }
}