# EVE Online 行星开发状态识别与展示系统

## 项目概述

本项目为EVE Online的Sanderling内存读取工具扩展了行星开发（Planetary Interaction, PI）状态识别和展示功能。通过解析游戏客户端的UI树结构，系统能够识别和监控玩家的行星殖民地状态，并通过现代化的Web界面进行实时展示。

## 功能特性

### 🔍 行星开发状态识别
- **殖民地检测**: 自动识别所有活跃的行星殖民地
- **设施监控**: 监控指挥中心、提取器、处理器、存储单元、发射台等设施状态
- **资源追踪**: 跟踪各种行星资源的提取情况和产量
- **电力/CPU监控**: 实时监控殖民地的电力和CPU使用情况
- **周期管理**: 跟踪提取程序的周期状态和剩余时间

### 📊 实时数据展示
- **现代化仪表板**: 响应式Web界面，支持桌面和移动设备
- **实时更新**: 支持自动刷新和手动刷新数据
- **状态指示**: 直观的颜色编码和状态指示器
- **详细信息**: 点击查看殖民地的详细设施和生产信息
- **警报系统**: 自动检测需要关注的问题并发出警报

### 🚀 高级功能
- **数据导出**: 支持将监控数据导出为JSON格式
- **连接状态监控**: 实时显示与游戏客户端的连接状态
- **性能监控**: 显示内存读取性能和数据新鲜度
- **资源分析**: 详细的资源产量和价值分析

## 项目结构

```
/workspace/project/
├── Sanderling/                          # 原始Sanderling项目
├── planetary_interaction_types.elm      # 行星开发数据类型定义
├── planetary_interaction_parser.elm     # 行星开发解析器实现
├── pi_integration.elm                   # Sanderling集成代码
├── pi_dashboard.html                    # 基础仪表板界面
├── pi_dashboard_enhanced.html           # 增强版仪表板（推荐）
├── pi_api_server.py                     # 模拟API服务器
└── README_PI_Extension.md               # 本文档
```

## 技术架构

### 数据解析层 (Elm)
- **类型系统**: 使用Elm的强类型系统定义行星开发相关的数据结构
- **解析器**: 从Sanderling的UI树中提取行星开发信息
- **集成接口**: 与现有Sanderling解析器的集成点

### API服务层 (Python)
- **RESTful API**: 提供标准化的数据访问接口
- **实时数据**: 模拟从游戏客户端获取的实时数据
- **CORS支持**: 支持跨域请求，便于Web界面访问

### 展示层 (HTML/CSS/JavaScript)
- **响应式设计**: 适配各种屏幕尺寸
- **实时更新**: 支持自动和手动数据刷新
- **交互式界面**: 丰富的用户交互和详情展示

## 快速开始

### 1. 启动服务

```bash
# 启动Web服务器（端口12000）
cd /workspace/project
python -m http.server 12000 --bind 0.0.0.0 &

# 启动API服务器（端口12001）
python pi_api_server.py &
```

### 2. 访问界面

- **基础版仪表板**: https://work-1-klycxfekopkjwjtm.prod-runtime.all-hands.dev/pi_dashboard.html
- **增强版仪表板**: https://work-1-klycxfekopkjwjtm.prod-runtime.all-hands.dev/pi_dashboard_enhanced.html

### 3. API端点

- `GET /api/pi/status` - 获取整体状态信息
- `GET /api/pi/colonies` - 获取所有殖民地概览
- `GET /api/pi/colony?id=<colony_id>` - 获取特定殖民地详情
- `GET /api/pi/resources` - 获取资源统计信息

## 数据结构

### 殖民地信息
```elm
type alias Colony =
    { planetName : String
    , planetType : PlanetType
    , status : ColonyStatus
    , powerUsage : { used : Int, total : Int }
    , cpuUsage : { used : Int, total : Int }
    , facilities : List Facility
    , extractors : List Extractor
    , lastUpdate : Maybe Time.Posix
    }
```

### 设施类型
- **指挥中心** (Command Center): 殖民地的核心设施
- **提取器** (Extractor): 用于开采行星资源
- **处理器** (Processor): 用于加工原材料
- **存储单元** (Storage Unit): 存储材料和产品
- **发射台** (Launchpad): 用于进出口货物

### 资源类型
支持所有EVE Online中的行星资源类型：
- 水性液体 (Aqueous Liquids)
- 自养细菌 (Autotrophic Bacteria)
- 基础金属 (Base Metals)
- 碳化合物 (Carbon Compounds)
- 复杂有机体 (Complex Organisms)
- 长英质岩浆 (Felsic Magma)
- 重金属 (Heavy Metals)
- 离子溶液 (Ionic Solutions)
- 镁铁质岩浆 (Mafic Magma)
- 微生物 (Micro Organisms)
- 惰性气体 (Noble Gas)
- 贵金属 (Noble Metals)
- 非CS晶体 (Non-CS Crystals)
- 浮游生物 (Planktic)
- 活性气体 (Reactive Gas)
- 悬浮等离子体 (Suspended Plasma)

## 集成到Sanderling

要将此功能集成到现有的Sanderling项目中，需要进行以下修改：

### 1. 修改ParseUserInterface.elm

在`ParsedUserInterface`类型中添加：
```elm
, planetaryInteractionWindows : List PlanetaryInteractionWindow
```

在`parseUserInterfaceFromUITreeRoot`函数中添加：
```elm
, planetaryInteractionWindows = parsePlanetaryInteractionWindowsFromUITreeRoot uiTree
```

### 2. 添加解析函数

将`pi_integration.elm`中的解析函数添加到主解析器模块中。

### 3. 更新依赖

确保项目包含必要的Elm包和依赖项。

## 监控指标

### 性能指标
- **数据新鲜度**: 数据的实时性程度
- **扫描耗时**: 内存读取和解析的时间
- **连接状态**: 与游戏客户端的连接状态
- **更新频率**: 数据更新的频率

### 业务指标
- **活跃殖民地数量**: 正在运行的殖民地总数
- **总产量**: 所有殖民地的总产量
- **资源效率**: 提取器的平均效率
- **需要关注的问题**: 需要玩家处理的问题数量

## 警报系统

系统会自动检测以下情况并发出警报：

### ⚠️ 警告级别
- 提取器停止运行
- 存储单元接近满载
- CPU或电力使用率过高
- 提取程序即将结束

### 🚨 错误级别
- 设施出现错误状态
- 连接中断
- 数据读取失败

## 扩展功能

### 计划中的功能
- **历史数据记录**: 记录和分析历史生产数据
- **预测分析**: 基于历史数据预测产量和收益
- **自动化建议**: 基于当前状态提供优化建议
- **多角色支持**: 支持监控多个角色的殖民地
- **移动应用**: 开发移动端应用程序

### 自定义扩展
- **自定义警报规则**: 允许用户设置自定义的警报条件
- **数据导出格式**: 支持更多的数据导出格式
- **第三方集成**: 与其他EVE Online工具的集成
- **API扩展**: 提供更多的API端点和功能

## 故障排除

### 常见问题

1. **无法连接到API服务器**
   - 检查API服务器是否正在运行
   - 确认端口12001没有被其他程序占用
   - 检查防火墙设置

2. **数据不更新**
   - 检查与EVE Online客户端的连接
   - 确认Sanderling内存读取功能正常
   - 检查浏览器控制台的错误信息

3. **界面显示异常**
   - 清除浏览器缓存
   - 检查浏览器兼容性
   - 确认JavaScript已启用

### 调试模式

在浏览器控制台中启用调试模式：
```javascript
localStorage.setItem('pi_debug', 'true');
```

## 贡献指南

欢迎为此项目贡献代码和建议！

### 开发环境设置
1. 克隆Sanderling项目
2. 安装Elm开发环境
3. 设置Python开发环境
4. 运行测试服务器

### 提交规范
- 使用清晰的提交信息
- 遵循现有的代码风格
- 添加必要的测试和文档
- 确保向后兼容性

## 许可证

本项目遵循与Sanderling相同的许可证条款。

## 联系信息

如有问题或建议，请通过以下方式联系：
- GitHub Issues
- EVE Online游戏内邮件
- 相关论坛和社区

---

**注意**: 本项目仅用于教育和研究目的。使用时请遵守EVE Online的服务条款和CCP Games的相关政策。