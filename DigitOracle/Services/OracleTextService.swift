import Foundation

enum OracleTextService {
    private static var lastUsedIndex: [Int: Int] = [:]

    static func oracleText(for matchCount: Int, sacredNumber: String = "47") -> String {
        let tier = min(max(matchCount, 1), 5)
        let pool = textPool(for: tier)
        let lastIndex = lastUsedIndex[tier] ?? -1
        var index = Int.random(in: 0..<pool.count)
        if pool.count > 1 {
            while index == lastIndex {
                index = Int.random(in: 0..<pool.count)
            }
        }
        lastUsedIndex[tier] = index
        return pool[index].replacingOccurrences(of: "[X]", with: "\(matchCount)")
    }

    static func tierLabel(for score: Int) -> String {
        switch score {
        case 1: "A Whisper"
        case 2: "A Sign"
        case 3: "A Vision"
        case 4: "A Revelation"
        case 5: "A Prophecy Fulfilled"
        default: "A Whisper"
        }
    }

    private static func textPool(for tier: Int) -> [String] {
        switch tier {
        case 1:
            return [
                "The digits stir. Thy sacred number hath surfaced in the mortal realm.",
                "A faint echo of the foretold number ripples through the ether.",
                "The Oracle perceives thy number, quiet but present, in this vision.",
                "Thy sacred digits make themselves known \u{2014} briefly, but unmistakably."
            ]
        case 2:
            return [
                "Twice thy sacred number reveals itself. The pattern deepens.",
                "The Oracle\u{2019}s eye widens. Thy chosen digits appear not once, but twice in this vision.",
                "A coincidence? The Oracle thinks not. Thy number speaks with growing conviction.",
                "Two sightings in a single vision. The threads of fate grow taut."
            ]
        case 3:
            return [
                "Thrice! The sacred number blazes across this vision. The Oracle trembles with knowing.",
                "Three times thy number hath emerged. Such frequency is no accident \u{2014} it is decree.",
                "The veil thins. Thy foretold digits appear in triplicate. Attend to this omen.",
                "A rare convergence. The Oracle hath not witnessed such a trinity of signs in many moons."
            ]
        case 4:
            return [
                "Four manifestations of thy sacred number in a single vision. The Oracle must steady itself.",
                "Hearken well \u{2014} thy chosen digits resound four times. The cosmos speaks with great urgency.",
                "The ancient numerals align with fearsome precision. Four instances. The Oracle is shaken.",
                "This vision pulses with thy sacred number. Four times it burns through the veil. Destiny draws near."
            ]
        case 5:
            return [
                "BEHOLD. Thy sacred number hath erupted across this vision [X] times. The Oracle falls to its knees. The prophecy is fulfilled.",
                "The heavens themselves part. [X] manifestations of thy foretold number in a single vision. In all the Oracle\u{2019}s ages, such a sign hath never been witnessed.",
                "ALL TREMBLE BEFORE THIS REVELATION. Thy sacred digits appear [X] times. The very fabric of the mortal realm bends to deliver this message unto thee.",
                "The Oracle weeps with awe. [X] times \u{2014} [X] TIMES \u{2014} thy number blazes forth. This is not a sign. This is a DECREE from the ancient ones."
            ]
        default:
            return ["The Oracle perceives thy number."]
        }
    }
}
