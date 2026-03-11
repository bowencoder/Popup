//
//  MBPopupAPMTracker.swift
//  Popup
//
//  Created by bowen on 2026/01/29.
//  Copyright © 2025 bowen. All rights reserved.
//

import Foundation

/// 弹窗 APM 监控追踪器
/// 负责弹窗相关的 APM 数据上报
@objc(MBPopupAPMTracker)
@objcMembers
public class MBPopupAPMTracker: NSObject {
    
    // MARK: - Public Methods
    
    /// 监控弹窗关闭
    /// - Parameter popup: 关闭的弹窗
    public static func trackPopupDismiss(popup: MBPopupTaskProtocol) {
        
    }
    
    /// 监控弹窗泄漏
    /// - Parameters:
    ///   - showingCount: 当前显示的弹窗数量
    ///   - queueCount: 队列中的弹窗数量
    ///   - displayInfo: 显示列表的调试信息
    ///   - queueInfo: 队列的调试信息
    public static func trackPopupLeak(
        showingCount: Int,
        queueCount: Int,
        displayInfo: [String: Any],
        queueInfo: [String: Any]
    ) {
        
    }

}
