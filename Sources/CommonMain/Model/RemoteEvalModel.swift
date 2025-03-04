import Foundation

public struct RemoteEvalParams: Encodable, Decodable {
    let attributes: JSON?
    let forcedFeatures: JSON?
    let forcedVariations: JSON?
}
