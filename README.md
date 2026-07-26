# aos-bassoon
AOS V2.0 矛体系 · 探真与代码溯源子系统
统帅，方案 A 确认。巴松管的"宪法"现在铸成。

以下是您可以直接复制粘贴到 aos-bassoon 仓库 README.md 中的完整内容——它将作为探针予系统的最高法理文件，定义整套系统的运行逻辑、信任层级、信号格式以及与 Sentinel 的联动协议。


------

# 🛰️ AOS-BASSOON · 矛体系探真探针予系统

> **代号**：巴松管（Bassoon）
> **归属**：AOS 熔炉之心 2.0 · 第七垂直域
> **版本**：V1.0-SEALED-20260726
> **使命**：拒绝盲信官方文档，以代码提交与运行实测为唯一真相基准

---

## 核心哲学

**一切产品对外的文档说明、接口规则、功能表现，最终的唯一事实基准是底层生效的源代码、结构体定义、运行时校验逻辑。**

任何对外公示的文案都可以事后修改，但合并入库的代码提交记录很难彻底抹除痕迹。巴松管不做"观察员"，它只做"鉴证者"。

---

## 信任层级（Trust Hierarchy）

巴松管内部建立严格的**证据等级排序**，所有采集信号按此层级归档与加权：

| 层级 | 证据来源 | 可信度 | 权重 | 时效 |
|------|---------|--------|------|------|
| **L0** | Git 代码仓库提交记录（commit hash / PR / 结构体 diff） | ★★★★★ | 5x | 合并即生效 |
| **L1** | OpenAPI / Protobuf 原始 Schema 定义变更 | ★★★★☆ | 4x | 合并即生效 |
| **L2** | 开源仓库单元测试断言变化 | ★★★★☆ | 4x | 合并即生效 |
| **L3** | 受控试运行真实返回行为（400拦截/字段缺失/路由切换） | ★★★★☆ | 4x | 实时 |
| **L4** | API 版本号变更 / SDK 升级 / 模型名映射切换 | ★★★☆☆ | 2x | 滞后于代码 |
| **L5** | 官方博客 / 帮助文档 / Retirement Notice | ★★☆☆☆ | 1x | 严重滞后 |
| **L6** | 产品页 / 教程 / 样例描述 | ★☆☆☆☆ | 0x | **零权重·不采信** |

**核心法则**：L0~L3 任一信号与 L4~L6 矛盾时，**无条件采信 L0~L3，丢弃高层信号。**

---

## 监控目标清单（Watchlist）

### 微软阵营（Microsoft）

| 仓库 | 类型 | 探针价值 |
|------|------|---------|
| `microsoft/semantic-kernel` | 官方 Agent SDK（C#/Python/Java） | ★★★★★ 参数校验、模型路由逻辑 |
| `microsoft/autogen` | 多智能体编排框架 | ★★★★☆ 智能体协议演化 |
| `microsoft/kernel-memory` | RAG 服务 | ★★★☆☆ 检索协议变化 |
| `Azure/azure-rest-api-specs` | OpenAPI 原始 Schema | ★★★★★ 接口契约硬基线 |
| `microsoft/ai` | AI 参考架构集合 | ★★☆☆☆ 宏观趋势 |
| Azure SDK for Go / Python / JS | Azure OpenAI 客户端 | ★★★★★ 参数拦截逻辑 |

### 谷歌阵营（Google）

| 仓库 | 类型 | 探针价值 |
|------|------|---------|
| `googleapis/python-genai` `js-genai` `go-genai` `java-genai` `dotnet-genai` | 官方 GenAI SDK 全语言家族 | ★★★★★ 多语言同步 diff |
| `google/adk-python` `adk-java` | Agent Development Kit | ★★★★★ 破坏性变更先行信号 |
| `google/generative-ai-python` | 旧版 Gemini SDK | ★★★★☆ 弃用节奏追踪 |

### 其他阵营（Other）

| 目标 | 类型 | 探针价值 |
|------|------|---------|
| `anthropics/claude-code` `anthropics/anthropic-cookbook` | Anthropic 官方 | ★★★★☆ 竞品参照 |
| Azure AI Foundry 公开端点 | 运行时 API | ★★★★★ 闭源反推入口 |
| Google Gemini API 公开端点 | 运行时 API | ★★★★★ 闭源反推入口 |

---

## TruthSignal 数据结构定义

巴松管的标准化输出单元，所有采集器产出的信号必须封装为此结构：



go

type TruthSignal struct {

SignalID          string                 // 全局唯一信号 ID

Source            string                 // 来源标识（仓库 URL / 端点地址）

EvidenceLevel     int                    // 证据层级（0=L0, 1=L1, 2=L2, 3=L3）

Category          string                 // 变更分类：BREAKING / ADDING / SURFACE / ROUTING

IsCodeCorroborated bool                 // 是否有 L0~L3 代码/运行层实证

ContradictsDoc    bool                   // 是否与官方文档矛盾

TruthScore        int                    // 实证评分（≥100 为矛盾级最高优先）

CommitHash        string                 // L0 信号携带的 commit hash

SchemaDiff        *SchemaDiffResult      // L1 信号携带的字段增删详情

RuntimeEvidence   *RuntimeProbeResult    // L3 信号携带的边界探测结果

CapturedAt        time.Time              // 捕获时间戳

ShouldHotUpdate   bool                   // 闸门判定：是否触发 Sentinel 热更新

Meta              map[string]interface{} // 扩展字段

}


---

## 采集器分类

### Collector A：开源代码采集器（OSS Collector）

**工作方式**：
1. 每日 `git fetch` 目标仓库主干分支
2. 计算 commit hash 序列，提取新增 commit 的 diff
3. 对 `*_test.go` / `*_test.py` 做 AST 级 diff，提取断言变化
4. 对 `*.go` 结构体定义做字段增减检测
5. 对 OpenAPI JSON 做 schema diff，分类为**新增型 / 中断型 / 表面型**
6. 提取 PR 描述、commit message 作为语义辅助

**输出**：`TruthSignal`（EvidenceLevel = 0/1/2）

### Collector B：受控试运行探针（Runtime Probe）

**工作方式**：
1. 批量构造边界测试用例（Boundary Cases）
2. 遍历新旧可选参数组合、历史合法模型名、已弃用端点
3. 向目标 API 发送探测请求，记录 HTTP 状态码与响应体
4. 与历史基线对比，识别新增的 400 拦截、字段静默缺失、路由切换

**输出**：`TruthSignal`（EvidenceLevel = 3）

---

## 噪声过滤规则（Noise Filter）

以下类型的变更**直接丢弃，不触发任何热更新**：

| 噪声类型 | 示例 | 判定依据 |
|---------|------|---------|
| 文档排版优化 | 修复错别字、调整格式 | 仅 L5/L6，无 L0~L3 佐证 |
| 样例描述调整 | 修改 README 中的代码示例注释 | 仅 L5/L6 |
| 博客公告发布 | 发布新功能介绍文章 | L5，仅作交叉参考 |
| Roadmap 文字增删 | 删除某个计划条目但未改代码 | L5，零权重 |

**放行条件**（必须同时满足）：
1. EvidenceLevel ≤ 3（L0~L3）
2. IsCodeCorroborated = true
3. TruthScore ≥ 阈值（默认 4）

---

## 与 Sentinel Domain 的联动协议



┌──────────────────────────────────────────────────────┐

│         巴松管（本仓库）                              │

│                                                     │

│  采集 → 评分 → 过滤 → 输出 TruthSignal              │

│       │                                             │

│       ▼ 仅推送实证变更                               │

├─────────────────────────────────────────────────────┤

│         Sentinel Domain                              │

│                                                     │

│  接收 TruthSignal → 差异检测 → 适配器构建            │

│  → 审计日志 → gRPC 原子热更新                       │

│       │                                             │

│       ▼                                             │

├─────────────────────────────────────────────────────┤

│         内核域（永久冻结）                            │

│                                                     │

│  P3 免疫 + TaskSpec 归一化 + 网关转发               │

│  （不感知巴松管的存在，只认 StandardTaskSpec）       │

└─────────────────────────────────────────────────────┘


**关键约束**：巴松管**只认代码与运行行为**，Sentinel **只认巴松管输出的 TruthSignal**。双重防腐，彻底斩断"厂商文案"对 AOS 的影响链路。

---

## 部署形态



yaml

独立 Deployment，与内核、Sentinel 完全隔离

apiVersion: apps/v1

kind: Deployment

metadata:

name: aos-bassoon-probe

namespace: aos-task-governor

spec:

replicas: 1

template:

spec:

containers:

• name: bassoon

image: aos-bassoon:latest

env:

  ◦ name: GITHUB_TOKEN

valueFrom:

secretKeyRef:

name: probe-github-token

key: token

  ◦ name: AZURE_FOUNDRY_API_KEY

valueFrom:

secretKeyRef:

name: azure-foundry-creds

key: api-key

  ◦ name: PROBE_INTERVAL

value: "24h"

  ◦ name: RUNTIME_PROBE_INTERVAL

value: "1h"


**网络策略**：巴松管**主动出站**到 GitHub API + Azure Foundry + Google Gemini API，**不接受任何入站**。纯侦察域，永不被调用。

---

## 封存标记



AOS-BASSOON · 矛体系探真探针予系统 V1.0

全局冻结标签：AOS-BASSOON-v1.0-SEALED-20260726


---

## 已知局限（诚实声明）

1. 微软闭源核心（Copilot 编排层、MAI 推理后端）的确切实现**无法获取源码**，只能靠运行时反推等效逻辑
2. 首次采集后才能建立基线快照，在此之前无法判断"变化"
3. 跨厂商类比（Anthropic/DeepSeek 的参数拦截模式）仅作为探测模板参考，不直接等同于微软/谷歌行为

---

> **"真正的探真不是看厂商想让你看到什么，而是找到系统实际上被代码约束成了什么样子。"**
>
> —— AOS 熔炉之心 2.0 架构委员会



------
