module PlanetaryInteractionAutomation exposing (..)

{-| 行星开发自动化操作模块
提供一键重新采集和自动收取功能的数据类型和操作定义
-}

import Time
import Dict exposing (Dict)


-- 自动化操作类型
type AutomationAction
    = RestartExtraction ExtractorRestartConfig
    | CollectResources CollectionConfig
    | PauseAutomation
    | ResumeAutomation
    | StopAutomation


-- 提取器重启配置
type alias ExtractorRestartConfig =
    { colonyId : String
    , extractorId : String
    , targetResourceType : ResourceType
    , searchRadius : Float -- 搜索半径（公里）
    , minResourceDensity : Float -- 最小资源密度要求
    , cycleDuration : Int -- 采集周期时长（小时）
    , autoOptimize : Bool -- 是否自动优化位置
    }


-- 收取配置
type alias CollectionConfig =
    { characterName : String
    , homeStation : StationInfo
    , targetPlanets : List PlanetCollectionTarget
    , cargoHoldReserve : Float -- 货舱保留空间百分比
    , maxTravelTime : Int -- 最大旅行时间（分钟）
    , safetyChecks : SafetyConfig
    }


-- 行星收取目标
type alias PlanetCollectionTarget =
    { planetId : String
    , planetName : String
    , systemName : String
    , customsOfficeId : String
    , enabled : Bool -- 是否启用收取
    , priority : Int -- 收取优先级（1-10）
    , expectedCargo : Float -- 预期货物量（m³）
    , lastCollectionTime : Maybe Time.Posix
    }


-- 空间站信息
type alias StationInfo =
    { stationId : String
    , stationName : String
    , systemName : String
    , regionName : String
    , coordinates : SpaceCoordinates
    }


-- 空间坐标
type alias SpaceCoordinates =
    { x : Float
    , y : Float
    , z : Float
    }


-- 安全配置
type alias SafetyConfig =
    { maxSecurityStatus : Float -- 最大安全等级限制
    , avoidLowSec : Bool -- 避免低安全区域
    , checkHostiles : Bool -- 检查敌对玩家
    , dockOnThreat : Bool -- 遇到威胁时停靠
    , emergencyDockDistance : Float -- 紧急停靠距离（AU）
    }


-- 自动化状态
type AutomationStatus
    = Idle
    | Planning
    | Executing AutomationStep
    | Paused AutomationStep
    | Completed AutomationResult
    | Failed AutomationError


-- 自动化步骤
type AutomationStep
    = UndockingFromStation
    | NavigatingToSystem String
    | WarpingToPlanet String
    | ApproachingCustomsOffice
    | AccessingCustomsOffice
    | TransferringCargo
    | ReturningToStation
    | DockingAtStation
    | RestartingExtractor ExtractorRestartStep


-- 提取器重启步骤
type ExtractorRestartStep
    = OpeningPlanetaryInterface
    | StoppingCurrentExtraction
    | AnalyzingResourceDistribution
    | SelectingOptimalLocation
    | ConfiguringNewExtraction
    | StartingExtractionCycle


-- 自动化结果
type alias AutomationResult =
    { action : AutomationAction
    , startTime : Time.Posix
    , endTime : Time.Posix
    , success : Bool
    , itemsCollected : List CollectedItem
    , extractorsRestarted : List ExtractorRestartResult
    , totalValue : Float -- ISK
    , errors : List String
    , warnings : List String
    }


-- 收集的物品
type alias CollectedItem =
    { itemType : String
    , quantity : Int
    , volume : Float
    , estimatedValue : Float
    , planetSource : String
    }


-- 提取器重启结果
type alias ExtractorRestartResult =
    { extractorId : String
    , oldLocation : SpaceCoordinates
    , newLocation : SpaceCoordinates
    , oldDensity : Float
    , newDensity : Float
    , improvementPercentage : Float
    }


-- 自动化错误
type AutomationError
    = NavigationError String
    | SecurityThreat String
    | CargoSpaceInsufficient
    | CustomsOfficeInaccessible String
    | ExtractorConfigurationFailed String
    | UnexpectedGameState String
    | TimeoutError String
    | UserInterruption


-- 资源密度分析
type alias ResourceDensityAnalysis =
    { resourceType : ResourceType
    , currentDensity : Float
    , maxDensityFound : Float
    , optimalLocation : SpaceCoordinates
    , densityMap : List DensityPoint
    , analysisTime : Time.Posix
    }


-- 密度点
type alias DensityPoint =
    { coordinates : SpaceCoordinates
    , density : Float
    , distance : Float -- 距离当前位置的距离
    }


-- 自动化配置
type alias AutomationConfig =
    { enabled : Bool
    , maxConcurrentActions : Int
    , defaultCycleDuration : Int -- 小时
    , defaultSearchRadius : Float -- 公里
    , minDensityImprovement : Float -- 最小密度改善百分比
    , collectionInterval : Int -- 收取间隔（小时）
    , safetySettings : SafetyConfig
    , notifications : NotificationConfig
    }


-- 通知配置
type alias NotificationConfig =
    { enableDesktopNotifications : Bool
    , enableSoundAlerts : Bool
    , notifyOnCompletion : Bool
    , notifyOnErrors : Bool
    , notifyOnHighValueCollection : Bool
    , highValueThreshold : Float -- ISK
    }


-- 自动化统计
type alias AutomationStats =
    { totalActionsExecuted : Int
    , successfulActions : Int
    , failedActions : Int
    , totalItemsCollected : Int
    , totalValueCollected : Float
    , totalTimeSpent : Int -- 分钟
    , extractorsOptimized : Int
    , averageImprovementPercentage : Float
    , lastActionTime : Maybe Time.Posix
    }


-- 资源类型（从主模块引用）
type ResourceType
    = AqueousLiquids
    | AutotrophicBacteria
    | BaseMetals
    | CarbonCompounds
    | ComplexOrganisms
    | FelsicMagma
    | HeavyMetals
    | IonicSolutions
    | MaficMagma
    | MicroOrganisms
    | NobleGas
    | NobleMetals
    | NonCSCrystals
    | PlankticColonies
    | ReactiveGas
    | SuspendedPlasma


-- 自动化命令
type AutomationCommand
    = StartExtractorRestart ExtractorRestartConfig
    | StartResourceCollection CollectionConfig
    | PauseCurrentAction
    | ResumeCurrentAction
    | CancelCurrentAction
    | UpdateConfig AutomationConfig
    | GetStatus
    | GetStats


-- 自动化事件
type AutomationEvent
    = ActionStarted AutomationAction
    | ActionCompleted AutomationResult
    | ActionFailed AutomationError
    | StepCompleted AutomationStep
    | ProgressUpdate String Float -- 描述和进度百分比
    | SafetyAlert String
    | ResourceFound ResourceDensityAnalysis
    | CargoCollected CollectedItem


-- 辅助函数

-- 计算两点间距离
calculateDistance : SpaceCoordinates -> SpaceCoordinates -> Float
calculateDistance coord1 coord2 =
    let
        dx = coord1.x - coord2.x
        dy = coord1.y - coord2.y
        dz = coord1.z - coord2.z
    in
    sqrt (dx * dx + dy * dy + dz * dz)


-- 检查安全状态
isSafeSystem : Float -> SafetyConfig -> Bool
isSafeSystem securityStatus config =
    if config.avoidLowSec then
        securityStatus >= 0.5
    else
        securityStatus >= config.maxSecurityStatus


-- 估算旅行时间
estimateTravelTime : SpaceCoordinates -> SpaceCoordinates -> Int
estimateTravelTime from to =
    let
        distance = calculateDistance from to
        -- 假设平均速度为3 AU/s，包括跳跃和对齐时间
        timeInSeconds = distance / 3.0 * 60.0
    in
    round (timeInSeconds / 60.0) -- 转换为分钟


-- 优化收取路线
optimizeCollectionRoute : StationInfo -> List PlanetCollectionTarget -> List PlanetCollectionTarget
optimizeCollectionRoute homeStation targets =
    let
        enabledTargets = List.filter .enabled targets
        sortedByPriority = List.sortBy .priority enabledTargets
    in
    -- 简单的优先级排序，实际实现中可以使用更复杂的路径优化算法
    sortedByPriority


-- 计算预期收益
calculateExpectedValue : List PlanetCollectionTarget -> Float
calculateExpectedValue targets =
    targets
        |> List.filter .enabled
        |> List.map .expectedCargo
        |> List.sum
        |> (*) 1000.0 -- 假设平均每m³价值1000 ISK


-- 验证配置有效性
validateAutomationConfig : AutomationConfig -> List String
validateAutomationConfig config =
    let
        errors = []
        
        errors1 = 
            if config.maxConcurrentActions <= 0 then
                "最大并发操作数必须大于0" :: errors
            else
                errors
                
        errors2 = 
            if config.defaultCycleDuration <= 0 then
                "默认采集周期必须大于0小时" :: errors1
            else
                errors1
                
        errors3 = 
            if config.defaultSearchRadius <= 0 then
                "默认搜索半径必须大于0公里" :: errors2
            else
                errors2
    in
    errors3


-- 生成自动化报告
generateAutomationReport : AutomationStats -> List AutomationResult -> String
generateAutomationReport stats results =
    let
        successRate = 
            if stats.totalActionsExecuted > 0 then
                toFloat stats.successfulActions / toFloat stats.totalActionsExecuted * 100
            else
                0
                
        avgValue = 
            if stats.successfulActions > 0 then
                stats.totalValueCollected / toFloat stats.successfulActions
            else
                0
    in
    "自动化操作报告\n" ++
    "================\n" ++
    "总操作次数: " ++ String.fromInt stats.totalActionsExecuted ++ "\n" ++
    "成功次数: " ++ String.fromInt stats.successfulActions ++ "\n" ++
    "成功率: " ++ String.fromFloat successRate ++ "%\n" ++
    "总收集价值: " ++ String.fromFloat stats.totalValueCollected ++ " ISK\n" ++
    "平均单次价值: " ++ String.fromFloat avgValue ++ " ISK\n" ++
    "提取器优化次数: " ++ String.fromInt stats.extractorsOptimized ++ "\n" ++
    "平均改善率: " ++ String.fromFloat stats.averageImprovementPercentage ++ "%\n"