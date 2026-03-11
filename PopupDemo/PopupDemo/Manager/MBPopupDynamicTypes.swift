//
//  MBPopupDynamicTypes.swift
//  Popup
//
//  Created by bowen on 2026/01/29.
//  Copyright © 2025 bowen. All rights reserved.
//
//  本文件定义弹窗管控系统的动态类型（业务可扩展）
//

import UIKit

/// 弹窗场景
/// 用于弹窗黑白名单、场景区分等
@objc(MBPopupScene)
public enum MBPopupScene: Int {
    case unknown = 0            // 未知
    case coupon = 1            // 优惠券
    case shoppingRedPacket = 2 // 购物红包
    case shoppingBag = 3       // 购物袋

    /// 将枚举值转换为字符串
    /// - Returns: 场景标识字符串
    public func stringValue() -> String {
        switch self {
        case .unknown:
            return "unknown"
        case .coupon:
            return "coupon"
        case .shoppingRedPacket:
            return "shoppingRedPacket"
        case .shoppingBag:
            return "shoppingBag"
        }
    }
}

// MARK: - Mutex Group Constants

/// 弹窗互斥组常量
/// 同组内仅展示一个弹窗，冲突时按 mutexPolicy 策略处理（替换/暂停/拒绝）
@objc(MBPopupMutexGroup)
@objcMembers
public class MBPopupMutexGroup: NSObject {
    /// 抽奖相关弹窗互斥组
    public static let lottery = "lottery"
}
