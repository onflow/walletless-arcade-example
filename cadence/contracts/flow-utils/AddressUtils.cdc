import "StringUtils"

pub contract AddressUtils {

    priv fun withoutPrefix(_ input: String): String{
        var address=input

        //get rid of 0x
        if address.length>1 && address.utf8[1] == 120 {
            address = address.slice(from: 2, upTo: address.length)
        }

        //ensure even length
        if address.length%2==1{
            address="0".concat(address)
        }
        return address
    }
    
    priv fun parseUInt64(_ input: AnyStruct): UInt64?{
        var stringValue:String = ""

        if input.getType().isSubtype(of: Type<String>()){
            stringValue = input as! String
        }
        else if input.getType().isSubtype(of: Type<Int>()){
            stringValue = (input as! Int).toString()
        }
        else if input.getType().isSubtype(of: Type<Address>()){
            stringValue = (input as! Address).toString()
        }
        else if input.getType().isSubtype(of: Type<Type>()){
            stringValue =  StringUtils.split((input as! Type).identifier, ".")[1]
        }

        var address=self.withoutPrefix(stringValue)
        var r:UInt64 = 0
        var bytes = address.decodeHex()
        while bytes.length>0{
            r = r  + (UInt64(bytes.removeFirst()) << UInt64(bytes.length * 8 ))
        }
        return r

    }

    pub fun parseAddress(_ input: AnyStruct): Address?{
        if let parsed = self.parseUInt64(input){
            return Address(parsed)
        }
        return nil
    }

    pub fun isValidAddress(_ input: AnyStruct, forNetwork: String) : Bool{
        
        if let address = self.parseUInt64(input) {
            
            var codeWords: {String:UInt64} = {
                "MAINNET" : 0,
                "TESTNET" : 0x6834ba37b3980209,
                "EMULATOR": 0x1cb159857af02018
            }

            var parityCheckMatrixColumns: [UInt64] = [
                0x00001, 0x00002, 0x00004, 0x00008, 0x00010, 0x00020, 0x00040, 0x00080,
                0x00100, 0x00200, 0x00400, 0x00800, 0x01000, 0x02000, 0x04000, 0x08000,
                0x10000, 0x20000, 0x40000, 0x7328d, 0x6689a, 0x6112f, 0x6084b, 0x433fd,
                0x42aab, 0x41951, 0x233ce, 0x22a81, 0x21948, 0x1ef60, 0x1deca, 0x1c639,
                0x1bdd8, 0x1a535, 0x194ac, 0x18c46, 0x1632b, 0x1529b, 0x14a43, 0x13184,
                0x12942, 0x118c1, 0x0f812, 0x0e027, 0x0d00e, 0x0c83c, 0x0b01d, 0x0a831,
                0x0982b, 0x07034, 0x0682a, 0x05819, 0x03807, 0x007d2, 0x00727, 0x0068e,
                0x0067c, 0x0059d, 0x004eb, 0x003b4, 0x0036a, 0x002d9, 0x001c7, 0x0003f
            ]

            var parity: UInt64 = 0
            var codeWord: UInt64 = codeWords[forNetwork]! //0 for mainnet
            codeWord = codeWord ^ address

            if codeWord==0{
                return false
            }

            for column in parityCheckMatrixColumns{
                if codeWord & 1 == 1{
                    parity = parity ^ column
                }
                codeWord = codeWord >> 1
            }

            return parity==0 && codeWord==0

        }
        return false
    }

    pub fun getNetworkFromAddress(_ input: AnyStruct): String? {
        for network in ["MAINNET", "TESTNET", "EMULATOR"]{
            if self.isValidAddress(input, forNetwork: network){
                return network
            }
        }
        return nil
    }

    pub fun currentNetwork(): String{
        return self.getNetworkFromAddress(self.account.address)!
    }

}
 