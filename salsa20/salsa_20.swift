//
//  Salsa20.swift
//  CryptoSwift
//
//  Created by Dennis Michaelis on 27.03.16.
//  Copyright © 2016 Dennis Michaelis. All rights reserved.
//

import Cocoa

#if os(Linux)
    import Glibc
    import SwiftShims
#else
    import Darwin
#endif

public enum CipherError: ErrorType {
    case Encrypt
    case Decrypt
}

public protocol Cipher {
    func cipherEncrypt(bytes: [UInt8]) throws -> [UInt8]
    func cipherDecrypt(bytes: [UInt8]) throws -> [UInt8]

    static func randomIV(blockSize:Int) -> [UInt8]
}

extension Cipher {
    static public func randomIV(blockSize:Int) -> [UInt8] {
        var randomIV:[UInt8] = [UInt8]();
        for _ in 0..<blockSize {
            randomIV.append(UInt8(truncatingBitPattern: cs_arc4random_uniform(256)));
        }
        return randomIV
    }
}

protocol BitshiftOperationsType {
    func <<(lhs: Self, rhs: Self) -> Self
    func >>(lhs: Self, rhs: Self) -> Self
    func <<=(inout lhs: Self, rhs: Self)
    func >>=(inout lhs: Self, rhs: Self)
}

protocol ByteConvertible {
    init(_ value: UInt8)
    init(truncatingBitPattern: UInt64)
}

extension Int    : BitshiftOperationsType, ByteConvertible { }
extension Int8   : BitshiftOperationsType, ByteConvertible { }
extension Int16  : BitshiftOperationsType, ByteConvertible { }
extension Int32  : BitshiftOperationsType, ByteConvertible { }
extension Int64  : BitshiftOperationsType, ByteConvertible {
    init(truncatingBitPattern value: UInt64) {
        self = Int64(bitPattern: value)
    }
}
extension UInt   : BitshiftOperationsType, ByteConvertible { }
extension UInt8  : BitshiftOperationsType, ByteConvertible { }
extension UInt16 : BitshiftOperationsType, ByteConvertible { }
extension UInt32 : BitshiftOperationsType, ByteConvertible { }
extension UInt64 : BitshiftOperationsType, ByteConvertible {
    init(truncatingBitPattern value: UInt64) {
        self = value
    }
}

func cs_arc4random_uniform(upperBound: UInt32) -> UInt32 {
    #if os(Linux)
        return _swift_stdlib_arc4random_uniform(upperBound)
    #else
        return arc4random_uniform(upperBound)
    #endif
}

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

/** Protocol and extensions for integerFromBitsArray. Bit hakish for me, but I can't do it in any other way */
protocol Initiable  {
    init(_ v: Int)
    init(_ v: UInt)
}

extension Int:Initiable {}
extension UInt:Initiable {}
extension UInt8:Initiable {}
extension UInt16:Initiable {}
extension UInt32:Initiable {}
extension UInt64:Initiable {}

/** build bit pattern from array of bits */
func integerFromBitsArray<T: UnsignedIntegerType>(bits: [Bit]) -> T
{
    var bitPattern:T = 0
    for (idx,b) in bits.enumerate() {
        if (b == Bit.One) {
            let bit = T(UIntMax(1) << UIntMax(idx))
            bitPattern = bitPattern | bit
        }
    }
    return bitPattern
}

/// Initialize integer from array of bytes.
/// This method may be slow
func integerWithBytes<T: IntegerType where T:ByteConvertible, T: BitshiftOperationsType>(bytes: [UInt8]) -> T {
    var bytes = bytes.reverse() as Array<UInt8> //FIXME: check it this is equivalent of Array(...)
    if bytes.count < sizeof(T) {
        let paddingCount = sizeof(T) - bytes.count
        if (paddingCount > 0) {
            bytes += [UInt8](count: paddingCount, repeatedValue: 0)
        }
    }

    if sizeof(T) == 1 {
        return T(truncatingBitPattern: UInt64(bytes.first!))
    }

    var result: T = 0
    for byte in bytes.reverse() {
        result = result << 8 | T(byte)
    }
    return result
}

/// Array of bytes, little-endian representation. Don't use if not necessary.
/// I found this method slow
func arrayOfBytes<T>(value:T, length:Int? = nil) -> [UInt8] {
    let totalBytes = length ?? sizeof(T)

    let valuePointer = UnsafeMutablePointer<T>.alloc(1)
    valuePointer.memory = value

    let bytesPointer = UnsafeMutablePointer<UInt8>(valuePointer)
    var bytes = [UInt8](count: totalBytes, repeatedValue: 0)
    for j in 0..<min(sizeof(T),totalBytes) {
        bytes[totalBytes - 1 - j] = (bytesPointer + j).memory
    }

    valuePointer.destroy()
    valuePointer.dealloc(1)

    return bytes
}

// MARK: - shiftLeft

// helper to be able tomake shift operation on T
func << <T:SignedIntegerType>(lhs: T, rhs: Int) -> Int {
    let a = lhs as! Int
    let b = rhs
    return a << b
}

func << <T:UnsignedIntegerType>(lhs: T, rhs: Int) -> UInt {
    let a = lhs as! UInt
    let b = rhs
    return a << b
}

// Generic function itself
// FIXME: this generic function is not as generic as I would. It crashes for smaller types
func shiftLeft<T: SignedIntegerType where T: Initiable>(value: T, count: Int) -> T {
    if (value == 0) {
        return 0;
    }

    let bitsCount = (sizeofValue(value) * 8)
    let shiftCount = Int(Swift.min(count, bitsCount - 1))

    var shiftedValue:T = 0;
    for bitIdx in 0..<bitsCount {
        let bit = T(IntMax(1 << bitIdx))
        if ((value & bit) == bit) {
            shiftedValue = shiftedValue | T(bit << shiftCount)
        }
    }

    if (shiftedValue != 0 && count >= bitsCount) {
        // clear last bit that couldn't be shifted out of range
        shiftedValue = shiftedValue & T(~(1 << (bitsCount - 1)))
    }
    return shiftedValue
}

// for any f*** other Integer type - this part is so non-Generic
func shiftLeft(value: UInt, count: Int) -> UInt {
    return UInt(shiftLeft(Int(value), count: count)) //FIXME: count:
}

func shiftLeft(value: UInt8, count: Int) -> UInt8 {
    return UInt8(shiftLeft(UInt(value), count: count))
}

func shiftLeft(value: UInt16, count: Int) -> UInt16 {
    return UInt16(shiftLeft(UInt(value), count: count))
}

func shiftLeft(value: UInt32, count: Int) -> UInt32 {
    return UInt32(shiftLeft(UInt(value), count: count))
}

func shiftLeft(value: UInt64, count: Int) -> UInt64 {
    return UInt64(shiftLeft(UInt(value), count: count))
}

func shiftLeft(value: Int8, count: Int) -> Int8 {
    return Int8(shiftLeft(Int(value), count: count))
}

func shiftLeft(value: Int16, count: Int) -> Int16 {
    return Int16(shiftLeft(Int(value), count: count))
}

func shiftLeft(value: Int32, count: Int) -> Int32 {
    return Int32(shiftLeft(Int(value), count: count))
}

func shiftLeft(value: Int64, count: Int) -> Int64 {
    return Int64(shiftLeft(Int(value), count: count))
}

protocol _UInt32Type { }
extension UInt32: _UInt32Type {}

/** array of bytes */
extension UInt32 {
    public func bytes(totalBytes: Int = sizeof(UInt32)) -> [UInt8] {
        return arrayOfBytes(self, length: totalBytes)
    }

    public static func withBytes(bytes: ArraySlice<UInt8>) -> UInt32 {
        return UInt32.withBytes(Array(bytes))
    }

    /** Int with array bytes (little-endian) */
    public static func withBytes(bytes: [UInt8]) -> UInt32 {
        return integerWithBytes(bytes)
    }
}

/** Shift bits */
extension UInt32 {

    /** Shift bits to the left. All bits are shifted (including sign bit) */
    private mutating func shiftLeft(count: UInt32) -> UInt32 {
        if (self == 0) {
            return self;
        }

        let bitsCount = UInt32(sizeof(UInt32) * 8)
        let shiftCount = Swift.min(count, bitsCount - 1)
        var shiftedValue:UInt32 = 0;

        for bitIdx in 0..<bitsCount {
            // if bit is set then copy to result and shift left 1
            let bit = 1 << bitIdx
            if ((self & bit) == bit) {
                shiftedValue = shiftedValue | (bit << shiftCount)
            }
        }

        if (shiftedValue != 0 && count >= bitsCount) {
            // clear last bit that couldn't be shifted out of range
            shiftedValue = shiftedValue & (~(1 << (bitsCount - 1)))
        }

        self = shiftedValue
        return self
    }

    /** Shift bits to the right. All bits are shifted (including sign bit) */
    private mutating func shiftRight(count: UInt32) -> UInt32 {
        if (self == 0) {
            return self;
        }

        let bitsCount = UInt32(sizeofValue(self) * 8)

        if (count >= bitsCount) {
            return 0
        }

        let maxBitsForValue = UInt32(floor(log2(Double(self)) + 1))
        let shiftCount = Swift.min(count, maxBitsForValue - 1)
        var shiftedValue:UInt32 = 0;

        for bitIdx in 0..<bitsCount {
            // if bit is set then copy to result and shift left 1
            let bit = 1 << bitIdx
            if ((self & bit) == bit) {
                shiftedValue = shiftedValue | (bit >> shiftCount)
            }
        }
        self = shiftedValue
        return self
    }

}

infix operator &<<= {
associativity none
precedence 160
}

infix operator &<< {
associativity none
precedence 160
}

infix operator &>>= {
associativity none
precedence 160
}

infix operator &>> {
associativity none
precedence 160
}

/** shift left and assign with bits truncation */
public func &<<= (inout lhs: UInt32, rhs: UInt32) {
    lhs.shiftLeft(rhs)
}

/** shift left with bits truncation */
public func &<< (lhs: UInt32, rhs: UInt32) -> UInt32 {
    var l = lhs;
    l.shiftLeft(rhs)
    return l
}

/** shift right and assign with bits truncation */
func &>>= (inout lhs: UInt32, rhs: UInt32) {
    lhs.shiftRight(rhs)
}

/** shift right and assign with bits truncation */
func &>> (lhs: UInt32, rhs: UInt32) -> UInt32 {
    var l = lhs;
    l.shiftRight(rhs)
    return l
}

func rotateLeft(v:UInt8, _ n:UInt8) -> UInt8 {
    return ((v << n) & 0xFF) | (v >> (8 - n))
}

func rotateLeft(v:UInt16, _ n:UInt16) -> UInt16 {
    return ((v << n) & 0xFFFF) | (v >> (16 - n))
}

func rotateLeft(v:UInt32, _ n:UInt32) -> UInt32 {
    return ((v << n) & 0xFFFFFFFF) | (v >> (32 - n))
}

func rotateLeft(x:UInt64, _ n:UInt64) -> UInt64 {
    return (x << n) | (x >> (64 - n))
}

func rotateRight(x:UInt16, n:UInt16) -> UInt16 {
    return (x >> n) | (x << (16 - n))
}

func rotateRight(x:UInt32, n:UInt32) -> UInt32 {
    return (x >> n) | (x << (32 - n))
}

func rotateRight(x:UInt64, n:UInt64) -> UInt64 {
    return ((x >> n) | (x << (64 - n)))
}

func reverseBytes(value: UInt32) -> UInt32 {
    return ((value & 0x000000FF) << 24) | ((value & 0x0000FF00) << 8) | ((value & 0x00FF0000) >> 8)  | ((value & 0xFF000000) >> 24);
}

func toUInt32Array(slice: ArraySlice<UInt8>) -> Array<UInt32> {
    var result = Array<UInt32>()
    result.reserveCapacity(16)

    for idx in slice.startIndex.stride(to: slice.endIndex, by: sizeof(UInt32)) {
        let val1:UInt32 = (UInt32(slice[idx.advancedBy(3)]) << 24)
        let val2:UInt32 = (UInt32(slice[idx.advancedBy(2)]) << 16)
        let val3:UInt32 = (UInt32(slice[idx.advancedBy(1)]) << 8)
        let val4:UInt32 = UInt32(slice[idx])
        let val:UInt32 = val1 | val2 | val3 | val4
        result.append(val)
    }
    return result
}

func toUInt64Array(slice: ArraySlice<UInt8>) -> Array<UInt64> {
    var result = Array<UInt64>()
    result.reserveCapacity(32)
    for idx in slice.startIndex.stride(to: slice.endIndex, by: sizeof(UInt64)) {
        var val:UInt64 = 0
        val |= UInt64(slice[idx.advancedBy(7)]) << 56
        val |= UInt64(slice[idx.advancedBy(6)]) << 48
        val |= UInt64(slice[idx.advancedBy(5)]) << 40
        val |= UInt64(slice[idx.advancedBy(4)]) << 32
        val |= UInt64(slice[idx.advancedBy(3)]) << 24
        val |= UInt64(slice[idx.advancedBy(2)]) << 16
        val |= UInt64(slice[idx.advancedBy(1)]) << 8
        val |= UInt64(slice[idx.advancedBy(0)]) << 0
        result.append(val)
    }
    return result
}

func xor(a: [UInt8], _ b:[UInt8]) -> [UInt8] {
    var xored = [UInt8](count: min(a.count, b.count), repeatedValue: 0)
    for i in 0..<xored.count {
        xored[i] = a[i] ^ b[i]
    }
    return xored
}

public class Salsa20 {

    public enum Error: ErrorType {
        case MissingContext
        case LimitOfNonceExceeded
        case NotImplementedYet
    }

    static let blockSize = 64 // 512 / 8
    internal let stateSize = 16
    internal var rounds: UInt8
    internal var context:Context?
    private var keyStream: [UInt8]?
    private var index: Int = 0

    internal let SIGMA = "expand 32-byte k"
    internal let TAU = "expand 16-byte k"

    internal final class Context {
        var input:[UInt32] = [UInt32](count: 16, repeatedValue: 0)

        deinit {
            for i in 0..<input.count {
                input[i] = 0x00;
            }
        }
    }

    internal init?(rounds: UInt8) {
        self.rounds = rounds
    }

    public init?(key:[UInt8], iv:[UInt8], rounds: UInt8) {
        self.rounds = rounds
        if let c = contextSetup(iv: iv, key: key) {
            context = c
            keyStream = wordToByte(c.input)
        } else {
            return nil
        }
    }

    public convenience init?(key:[UInt8], iv:[UInt8]) {
        self.init(key: key, iv: iv, rounds: 20)
    }

    public func encrypt(bytes:[UInt8]) throws -> [UInt8] {
        guard context != nil else {
            throw Error.MissingContext
        }

        return try encryptBytes(bytes)
    }

    public func decrypt(bytes:[UInt8]) throws -> [UInt8] {
        return try encrypt(bytes)
    }

    internal func wordToByte(input:[UInt32] /* 64 */) -> [UInt8]? /* 16 */ {
        if (input.count != stateSize) {
            return nil
        }

        if (self.rounds % 2 != 0) {
            return nil
        }

        var x = input

        for _ in 0..<rounds/2 {
            x[ 4] ^= quarterround(x[0], x[12], 7)
            x[ 8] ^= quarterround(x[4], x[0], 9)
            x[12] ^= quarterround(x[8], x[4], 13)
            x[ 0] ^= quarterround(x[12], x[8], 18)
            x[ 9] ^= quarterround(x[5], x[1], 7)
            x[13] ^= quarterround(x[9], x[5], 9)
            x[ 1] ^= quarterround(x[13], x[9], 13)
            x[ 5] ^= quarterround(x[1], x[13], 18)
            x[14] ^= quarterround(x[10], x[6], 7)
            x[ 2] ^= quarterround(x[14], x[10], 9)
            x[ 6] ^= quarterround(x[2], x[14], 13)
            x[10] ^= quarterround(x[6], x[2], 18)
            x[ 3] ^= quarterround(x[15], x[11], 7)
            x[ 7] ^= quarterround(x[3], x[15], 9)
            x[11] ^= quarterround(x[7], x[3], 13)
            x[15] ^= quarterround(x[11], x[7], 18)

            x[ 1] ^= quarterround(x[0], x[3], 7)
            x[ 2] ^= quarterround(x[1], x[0], 9)
            x[ 3] ^= quarterround(x[2], x[1], 13)
            x[ 0] ^= quarterround(x[3], x[2], 18)
            x[ 6] ^= quarterround(x[5], x[4], 7)
            x[ 7] ^= quarterround(x[6], x[5], 9)
            x[ 4] ^= quarterround(x[7], x[6], 13)
            x[ 5] ^= quarterround(x[4], x[7], 18)
            x[11] ^= quarterround(x[10], x[9], 7)
            x[ 8] ^= quarterround(x[11], x[10], 9)
            x[ 9] ^= quarterround(x[8], x[11], 13)
            x[10] ^= quarterround(x[9], x[8], 18)
            x[12] ^= quarterround(x[15], x[14], 7)
            x[13] ^= quarterround(x[12], x[15], 9)
            x[14] ^= quarterround(x[13], x[12], 13)
            x[15] ^= quarterround(x[14], x[13], 18)
        }

        var output = [UInt8]()
        output.reserveCapacity(16)

        for i in 0..<16 {
            x[i] = x[i] &+ input[i]
            output.appendContentsOf(x[i].bytes().reverse())
        }

        return output
    }

    internal func contextSetup(iv  iv:[UInt8], key:[UInt8]) -> Context? {
        let ctx = Context()
        let kbits = key.count * 8

        if (kbits != 128 && kbits != 256) {
            return nil
        }

        // 1 - 4
        for i in 0..<4 {
            let start = i * 4
            ctx.input[i + 1] = wordNumber(key[start..<(start + 4)])
        }

        var addPos = 0;
        let constant: NSData;
        switch (kbits) {
        case 256:
            addPos += 16
            // sigma
            constant = SIGMA.dataUsingEncoding(NSUTF8StringEncoding)!
        default:
            // tau
            constant = TAU.dataUsingEncoding(NSUTF8StringEncoding)!
            break;
        }
        ctx.input[0]  = littleEndian(constant, range: 0..<4)
        ctx.input[5]  = littleEndian(constant, range: 4..<8)
        ctx.input[10] = littleEndian(constant, range: 8..<12)
        ctx.input[15] = littleEndian(constant, range: 12..<16)


        // 11 - 14
        for i in 0..<4 {
            let start = addPos + (i*4)

            let bytes = key[start..<(start + 4)]
            ctx.input[i + 11] = wordNumber(bytes)
        }

        // iv
        ctx.input[6] = wordNumber(iv[0..<4])
        ctx.input[7] = wordNumber(iv[4..<8])
        ctx.input[8] = 0
        ctx.input[9] = 0


        return ctx
    }

    internal func encryptBytes(message:[UInt8]) throws -> [UInt8] {

        guard let ctx = context else {
            throw Error.MissingContext
        }

        guard var keyStream = keyStream else {
            throw Error.MissingContext
        }

        var c:[UInt8] = [UInt8](count: message.count, repeatedValue: 0)

        let bytes = message.count

        while (true) {
            for i in 0..<bytes {
                c[i] = message[i] ^ keyStream[index]
                //reset index every 64 byte, regenerate keyStream
                index = (index + 1) & 0x3F
                if index == 0 {
                    ctx.input[8] = ctx.input[8] &+ 1
                    if (ctx.input[8] == 0) {
                        ctx.input[9] = ctx.input[9] &+ 1
                        /* stopping at 2^70 bytes per nonce is user's responsibility */
                        if (ctx.input[9] == 0) {
                            throw Error.LimitOfNonceExceeded
                        }
                    }
                    keyStream = wordToByte(ctx.input)!
                    self.keyStream = keyStream
                }
            }

            return c
        }
    }

    private final func quarterround(b:UInt32, _ c:UInt32, _ d:UInt32) -> UInt32 {
        return rotateLeft(b &+ c, d)
    }

    /**
     Reset keystream to start again
     */
    public func reset() {
        //reset index counter
        index = 0

        //reset position
        context?.input[8] = 0
        context?.input[9] = 0

        //reset stream key
        self.keyStream = wordToByte((context?.input)!)!
    }
}

// MARK: - Cipher

extension Salsa20: Cipher {
    public func cipherEncrypt(bytes:[UInt8]) throws -> [UInt8] {
        return try self.encrypt(bytes)
    }

    public func cipherDecrypt(bytes: [UInt8]) throws -> [UInt8] {
        return try self.decrypt(bytes)
    }
}

// MARK: Helpers

/// Change array to number. It's here because arrayOfBytes is too slow
internal func wordNumber(bytes:ArraySlice<UInt8>) -> UInt32 {
    var value:UInt32 = 0
    for i:UInt32 in 0..<4 {
        let j = bytes.startIndex + Int(i)
        value = value | UInt32(bytes[j]) << (8 * i)
    }

    return value
}

internal func littleEndian(data: NSData, range: Range<Int>) -> UInt32 {
    var val: UInt32 = 0
    data.getBytes(&val, range: NSRange(range))
    return UInt32.init(littleEndian: val);
}
