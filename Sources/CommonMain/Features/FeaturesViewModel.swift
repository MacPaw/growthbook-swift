import Foundation

/// Interface for Feature API Completion Events
protocol FeaturesFlowDelegate: AnyObject {
//    func featuresFetchedSuccessfully(features: Features, isRemote: Bool)

    func featuresAPIModelSuccessfully(model: DecryptedFeaturesDataModel, fetchType: GrowthBookFeaturesFetchResult.FetchType)

    func featuresFetchFailed(error: Error, fetchType: GrowthBookFeaturesFetchResult.FetchType)
//
//    func savedGroupsFetchFailed(error: Error, isRemote: Bool)
//
//    func savedGroupsFetchedSuccessfully(savedGroups: JSON, isRemote: Bool)
}


/// View Model for Features
final class FeaturesViewModel {
    private class MutableState {
        weak var delegate: FeaturesFlowDelegate?

        init(delegate: FeaturesFlowDelegate? = nil) {
            self.delegate = delegate
        }
    }

    private let mutableState: Protected<MutableState>

    var delegate: FeaturesFlowDelegate? {
        get { mutableState.read(\.delegate) }
        set { mutableState.write(\.delegate, newValue) }
    }

    private let featuresCache: FeaturesCacheInterface
    private let savedGroupsCache: SavedGroupsCacheInterface

    private let featuresModelProvider: FeaturesModelProviderInterface?
    private let featuresModelFetcher: FeaturesModelFetcherInterface

    init(
        delegate: FeaturesFlowDelegate,
        featuresCache: FeaturesCacheInterface,
        savedGroupsCache: SavedGroupsCacheInterface,
        featuresModelProvider: FeaturesModelProviderInterface?,
        featuresModelFetcher: FeaturesModelFetcherInterface
    )
    {
        self.mutableState = .init(.init(delegate: delegate))
        self.featuresCache = featuresCache
        self.savedGroupsCache = savedGroupsCache
        self.featuresModelProvider = featuresModelProvider
        self.featuresModelFetcher = featuresModelFetcher

        self.initialize()
    }

    deinit {
        featuresModelProvider?.unsubscribeFromFeaturesUpdates()
    }

    private func initialize() {
        fetchCachedFeatures()
        fetchRemoteFeatures()
    }

    private func fetchCachedFeatures() {
        // Check for cache data
        // TODO: Delegate if needed
//        do {
//            let features = try featuresCache.features() ?? [:]
////            delegate?.featuresFetchedSuccessfully(features: features, isRemote: false)
//        } catch {
////            delegate?.featuresFetchFailed(error: error, isRemote: false)
//        }
    }

    private func notifyDelegateAboutFetchResult(
        _ result: Result<DecryptedFeaturesDataModel, any Error>,
        fetchType: GrowthBookFeaturesFetchResult.FetchType
    )
    {
        guard let delegate else { return }

        switch result {
        case let .success(model):
            delegate.featuresAPIModelSuccessfully(model: model, fetchType: fetchType)
        case let .failure(error):
            delegate.featuresFetchFailed(error: error, fetchType: fetchType)
        }
    }

    func fetchFeaturesOnce() {
        featuresModelFetcher.fetchFeatures { [weak self] (result: Result<FeaturesModelResponse, any Error>) in
            guard let self else { return }

            self.notifyDelegateAboutFetchResult(result.map(\.decryptedFeaturesDataModel), fetchType: .remoteForced)
        }
    }

    private func fetchRemoteFeatures() {
        featuresModelFetcher.fetchFeatures { [weak self] (result: Result<FeaturesModelResponse, any Error>) in
            guard let self else { return }

            self.notifyDelegateAboutFetchResult(result.map(\.decryptedFeaturesDataModel), fetchType: .initialRemote)

            self.subscribeToFeaturesUpdates()
        }
    }

    private func subscribeToFeaturesUpdates() {
        featuresModelProvider?.delegate = self
        featuresModelProvider?.subscribeToFeaturesUpdates()
    }
}

extension FeaturesViewModel: FeaturesModelProviderDelegate {
    func featuresProvider(_ provider: any FeaturesModelProviderInterface, didUpdate featuresModel: DecryptedFeaturesDataModel) {
        self.notifyDelegateAboutFetchResult(.success(featuresModel), fetchType: .remoteRefresh)
    }

    func featuresProvider(_ provider: any FeaturesModelProviderInterface, didFailToUpdate error: any Error) {
        self.notifyDelegateAboutFetchResult(.failure(error), fetchType: .remoteRefresh)
    }
}
