import Foundation

extension UInt8 {
    var hexDescription: String {
        return String(format: "%02x", self)
    }
}

func CalulateTable_CRC8() -> [UInt8:UInt8]
{
    let generator: UInt8 = 0x07
    var crcTable: [UInt8:UInt8] = [:]
    /* iterate over all byte values 0 - 255 */
    for divident: UInt8 in 0...254
    {
        var currByte = UInt8(divident)
        /* calculate the CRC-8 value for current byte */
        for _ in 0...7
        {
            if ((currByte & 0xF4) != 0) {
                currByte <<= 1;
                currByte ^= generator;
            }
            else {
                currByte <<= 1;
            }
        }
        /* store CRC value in lookup table */
        crcTable[divident] = currByte;
    }
    return crcTable
}

func Compute_CRC8(data: [UInt8]) -> UInt8
{
    var crcTable = CalulateTable_CRC8()
    var crc: UInt8 = 0xF4
    for b in data {
        /* XOR-in next input byte */
        let data = (b ^ crc)
        /* get current CRC value = remainder */
        crc = crcTable[data] ?? 10
    }

    return crc
}

// Params represents parameters of a CRC-8 algorithm including polynomial and initial value.
// More information about algorithms parametrization and parameter descriptions
// can be found here - http://www.zlib.net/crc_v3.txt
struct Params {
    var Poly: UInt8
    var Init: UInt8
    var RefIn: Bool
    var RefOut: Bool
    var XorOut: UInt8
    var Check: UInt8
    var Name: String
}

// Predefined CRC-8 algorithms.
// List of algorithms with their parameters borrowed from here - http://reveng.sourceforge.net/crc-catalogue/1-15.htm#crc.cat-bits.8
//
// The variables can be used to create Table for the selected algorithm.
let lookup = [
    "CRC8"          : Params (Poly: 0x07, Init: 0x00, RefIn: false, RefOut: false, XorOut: 0x00, Check: 0xF4, Name: "CRC-8"),
    "CRC8_CDMA2000" : Params (Poly: 0x9B, Init: 0xFF, RefIn: false, RefOut: false, XorOut: 0x00, Check: 0xDA, Name: "CRC-8/CDMA2000"),
    "CRC8_DARC"     : Params (Poly: 0x39, Init: 0x00, RefIn: true, RefOut: true, XorOut: 0x00, Check: 0x15, Name: "CRC-8/DARC"),
    "CRC8_DVB_S2"   : Params (Poly: 0xD5, Init: 0x00, RefIn: false, RefOut: false, XorOut: 0x00, Check: 0xBC, Name: "CRC-8/DVB-S2"),
    "CRC8_EBU"      : Params (Poly: 0x1D, Init: 0xFF, RefIn: true, RefOut: true, XorOut: 0x00, Check: 0x97, Name: "CRC-8/EBU"),
    "CRC8_I_CODE"   : Params (Poly: 0x1D, Init: 0xFD, RefIn: false, RefOut: false, XorOut: 0x00, Check: 0x7E, Name: "CRC-8/I-CODE"),
    "CRC8_ITU"      : Params (Poly: 0x07, Init: 0x00, RefIn: false, RefOut: false, XorOut: 0x55, Check: 0xA1, Name: "CRC-8/ITU"),
    "CRC8_MAXIM"    : Params (Poly: 0x31, Init: 0x00, RefIn: true, RefOut: true, XorOut: 0x00, Check: 0xA1, Name: "CRC-8/MAXIM"),
    "CRC8_ROHC"     : Params (Poly: 0x07, Init: 0xFF, RefIn: true, RefOut: true, XorOut: 0x00, Check: 0xD0, Name: "CRC-8/ROHC"),
    "CRC8_WCDMA"    : Params (Poly: 0x9B, Init: 0x00, RefIn: true, RefOut: true, XorOut: 0x00, Check: 0x25, Name: "CRC-8/WCDMA")
]

// Table is a 256-byte table representing polinomial and algorithm settings for efficient processing.
struct Table {
    var params: Params
    var data: [UInt8]
}

// MakeTable returns the Table constructed from the specified algorithm.
func MakeTable(params: Params) -> Table {
    var table = Table(params: params, data: [UInt8](repeating: 0, count: 256))
    for n in 0 ... 255 {
        var crc = UInt8(n)
        for _ in 0...7 {
            let bit = (crc & 0x80) != 0
            crc <<= 1
            if bit {
                crc ^= params.Poly
            }
        }
        table.data[n] = crc
    }
    return table
}

// Init returns the initial value for CRC register corresponding to the specified algorithm.
func Init(table: Table) -> UInt8 {
    return table.params.Init
}

// Update returns the result of adding the bytes in data to the crc.
func Update(crc: UInt8, data: [UInt8], table: Table) -> UInt8 {
    var crcOut: UInt8 = crc
    for d in data {
        var alteredData = d
        if table.params.RefIn {
            alteredData = UInt8(littleEndian: alteredData)
        }
        crcOut = table.data[Int(crcOut^alteredData)]
    }

    return crcOut
}

// Complete returns the result of CRC calculation and post-calculation processing of the crc.
func Complete(crc: UInt8, table: Table) -> UInt8 {
    var alteredCRC: UInt8 = crc
    if table.params.RefOut {
        alteredCRC = UInt8(littleEndian: crc)
    }

    return alteredCRC ^ table.params.XorOut
}

// Checksum returns CRC checksum of data usign scpecified algorithm represented by the Table.
func Checksum(data: [UInt8], table: Table) -> UInt8 {
    var crc = Init(table: table)
    crc = Update(crc: crc, data: data, table: table)
    return Complete(crc: crc, table: table)
}
