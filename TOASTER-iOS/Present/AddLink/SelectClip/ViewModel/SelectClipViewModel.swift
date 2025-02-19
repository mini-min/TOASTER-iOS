//
//  SelectClipViewModel.swift
//  TOASTER-iOS
//
//  Created by Gahyun Kim on 2024/02/27.
//

import Combine
import UIKit

final class SelectClipViewModel: ViewModelType {
    
    private var cancelBag = CancelBag()
    var selectedClip: [RemindClipModel] = []
    
    // MARK: - Input State
    
    struct Input {
        let requestClipList: Driver<Void>
        let clipNameChanged: Driver<String>
        let addClipButtonTapped: Driver<String>
        let completeButtonTapped: Driver<(String, Int?)>
    }
    
    // MARK: - Output State
    
    struct Output {
        let needToReload = PassthroughSubject<Void, Never>()
        let duplicateClipName = PassthroughSubject<Bool, Never>()
        let addClipResult = PassthroughSubject<Bool, Never>()
        let saveLinkResult = PassthroughSubject<Bool, Never>()
    }
    
    // MARK: - Method
    
    func transform(_ input: Input, cancelBag: CancelBag) -> Output {
        let output = Output()
        
        input.requestClipList
            .networkFlatMap(self) { context, _ in
                context.fetchClipData()
            }
            .sink { [weak self] clipDataList in
                self?.selectedClip = clipDataList
                output.needToReload.send()
            }.store(in: cancelBag)
        
        input.clipNameChanged
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .removeDuplicates()
            .networkFlatMap(self) { context, clipTitle in
                context.getCheckCategoryAPI(categoryTitle: clipTitle)
            }
            .sink { isDuplicate in
                output.duplicateClipName.send(isDuplicate)
            }.store(in: cancelBag)
        
        input.addClipButtonTapped
            .networkFlatMap(self) { context, clipTitle in
                context.postAddCategoryAPI(requestBody: clipTitle)
            }
            .sink { isSuccess in
                output.addClipResult.send(isSuccess)
                if isSuccess {
                    output.needToReload.send()
                }
            }.store(in: cancelBag)
        
        input.completeButtonTapped
            .networkFlatMap(self) { context, body in
                context.postSaveLink(url: body.0, category: body.1)
            }
            .sink { result in
                output.saveLinkResult.send(result)
            }.store(in: cancelBag)
        
        return output
    }
}

// MARK: - Network

private extension SelectClipViewModel {
    func postSaveLink(url: String, category: Int?) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            let request = PostSaveLinkRequestDTO(linkUrl: url, categoryId: category)
            NetworkService.shared.toastService.postSaveLink(requestBody: request) { result in
                switch result {
                case .success:
                    promise(.success(true))
                case .badRequest, .serverErr:
                    promise(.success(false))
                case .networkFail, .unAuthorized, .notFound:
                    promise(.failure(NetworkResult<Error>.unAuthorized))
                default:
                    return
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func fetchClipData() -> AnyPublisher<[RemindClipModel], Error> {
        return Future<[RemindClipModel], Error> { promise in
            NetworkService.shared.clipService.getAllCategory { result in
                switch result {
                case .success(let response):
                    var clipDataList: [RemindClipModel] = [
                        RemindClipModel(
                            id: nil,
                            title: "전체 클립",
                            clipCount: response?.data.toastNumberInEntire ?? 0
                        )
                    ]
                    response?.data.categories.forEach {
                        let clipData = RemindClipModel(
                            id: $0.categoryId,
                            title: $0.categoryTitle,
                            clipCount: $0.toastNum
                        )
                        clipDataList.append(clipData)
                    }
                    promise(.success(clipDataList))
                case .networkFail, .unAuthorized, .notFound:
                    promise(.failure(NetworkResult<Error>.unAuthorized))
                default:
                    return
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func getCheckCategoryAPI(categoryTitle: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            NetworkService.shared.clipService.getCheckCategory(categoryTitle: categoryTitle) { result in
                switch result {
                case .success(let response):
                    if let data = response?.data.isDupicated, categoryTitle.count < 16 {
                        promise(.success(data))
                    }
                case .unAuthorized, .networkFail, .notFound:
                    promise(.failure(NetworkResult<Error>.unAuthorized))
                default:
                    return
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func postAddCategoryAPI(requestBody: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            NetworkService.shared.clipService.postAddCategory(requestBody: PostAddCategoryRequestDTO(categoryTitle: requestBody)) { result in
                switch result {
                case .success:
                    promise(.success(true))
                case .unAuthorized, .networkFail, .notFound:
                    promise(.failure(NetworkResult<Error>.unAuthorized))
                default:
                    return
                }
            }
        }.eraseToAnyPublisher()
    }
}
