import Foundation

final class AddressBook {
    static let shared = AddressBook()
    private static let storeKey = "facilityAddresses"
    private var store: [String: String]

    private init() {
        store = (UserDefaults.standard.dictionary(forKey: AddressBook.storeKey) as? [String: String]) ?? [:]
    }

    private func norm(_ s: String) -> String {
        return s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    func address(for facility: String) -> String {
        return store[norm(facility)] ?? ""
    }

    func resolved(for e: Encounter) -> String {
        let a = address(for: e.facility)
        return a.isEmpty ? e.address : a
    }

    func setAddress(_ a: String, for facility: String) {
        let t = a.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty {
            store.removeValue(forKey: norm(facility))
        } else {
            store[norm(facility)] = t
        }
        UserDefaults.standard.set(store, forKey: AddressBook.storeKey)
    }
}
