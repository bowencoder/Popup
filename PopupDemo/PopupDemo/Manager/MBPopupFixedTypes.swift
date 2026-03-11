//
//  MBPopupFixedTypes.swift
//  Popup
//
//  Created by bowen on 2026/01/29.
//  Copyright © 2025 bowen. All rights reserved.
//
//  本文件定义弹窗管控系统的固定类型
//

import UIKit

/// 弹窗优先级
@objc(MBPopupPriority)
public enum MBPopupPriority: Int {
    case low = 0        // 低优先级（数值越小优先级越低，同优先级 FIFO）
    case normal = 1     // 普通优先级（建议）
    case high = 2       // 高优先级（数值越大优先级越高，同优先级 FIFO）
    case force = 3      // 强制展示（叠加显示，受黑名单约束）
    case click = 999    // 点击触发（最高优先级，直接显示）
}

/// 弹窗状态
@objc(MBPopupState)
public enum MBPopupState: Int {
    case waiting = 0    // 等待中
    case showing = 1    // 展示中
    case suspended = 2  // 已暂停（suspend 策略下被新弹窗临时隐藏，可恢复）
    case closed = 3     // 已关闭
}

/// 互斥组冲突时的处理策略（同组已有展示时生效）
@objc(MBPopupMutexPolicy)
public enum MBPopupMutexPolicy: Int {
    /// 不参与互斥，走优先级策略（默认值）
    case none = 0
    /// 替换同组弹窗（关闭被替换者）
    case replace = 1
    /// 暂停/恢复（暂停被替换者，自己消失后恢复）
    case suspend = 2
    /// 拒绝展示
    case reject = 3
}

/// 弹窗动画类型
@objc(MBPopupAnimationType)
public enum MBPopupAnimationType: Int {
    case none = 0       // 无动画（默认，充满直播间）
    case fade = 1       // 渐隐渐现（充满直播间）
    case bottomSheet = 2 // 底部抽屉式（从底部弹起，关闭时向下滑出）
    case topSheet = 3   // 顶部抽屉式（从顶部滑入，关闭时向上滑出）
    case centerSheet = 4 // 居中弹出（缩放 + 淡入，关闭时缩放 + 淡出）
}

/// 遮盖规则（黑白名单，基于 scene）
/// 
/// ## 作用
/// 本弹窗为顶层时，通过黑白名单控制后续弹窗能否叠加在本弹窗之上
///
/// ## 规则
/// - **黑名单优先**：黑名单中的场景禁止叠加（无视优先级，force 也会被拦截）
/// - **白名单次之**：白名单中的场景允许叠加（未配置白名单时，force 可叠加，普通优先级入队）
/// - **未配置时**：允许 force 叠加，普通优先级入队等待
///
@objc(MBPopupCoverRule)
@objcMembers
public class MBPopupCoverRule: NSObject {
    
    /// 白名单：允许叠在本弹窗之上的 scene 集合（非空时仅白名单内可叠加）
    private var whitelistScenes: Set<MBPopupScene>?
    
    /// 黑名单：不允许叠在本弹窗之上的 scene 集合（黑名单优先于白名单）
    private var blacklistScenes: Set<MBPopupScene>?
    
    // MARK: - Initialization
    
    /// 初始化方法（Swift 类型安全，推荐使用）
    /// - Parameters:
    ///   - whitelistScenes: 白名单场景枚举集合
    ///   - blacklistScenes: 黑名单场景枚举集合
    public init(whitelistScenes: Set<MBPopupScene>? = nil, blacklistScenes: Set<MBPopupScene>? = nil) {
        self.whitelistScenes = whitelistScenes
        self.blacklistScenes = blacklistScenes
        super.init()
    }
    
    /// Objective-C 兼容初始化方法
    /// - Parameters:
    ///   - whitelist: 白名单场景集合，元素类型为 NSNumber（存储 MBPopupScene 的 rawValue）
    ///   - blacklist: 黑名单场景集合，元素类型为 NSNumber（存储 MBPopupScene 的 rawValue）
    public convenience init(whitelist: NSArray?, blacklist: NSArray?) {
        var whitelistScenes: Set<MBPopupScene>?
        var blacklistScenes: Set<MBPopupScene>?
        
        if let whitelistArray = whitelist {
            whitelistScenes = Set(whitelistArray.compactMap { ($0 as? NSNumber)?.intValue }.compactMap { MBPopupScene(rawValue: $0) })
        }
        
        if let blacklistArray = blacklist {
            blacklistScenes = Set(blacklistArray.compactMap { ($0 as? NSNumber)?.intValue }.compactMap { MBPopupScene(rawValue: $0) })
        }
        
        self.init(whitelistScenes: whitelistScenes, blacklistScenes: blacklistScenes)
    }
    
    // MARK: - Check Methods
    
    /// 检查场景是否在白名单中
    public func isWhitelisted(_ scene: MBPopupScene) -> Bool {
        guard let whitelist = whitelistScenes else { return false }
        return whitelist.contains(scene)
    }
    
    /// 检查场景是否在黑名单中
    public func isBlacklisted(_ scene: MBPopupScene) -> Bool {
        guard let blacklist = blacklistScenes else { return false }
        return blacklist.contains(scene)
    }
}
