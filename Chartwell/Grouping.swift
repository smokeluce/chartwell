import Foundation

struct FacilityGroup {
    let facility: String
    let address: String
    let encounters: [Encounter]
}

enum Grouping {
    // Groups visits by facility, keeping the order of each facility's first visit.
    static func byFacility(_ list: [Encounter]) -> [FacilityGroup] {
        var order: [String] = []
        var buckets: [String: [Encounter]] = [:]
        var names: [String: String] = [:]
        for e in list {
            let k = e.facility.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if buckets[k] == nil {
                order.append(k)
                names[k] = e.facility
            }
            buckets[k, default: []].append(e)
        }
        return order.map { k in
            let items = buckets[k] ?? []
            let addr = items.isEmpty ? "" : AddressBook.shared.resolved(for: items[0])
            return FacilityGroup(facility: names[k] ?? k, address: addr, encounters: items)
        }
    }
}
