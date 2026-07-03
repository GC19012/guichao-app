//
//  GchDateHelper.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//

import Foundation

enum GchDateDisplayStyle: String, CaseIterable {
    case fullTimestamp, shortDate, mediumDateTime, compactTime

    var template: String {
        switch self {
        case .fullTimestamp: return "yyyy-MM-dd HH:mm:ss"
        case .shortDate: return "yyyy/MM/dd"
        case .mediumDateTime: return "MMM d, yyyy HH:mm"
        case .compactTime: return "MM-dd HH:mm"
        }
    }
}

struct GchDateOffsetRule: Hashable {
    let name: String
    let component: Calendar.Component
    let value: Int
}

final class GchDateHelper {
    static let shared = GchDateHelper()
    private let calendar = Calendar.current
    private init() {}

    static let offsetRules: [GchDateOffsetRule] = [
        GchDateOffsetRule(name: "tomorrow", component: .day, value: 1),
        GchDateOffsetRule(name: "nextWeek", component: .day, value: 7),
        GchDateOffsetRule(name: "nextMonth", component: .month, value: 1),
        GchDateOffsetRule(name: "nextHour", component: .hour, value: 1),
    ]

    func format(_ date: Date, style: GchDateDisplayStyle, locale: Locale = Locale(identifier: "zh_CN")) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = style.template
        return formatter.string(from: date)
    }

    func offset(_ date: Date, using rule: GchDateOffsetRule) -> Date {
        calendar.date(byAdding: rule.component, value: rule.value, to: date) ?? date
    }

    func isSameWeek(as other: Date, reference: Date) -> Bool {
        calendar.component(.weekOfYear, from: reference) == calendar.component(.weekOfYear, from: other)
    }
}
