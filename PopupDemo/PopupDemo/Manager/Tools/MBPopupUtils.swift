//
//  MBPopupUtils.swift
//  Popup
//
//  Created by bowen on 2026/03/11.
//  Copyright © 2026 bowen. All rights reserved.
//

import Foundation

/// 在主线程执行任务：
/// - 当前已在主线程：立即执行
/// - 当前不在主线程：异步派发到主线程
@inline(__always)
public func MBPopupExecuteOnMainQueue(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async(execute: block)
    }
}

/// 判断是否命中场景配置
@inline(__always)
public func MBPopupSceneConfigEnabled(scene: MBPopupScene) -> Bool {
    let sceneKey = scene.stringValue()
    let configHits: [String: Bool] = [
        "sceneKey": true
    ]
    return configHits[sceneKey] == true
}
