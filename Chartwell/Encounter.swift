import Foundation

struct Encounter: Codable {
    var visitID: String
    var date: String
    var facility: String
    var location: String
    var doctor: String
    var address: String
    var reason: String

    enum CodingKeys: String, CodingKey {
        case visitID = "visit_id"
        case date, facility, location, doctor, address, reason
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        visitID = try c.decodeIfPresent(String.self, forKey: .visitID) ?? ""
        date = try c.decodeIfPresent(String.self, forKey: .date) ?? ""
        facility = try c.decodeIfPresent(String.self, forKey: .facility) ?? ""
        location = try c.decodeIfPresent(String.self, forKey: .location) ?? ""
        doctor = try c.decodeIfPresent(String.self, forKey: .doctor) ?? ""
        address = try c.decodeIfPresent(String.self, forKey: .address) ?? ""
        reason = try c.decodeIfPresent(String.self, forKey: .reason) ?? ""
    }

    private static let parser: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let shortFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    var dateValue: Date? { return Encounter.parser.date(from: date) }

    var displayDate: String {
        if let d = dateValue { return Encounter.shortFormatter.string(from: d) }
        return date
    }

    var searchText: String {
        return [visitID, displayDate, facility, location, doctor, address, reason]
            .joined(separator: " ").lowercased()
    }
}

struct EncounterFile: Codable {
    var patient: String?
    var year: Int?
    var encounters: [Encounter]

    static func load(from url: URL) throws -> EncounterFile {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(EncounterFile.self, from: data)
    }
}
