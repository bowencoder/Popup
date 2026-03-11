# MBPopup 弹窗管理模块

本模块是一个面向 iOS 的弹窗调度中台，目标是把「弹窗展示行为」和「业务内容」解耦。  
业务只关心“我要展示什么”，调度层负责“何时展示、是否可叠加、冲突如何处理”。

---

## 1. 能力边界

### 已覆盖能力

- 队列调度：优先级 + 同优先级 FIFO
- 冲突控制：互斥组（`none/reject/replace/suspend`）
- 叠加控制：`coverRule` 黑白名单
- 双任务形态：`UIView` / `UIViewController`
- 生命周期埋点：展示、关闭、泄漏监控
- 主线程安全：统一通过 `MBPopupExecuteOnMainQueue` 入场

### 非目标（当前不负责）

- 弹窗内容渲染（由业务视图/VC自己实现）
- 跨页面容器管理（`container` 由外部传入）
- 持久化策略配置（当前不内置配置中心读取）

---

## 2. 模块结构

```text
Manager/
  MBPopupManager.swift            // 调度核心（show/dismiss/规则判定）
  MBPopupQueue.swift              // 等待队列（优先级排序）
  MBPopupDisplayManager.swift     // 展示中列表 + suspend映射
  MBPopupTaskProtocol.swift       // 协议族定义（标识/策略/展示/状态）
  MBPopupFixedTypes.swift         // 固定类型（优先级、状态、策略、动画）
  MBPopupDynamicTypes.swift       // 动态类型（scene、mutex group）
  Task/
    MBPopupTask.swift
    MBPopupBaseViewTask.swift
    MBPopupViewTask.swift
    MBPopupViewControllerTask.swift
    MBPopupBlockTask.swift
    MBPopupPlaceholderTask.swift
  Tools/
    MBPopupAnimator.swift
    MBPopupLayout.swift
    MBPopupAPMTracker.swift
    MBPopupUtils.swift
```

---

## 3. 快速接入

### 3.1 初始化 manager

```swift
final class LiveViewController: UIViewController {
    private lazy var popupManager = MBPopupManager(container: self)
}
```

### 3.2 展示一个 View 弹窗

```swift
let task = MBPopupViewTask(
    popupId: "coupon_001",
    scene: .coupon,
    contentView: couponView
)
task.priority = .normal
task.mutexGroup = MBPopupMutexGroup.lottery
task.mutexPolicy = .suspend

popupManager.show(task)
```

### 3.3 主动关闭

```swift
popupManager.dismiss(popupId: "coupon_001")
```

或在业务内调用注入的 `close`：

```swift
task.close?()
```

---

## 4. 核心流程

### 4.1 show 流程（`MBPopupManager.show`）

1. 去重（展示中 / 队列中 / suspend中）
2. 注入 `close` 回调
3. 执行“场景兜底绕过队列”判断（`MBPopupSceneConfigEnabled`）
4. 若当前无展示弹窗，直接展示
5. 命中互斥组则按 `mutexPolicy` 决策
6. 未命中互斥组则走黑白名单 + 优先级判定
7. 允许叠加则直接 show，否则 enqueue

### 4.2 dismiss 流程（`MBPopupManager.dismiss`）

1. 优先从展示中关闭
2. 否则从队列中移除
3. 否则从 suspend 映射中移除
4. 若存在被该弹窗挂起的任务则 `resume`
5. 否则推进队列（`processNextPopup`）

---

## 5. 规则矩阵（简化）

| 条件 | 结果 |
|---|---|
| `priority == .click` | 直接叠加展示 |
| `priority == .force` 且不在黑名单 | 直接叠加展示 |
| 普通优先级且命中顶层白名单 | 直接展示 |
| 命中黑名单 | 入队等待 |
| 顶层无 `coverRule` + 普通优先级 | 入队等待 |

> 注：最终以 `MBPopupManager` 当前代码为准。

---

## 6. 配置与兜底

`MBPopupSceneConfigEnabled(scene:)` 用于“兜底绕过队列”。  
建议业务按需实现为：

- 全局开关（全部场景绕过）
- 场景开关（指定 scene 绕过）

当前 `MBPopupUtils.swift` 里的实现是示例形态，建议按业务真实配置源接入（远端配置、本地开关或注入字典）。

---

## 7. 状态定义

- `waiting`：队列中等待
- `showing`：正在展示
- `suspended`：被互斥策略暂停
- `closed`：已关闭

时间字段：

- `entryTime`：入队时刻
- `showTime`：展示时刻
- `dismissTime`：关闭时刻
- `waitDuration`：等待时长
- `showDuration`：展示时长

---

## 8. 常见问题排查

### Q1: 自动弹“卡住出不来”

优先检查：

- 目标弹窗是否一直处于 `showing` 但未回调 dismiss
- 队首是否被黑名单拦截
- 是否错误复用 `popupId` 导致被去重
- `container` 是否已释放（`performShow` 会失败）

建议加的兜底：

- 队列超时淘汰（等待超过阈值自动移除）
- 空转 watchdog（长时间无事件推进时强制 dismiss 最老展示弹窗）

### Q2: 弹窗被“吞”了

- 先看日志：`show failed, container is nil`
- 检查容器生命周期是否早于 manager
- 检查 `coverRule` 是否把场景挡住

---

## 9. 开发规范（建议）

- `popupId` 必须稳定且唯一
- 所有 UI 逻辑必须在主线程
- `dismiss` completion 不做重活，避免阻塞队列
- 新增场景时同步补测试用例（黑白名单 + 互斥组 + 优先级）

---

## 10. 变更建议清单（后续可做）

- 增加 `watchdog`（长时间无处理事件自动自愈）
- 增加 `displayManager.allShowingPopups()` 用于治理策略
- 补统一配置接口（替代工具函数里的示例逻辑）
- 增加单元测试：去重、互斥、suspend恢复、队列推进

