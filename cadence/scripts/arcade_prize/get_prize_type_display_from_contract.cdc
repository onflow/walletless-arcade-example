import "MetadataViews"
import "ArcadePrize"

/// Returns an array of MetadataViews.Display structs
///
pub fun main(prizeTypeAsInt: Int): MetadataViews.Display {
    let prizeType = ArcadePrize.PrizeType(rawValue: prizeTypeAsInt)
        ?? panic("Given prize type raw value is invalid!")
    return ArcadePrize.getPrizeTypeDisplayView(prizeType: prizeType)
        ?? panic("Problem retrieving Display view for given prizeType!")
}
