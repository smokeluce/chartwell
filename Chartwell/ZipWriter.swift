import Foundation

// Minimal ZIP writer (stored, no compression). Enough for .docx packages.
final class ZipWriter {
    private var data = Data()
    private var central = Data()
    private var count: UInt16 = 0

    private static let table: [UInt32] = (0..<256).map { i -> UInt32 in
        var c = UInt32(i)
        for _ in 0..<8 {
            c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1)
        }
        return c
    }

    private static func crc32(_ d: Data) -> UInt32 {
        var c: UInt32 = 0xFFFFFFFF
        for b in d {
            c = table[Int((c ^ UInt32(b)) & 0xFF)] ^ (c >> 8)
        }
        return c ^ 0xFFFFFFFF
    }

    private func le16(_ v: UInt16) -> [UInt8] {
        return [UInt8(v & 0xFF), UInt8(v >> 8)]
    }

    private func le32(_ v: UInt32) -> [UInt8] {
        return [UInt8(v & 0xFF), UInt8((v >> 8) & 0xFF), UInt8((v >> 16) & 0xFF), UInt8(v >> 24)]
    }

    func add(_ path: String, _ text: String) {
        add(path, Data(text.utf8))
    }

    func add(_ path: String, _ content: Data) {
        let name = Array(path.utf8)
        let crc = ZipWriter.crc32(content)
        let size = UInt32(content.count)
        let offset = UInt32(data.count)

        var local = [UInt8]()
        local += le32(0x04034b50)
        local += le16(20)
        local += le16(0x0800)
        local += le16(0)
        local += le16(0)
        local += le16(0x21)
        local += le32(crc)
        local += le32(size)
        local += le32(size)
        local += le16(UInt16(name.count))
        local += le16(0)
        local += name
        data.append(contentsOf: local)
        data.append(content)

        var c = [UInt8]()
        c += le32(0x02014b50)
        c += le16(20)
        c += le16(20)
        c += le16(0x0800)
        c += le16(0)
        c += le16(0)
        c += le16(0x21)
        c += le32(crc)
        c += le32(size)
        c += le32(size)
        c += le16(UInt16(name.count))
        c += le16(0)
        c += le16(0)
        c += le16(0)
        c += le16(0)
        c += le32(0)
        c += le32(offset)
        c += name
        central.append(contentsOf: c)
        count += 1
    }

    func finish() -> Data {
        var out = data
        let cdOffset = UInt32(out.count)
        out.append(central)
        var end = [UInt8]()
        end += le32(0x06054b50)
        end += le16(0)
        end += le16(0)
        end += le16(count)
        end += le16(count)
        end += le32(UInt32(central.count))
        end += le32(cdOffset)
        end += le16(0)
        out.append(contentsOf: end)
        return out
    }
}
