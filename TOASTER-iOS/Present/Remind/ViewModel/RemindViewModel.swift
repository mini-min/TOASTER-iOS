//
//  RemindViewModel.swift
//  TOASTER-iOS
//
//  Created by 김다예 on 1/11/24.
//

import Foundation
import UserNotifications

final class RemindViewModel {
    
    // MARK: - Properties

    typealias DataChangeAction = (RemindViewType) -> Void
    private var dataChangeAction: DataChangeAction?
    
    typealias NormalChangeAction = () -> Void
    private var bottomSheetAction: NormalChangeAction?
    
    private let userDefault = UserDefaults.standard
    
    /// RemindViewType을 저장하기 위한 프로퍼티
    private var remindViewType: RemindViewType = .deviceOnAppOnNoneData {
        didSet {
            dataChangeAction?(remindViewType)
        }
    }
    
    private var deviceAlarmSetting: Bool? {
        didSet {
            
        }
    }
    private var appAlarmSetting: Bool = true {
        didSet {
            
        }
    }
    
    // MARK: - Data

    var timerData: RemindModel = RemindModel.fetchDummyModel() {
        didSet {
            if timerData.completeTimerModelList.count == 0 && 
                timerData.waitTimerModelList.count == 0 {
                remindViewType = .deviceOnAppOnNoneData
            } else {
                remindViewType = .deviceOnAppOnExistData
            }
        }
    }
}

// MARK: - extension

extension RemindViewModel {
    func setupDataChangeAction(changeAction: @escaping DataChangeAction,
                               normalAction: @escaping NormalChangeAction) {
        dataChangeAction = changeAction
        bottomSheetAction = normalAction
    }
    
    func fetchAlarmCheck() {
        UNUserNotificationCenter.current().getNotificationSettings { permission in
            switch permission.authorizationStatus {
            case .notDetermined:
                self.remindViewType = .deviceOnAppOnNoneData
                self.bottomSheetAction?()
            case .denied:
                self.deviceAlarmSetting = false
            case .authorized:
                self.deviceAlarmSetting = true
            default:
                print("unknown Error")
            }
        }
        if let isAppOn = userDefault.object(forKey: "isAppAlarmOn") as? Bool {
            appAlarmSetting = isAppOn
        }
    }
}

private extension RemindViewModel {
    func setupAlarm(forDeviceAlarm: Bool?) {
        if let deviceAlarm = forDeviceAlarm {
            if forDeviceAlarm == false {    // device 알람이 꺼져있을 때
                if appAlarmSetting == false {     // device 알람이 꺼져있고, 앱 알람도 꺼져있을 때
                    remindViewType = .deviceOffAppOff
                } else {                          // device 알람이 꺼져있고, 앱 알람이 켜져있을 때
                    remindViewType = .deviceOffAppOn
                }
            } else {                        // device 알람이 켜져있을 때
                if appAlarmSetting == false {     // device 알람이 켜져있고, 앱 알람이 꺼져있을 때
                    remindViewType = .deviceOnAppOff
                } else {
                    // TODO: - API 호출
                }
            }
        }
    }
}
