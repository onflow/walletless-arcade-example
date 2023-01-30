import ArcadePrize from "../../contracts/ArcadePrize.cdc"

/// Returns an array of MetadataViews.Display structs
///
pub fun main(prizeTypeAsInt: Int): UFix64 {
    let prizeType = ArcadePrize.PrizeType(rawValue: prizeTypeAsInt)
        ?? panic("Given prize type raw value is invalid!")
    return ArcadePrize.prizePrices[prizeType]
        ?? panic("Problem retrieving price for given prizeType!")
}
