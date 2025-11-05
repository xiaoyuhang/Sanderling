-- Planetary Interaction Parser for EVE Online
-- This module provides functions to parse planetary interaction UI elements

module PlanetaryInteractionParser exposing (..)

import Dict
import List.Extra
import Maybe.Extra
import PlanetaryInteraction exposing (..)
import Regex
import String
import Time


-- Parse planetary interaction window from UI tree
parsePlanetaryInteractionWindow : UITreeNodeWithDisplayRegion -> Maybe PlanetaryInteractionWindow
parsePlanetaryInteractionWindow windowNode =
    if isPlanetaryInteractionWindow windowNode then
        Just
            { uiNode = windowNode
            , planetInfo = parsePlanetInfo windowNode
            , colonies = parseColonies windowNode
            , commandCenter = parseCommandCenter windowNode
            , facilities = parseFacilities windowNode
            , extractors = parseExtractors windowNode
            , processors = parseProcessors windowNode
            , storageUnits = parseStorageUnits windowNode
            , launchpads = parseLaunchpads windowNode
            , links = parseLinks windowNode
            , routes = parseRoutes windowNode
            , planetResources = parsePlanetResources windowNode
            , cycleInfo = parseCycleInfo windowNode
            }

    else
        Nothing


-- Check if a UI node represents a planetary interaction window
isPlanetaryInteractionWindow : UITreeNodeWithDisplayRegion -> Bool
isPlanetaryInteractionWindow node =
    let
        typeName = node.uiNode.pythonObjectTypeName
        
        -- Common type names for PI windows in EVE Online
        piWindowTypes = 
            [ "PlanetWindow"
            , "PlanetaryInteractionWindow"
            , "ColonyWindow"
            , "PlanetView"
            , "PlanetaryManagement"
            ]
    in
    List.member typeName piWindowTypes


-- Parse planet information
parsePlanetInfo : UITreeNodeWithDisplayRegion -> Maybe PlanetInfo
parsePlanetInfo windowNode =
    let
        planetNameNode = findNodeByName windowNode "planetName"
        planetTypeNode = findNodeByName windowNode "planetType"
        securityNode = findNodeByName windowNode "securityStatus"
        systemNode = findNodeByName windowNode "systemName"
        regionNode = findNodeByName windowNode "regionName"
        
        planetName = planetNameNode |> Maybe.andThen getDisplayText |> Maybe.withDefault "Unknown"
        planetTypeStr = planetTypeNode |> Maybe.andThen getDisplayText |> Maybe.withDefault "Unknown"
        securityStr = securityNode |> Maybe.andThen getDisplayText |> Maybe.withDefault "0.0"
        systemName = systemNode |> Maybe.andThen getDisplayText |> Maybe.withDefault "Unknown"
        regionName = regionNode |> Maybe.andThen getDisplayText |> Maybe.withDefault "Unknown"
        
        planetType = parsePlanetType planetTypeStr
        security = String.toFloat securityStr |> Maybe.withDefault 0.0
    in
    Just
        { name = planetName
        , planetType = planetType
        , securityStatus = security
        , systemName = systemName
        , regionName = regionName
        }


-- Parse planet type from string
parsePlanetType : String -> PlanetType
parsePlanetType typeStr =
    case String.toLower typeStr of
        "temperate" -> Temperate
        "barren" -> Barren
        "oceanic" -> Oceanic
        "ice" -> Ice
        "gas" -> Gas
        "lava" -> Lava
        "storm" -> Storm
        "plasma" -> Plasma
        _ -> Barren  -- Default


-- Parse colonies
parseColonies : UITreeNodeWithDisplayRegion -> List Colony
parseColonies windowNode =
    findNodesByType windowNode "Colony"
        |> List.filterMap parseColony


-- Parse a single colony
parseColony : UITreeNodeWithDisplayRegion -> Maybe Colony
parseColony colonyNode =
    let
        planetName = getDisplayText colonyNode |> Maybe.withDefault "Unknown"
        commandCenterLevel = parseCommandCenterLevel colonyNode
        powerInfo = parsePowerInfo colonyNode
        cpuInfo = parseCpuInfo colonyNode
        facilities = parseFacilities colonyNode
        status = parseColonyStatus colonyNode
    in
    Just
        { uiNode = colonyNode
        , planetName = planetName
        , commandCenterLevel = commandCenterLevel
        , powerUsed = powerInfo.used
        , powerTotal = powerInfo.total
        , cpuUsed = cpuInfo.used
        , cpuTotal = cpuInfo.total
        , facilities = facilities
        , lastUpdate = Nothing  -- Would need timestamp parsing
        , status = status
        }


-- Parse command center level
parseCommandCenterLevel : UITreeNodeWithDisplayRegion -> Int
parseCommandCenterLevel node =
    findNodeByName node "commandCenterLevel"
        |> Maybe.andThen getDisplayText
        |> Maybe.andThen String.toInt
        |> Maybe.withDefault 1


-- Parse power information
parsePowerInfo : UITreeNodeWithDisplayRegion -> { used : Int, total : Int }
parsePowerInfo node =
    let
        powerText = findNodeByName node "powerUsage"
            |> Maybe.andThen getDisplayText
            |> Maybe.withDefault "0/0"
        
        parts = String.split "/" powerText
        used = List.head parts |> Maybe.andThen String.toInt |> Maybe.withDefault 0
        total = List.drop 1 parts |> List.head |> Maybe.andThen String.toInt |> Maybe.withDefault 0
    in
    { used = used, total = total }


-- Parse CPU information
parseCpuInfo : UITreeNodeWithDisplayRegion -> { used : Int, total : Int }
parseCpuInfo node =
    let
        cpuText = findNodeByName node "cpuUsage"
            |> Maybe.andThen getDisplayText
            |> Maybe.withDefault "0/0"
        
        parts = String.split "/" cpuText
        used = List.head parts |> Maybe.andThen String.toInt |> Maybe.withDefault 0
        total = List.drop 1 parts |> List.head |> Maybe.andThen String.toInt |> Maybe.withDefault 0
    in
    { used = used, total = total }


-- Parse colony status
parseColonyStatus : UITreeNodeWithDisplayRegion -> ColonyStatus
parseColonyStatus node =
    let
        statusText = findNodeByName node "status"
            |> Maybe.andThen getDisplayText
            |> Maybe.withDefault ""
            |> String.toLower
    in
    case statusText of
        "active" -> Active
        "inactive" -> Inactive
        "needs attention" -> NeedsAttention
        "extracting" -> Extracting
        "processing" -> Processing
        "full" -> Full
        _ -> Inactive


-- Parse command center
parseCommandCenter : UITreeNodeWithDisplayRegion -> Maybe CommandCenter
parseCommandCenter windowNode =
    findNodeByType windowNode "CommandCenter"
        |> List.head
        |> Maybe.andThen parseCommandCenterFromNode


-- Parse command center from node
parseCommandCenterFromNode : UITreeNodeWithDisplayRegion -> Maybe CommandCenter
parseCommandCenterFromNode node =
    let
        facility = parseFacilityFromNode node CommandCenterFacility
        level = parseCommandCenterLevel node
        upgradeAvailable = checkUpgradeAvailable node
    in
    Just
        { facility = facility
        , level = level
        , upgradeAvailable = upgradeAvailable
        }


-- Check if upgrade is available
checkUpgradeAvailable : UITreeNodeWithDisplayRegion -> Bool
checkUpgradeAvailable node =
    findNodeByName node "upgradeButton"
        |> Maybe.map (always True)
        |> Maybe.withDefault False


-- Parse facilities
parseFacilities : UITreeNodeWithDisplayRegion -> List Facility
parseFacilities windowNode =
    let
        facilityTypes = 
            [ ("CommandCenter", CommandCenterFacility)
            , ("Extractor", ExtractorFacility)
            , ("Processor", ProcessorFacility)
            , ("StorageUnit", StorageUnitFacility)
            , ("Launchpad", LaunchpadFacility)
            , ("Link", LinkFacility)
            ]
    in
    facilityTypes
        |> List.concatMap (\(typeName, facilityType) ->
            findNodesByType windowNode typeName
                |> List.map (parseFacilityFromNode facilityType)
        )


-- Parse facility from node
parseFacilityFromNode : FacilityType -> UITreeNodeWithDisplayRegion -> Facility
parseFacilityFromNode facilityType node =
    let
        facilityId = getFacilityId node
        position = parsePosition node
        powerConsumption = parsePowerConsumption node
        cpuConsumption = parseCpuConsumption node
        status = parseFacilityStatus node
        contents = parseContents node
    in
    { uiNode = node
    , facilityId = facilityId
    , facilityType = facilityType
    , position = position
    , powerConsumption = powerConsumption
    , cpuConsumption = cpuConsumption
    , status = status
    , contents = contents
    }


-- Get facility ID
getFacilityId : UITreeNodeWithDisplayRegion -> String
getFacilityId node =
    findNodeByName node "facilityId"
        |> Maybe.andThen getDisplayText
        |> Maybe.withDefault (String.fromInt (hashCode node))


-- Parse position
parsePosition : UITreeNodeWithDisplayRegion -> Location2d
parsePosition node =
    let
        x = findNodeByName node "positionX"
            |> Maybe.andThen getDisplayText
            |> Maybe.andThen String.toFloat
            |> Maybe.withDefault 0.0
        
        y = findNodeByName node "positionY"
            |> Maybe.andThen getDisplayText
            |> Maybe.andThen String.toFloat
            |> Maybe.withDefault 0.0
    in
    { x = x, y = y }


-- Parse power consumption
parsePowerConsumption : UITreeNodeWithDisplayRegion -> Int
parsePowerConsumption node =
    findNodeByName node "powerConsumption"
        |> Maybe.andThen getDisplayText
        |> Maybe.andThen String.toInt
        |> Maybe.withDefault 0


-- Parse CPU consumption
parseCpuConsumption : UITreeNodeWithDisplayRegion -> Int
parseCpuConsumption node =
    findNodeByName node "cpuConsumption"
        |> Maybe.andThen getDisplayText
        |> Maybe.andThen String.toInt
        |> Maybe.withDefault 0


-- Parse facility status
parseFacilityStatus : UITreeNodeWithDisplayRegion -> FacilityStatus
parseFacilityStatus node =
    let
        statusText = findNodeByName node "facilityStatus"
            |> Maybe.andThen getDisplayText
            |> Maybe.withDefault ""
            |> String.toLower
    in
    case statusText of
        "active" -> FacilityActive
        "inactive" -> FacilityInactive
        "full" -> FacilityFull
        "empty" -> FacilityEmpty
        "error" -> FacilityError
        _ -> FacilityInactive


-- Parse contents
parseContents : UITreeNodeWithDisplayRegion -> List ItemStack
parseContents node =
    findNodesByType node "ItemStack"
        |> List.filterMap parseItemStack


-- Parse item stack
parseItemStack : UITreeNodeWithDisplayRegion -> Maybe ItemStack
parseItemStack node =
    let
        itemType = findNodeByName node "itemType"
            |> Maybe.andThen getDisplayText
            |> Maybe.withDefault "Unknown"
        
        quantity = findNodeByName node "quantity"
            |> Maybe.andThen getDisplayText
            |> Maybe.andThen String.toInt
            |> Maybe.withDefault 0
        
        volume = findNodeByName node "volume"
            |> Maybe.andThen getDisplayText
            |> Maybe.andThen String.toFloat
            |> Maybe.withDefault 0.0
    in
    Just
        { itemType = itemType
        , quantity = quantity
        , volume = volume
        }


-- Parse extractors
parseExtractors : UITreeNodeWithDisplayRegion -> List Extractor
parseExtractors windowNode =
    findNodesByType windowNode "Extractor"
        |> List.filterMap parseExtractor


-- Parse extractor
parseExtractor : UITreeNodeWithDisplayRegion -> Maybe Extractor
parseExtractor node =
    let
        facility = parseFacilityFromNode ExtractorFacility node
        extractorType = parseExtractorType node
        targetResource = parseTargetResource node
        extractionRate = parseExtractionRate node
        cycleTime = parseCycleTime node
        heads = parseExtractorHeads node
        program = parseExtractionProgram node
    in
    Just
        { facility = facility
        , extractorType = extractorType
        , targetResource = targetResource
        , extractionRate = extractionRate
        , cycleTime = cycleTime
        , heads = heads
        , program = program
        }


-- Parse extractor type
parseExtractorType : UITreeNodeWithDisplayRegion -> ExtractorType
parseExtractorType node =
    let
        typeText = findNodeByName node "extractorType"
            |> Maybe.andThen getDisplayText
            |> Maybe.withDefault ""
            |> String.toLower
    in
    case typeText of
        "advanced" -> AdvancedExtractor
        _ -> BasicExtractor


-- Parse target resource
parseTargetResource : UITreeNodeWithDisplayRegion -> Maybe PlanetResource
parseTargetResource node =
    findNodeByName node "targetResource"
        |> Maybe.andThen parseResourceFromNode


-- Parse resource from node
parseResourceFromNode : UITreeNodeWithDisplayRegion -> Maybe PlanetResource
parseResourceFromNode node =
    let
        resourceTypeStr = getDisplayText node |> Maybe.withDefault ""
        resourceType = parseResourceType resourceTypeStr
        density = parseDensity node
        position = parsePosition node
        extractionRate = parseExtractionRate node
    in
    Just
        { resourceType = resourceType
        , density = density
        , position = position
        , extractionRate = extractionRate
        }


-- Parse resource type
parseResourceType : String -> ResourceType
parseResourceType typeStr =
    case String.toLower typeStr of
        "aqueous liquids" -> AqueousLiquids
        "autotrophic bacteria" -> AutootropicBacteria
        "base metals" -> BaseMetals
        "carbon compounds" -> CarbonCompounds
        "complex organisms" -> ComplexOrganisms
        "felsic magma" -> FelsicMagma
        "heavy metals" -> HeavyMetals
        "ionic solutions" -> IonicSolutions
        "mafic magma" -> MaficMagma
        "micro organisms" -> MicroOrganisms
        "noble gas" -> NobleGas
        "noble metals" -> NobleMetals
        "non-cs crystals" -> NonCSCrystals
        "planktic" -> Planktic
        "reactive gas" -> ReactiveGas
        "suspended plasma" -> SuspendedPlasma
        _ -> BaseMetals  -- Default


-- Parse density
parseDensity : UITreeNodeWithDisplayRegion -> Float
parseDensity node =
    findNodeByName node "density"
        |> Maybe.andThen getDisplayText
        |> Maybe.andThen String.toFloat
        |> Maybe.withDefault 0.0


-- Parse extraction rate
parseExtractionRate : UITreeNodeWithDisplayRegion -> Float
parseExtractionRate node =
    findNodeByName node "extractionRate"
        |> Maybe.andThen getDisplayText
        |> Maybe.andThen String.toFloat
        |> Maybe.withDefault 0.0


-- Parse cycle time
parseCycleTime : UITreeNodeWithDisplayRegion -> Int
parseCycleTime node =
    findNodeByName node "cycleTime"
        |> Maybe.andThen getDisplayText
        |> Maybe.andThen String.toInt
        |> Maybe.withDefault 3600  -- Default 1 hour


-- Parse extractor heads
parseExtractorHeads : UITreeNodeWithDisplayRegion -> List ExtractorHead
parseExtractorHeads node =
    findNodesByType node "ExtractorHead"
        |> List.filterMap parseExtractorHead


-- Parse extractor head
parseExtractorHead : UITreeNodeWithDisplayRegion -> Maybe ExtractorHead
parseExtractorHead node =
    let
        position = parsePosition node
        resourceDensity = parseDensity node
        isActive = parseIsActive node
    in
    Just
        { position = position
        , resourceDensity = resourceDensity
        , isActive = isActive
        }


-- Parse if something is active
parseIsActive : UITreeNodeWithDisplayRegion -> Bool
parseIsActive node =
    findNodeByName node "isActive"
        |> Maybe.andThen getDisplayText
        |> Maybe.map (String.toLower >> (==) "true")
        |> Maybe.withDefault False


-- Parse extraction program
parseExtractionProgram : UITreeNodeWithDisplayRegion -> Maybe ExtractionProgram
parseExtractionProgram node =
    findNodeByName node "extractionProgram"
        |> Maybe.andThen parseExtractionProgramFromNode


-- Parse extraction program from node
parseExtractionProgramFromNode : UITreeNodeWithDisplayRegion -> Maybe ExtractionProgram
parseExtractionProgramFromNode node =
    let
        startTime = parseTime node "startTime"
        duration = parseDuration node
        cycles = parseExtractionCycles node
    in
    case startTime of
        Just time ->
            Just
                { startTime = time
                , duration = duration
                , cycles = cycles
                }
        
        Nothing ->
            Nothing


-- Parse time (placeholder - would need proper time parsing)
parseTime : UITreeNodeWithDisplayRegion -> String -> Maybe Time.Posix
parseTime node fieldName =
    findNodeByName node fieldName
        |> Maybe.andThen getDisplayText
        |> Maybe.andThen (\_ -> Nothing)  -- Placeholder


-- Parse duration
parseDuration : UITreeNodeWithDisplayRegion -> Int
parseDuration node =
    findNodeByName node "duration"
        |> Maybe.andThen getDisplayText
        |> Maybe.andThen String.toInt
        |> Maybe.withDefault 86400  -- Default 24 hours


-- Parse extraction cycles
parseExtractionCycles : UITreeNodeWithDisplayRegion -> List ExtractionCycle
parseExtractionCycles node =
    findNodesByType node "ExtractionCycle"
        |> List.filterMap parseExtractionCycle


-- Parse extraction cycle
parseExtractionCycle : UITreeNodeWithDisplayRegion -> Maybe ExtractionCycle
parseExtractionCycle node =
    let
        cycleNumber = parseCycleNumber node
        startTime = parseTime node "startTime"
        endTime = parseTime node "endTime"
        extractionRate = parseExtractionRate node
        status = parseCycleStatus node
    in
    case (startTime, endTime) of
        (Just start, Just end) ->
            Just
                { cycleNumber = cycleNumber
                , startTime = start
                , endTime = end
                , extractionRate = extractionRate
                , status = status
                }
        
        _ ->
            Nothing


-- Parse cycle number
parseCycleNumber : UITreeNodeWithDisplayRegion -> Int
parseCycleNumber node =
    findNodeByName node "cycleNumber"
        |> Maybe.andThen getDisplayText
        |> Maybe.andThen String.toInt
        |> Maybe.withDefault 1


-- Parse cycle status
parseCycleStatus : UITreeNodeWithDisplayRegion -> CycleStatus
parseCycleStatus node =
    let
        statusText = findNodeByName node "cycleStatus"
            |> Maybe.andThen getDisplayText
            |> Maybe.withDefault ""
            |> String.toLower
    in
    case statusText of
        "active" -> CycleActive
        "completed" -> CycleCompleted
        "pending" -> CyclePending
        _ -> CyclePending


-- Parse processors
parseProcessors : UITreeNodeWithDisplayRegion -> List Processor
parseProcessors windowNode =
    findNodesByType windowNode "Processor"
        |> List.filterMap parseProcessor


-- Parse processor
parseProcessor : UITreeNodeWithDisplayRegion -> Maybe Processor
parseProcessor node =
    let
        facility = parseFacilityFromNode ProcessorFacility node
        processorTier = parseProcessorTier node
        schematic = parseSchematic node
        inputMaterials = parseInputMaterials node
        outputProducts = parseOutputProducts node
        cyclesRemaining = parseCyclesRemaining node
        isRunning = parseIsRunning node
    in
    Just
        { facility = facility
        , processorTier = processorTier
        , schematic = schematic
        , inputMaterials = inputMaterials
        , outputProducts = outputProducts
        , cyclesRemaining = cyclesRemaining
        , isRunning = isRunning
        }


-- Parse processor tier
parseProcessorTier : UITreeNodeWithDisplayRegion -> ProcessorTier
parseProcessorTier node =
    let
        tierText = findNodeByName node "processorTier"
            |> Maybe.andThen getDisplayText
            |> Maybe.withDefault ""
            |> String.toLower
    in
    case tierText of
        "advanced" -> AdvancedProcessor
        "high tech" -> HighTechProcessor
        _ -> BasicProcessor


-- Parse schematic
parseSchematic : UITreeNodeWithDisplayRegion -> Maybe Schematic
parseSchematic node =
    findNodeByName node "schematic"
        |> Maybe.andThen parseSchematicFromNode


-- Parse schematic from node
parseSchematicFromNode : UITreeNodeWithDisplayRegion -> Maybe Schematic
parseSchematicFromNode node =
    let
        schematicId = getFacilityId node
        name = getDisplayText node |> Maybe.withDefault "Unknown"
        inputs = parseInputRequirements node
        outputs = parseOutputRequirements node
        cycleTime = parseCycleTime node
    in
    Just
        { schematicId = schematicId
        , name = name
        , inputs = inputs
        , outputs = outputs
        , cycleTime = cycleTime
        }


-- Parse input requirements
parseInputRequirements : UITreeNodeWithDisplayRegion -> List MaterialRequirement
parseInputRequirements node =
    findNodesByType node "InputRequirement"
        |> List.filterMap parseMaterialRequirement


-- Parse output requirements
parseOutputRequirements : UITreeNodeWithDisplayRegion -> List MaterialRequirement
parseOutputRequirements node =
    findNodesByType node "OutputRequirement"
        |> List.filterMap parseMaterialRequirement


-- Parse material requirement
parseMaterialRequirement : UITreeNodeWithDisplayRegion -> Maybe MaterialRequirement
parseMaterialRequirement node =
    let
        materialType = findNodeByName node "materialType"
            |> Maybe.andThen getDisplayText
            |> Maybe.withDefault "Unknown"
        
        quantity = findNodeByName node "quantity"
            |> Maybe.andThen getDisplayText
            |> Maybe.andThen String.toInt
            |> Maybe.withDefault 0
    in
    Just
        { materialType = materialType
        , quantity = quantity
        }


-- Parse input materials
parseInputMaterials : UITreeNodeWithDisplayRegion -> List ItemStack
parseInputMaterials node =
    findNodeByName node "inputMaterials"
        |> Maybe.map (findNodesByType "ItemStack")
        |> Maybe.withDefault []
        |> List.filterMap parseItemStack


-- Parse output products
parseOutputProducts : UITreeNodeWithDisplayRegion -> List ItemStack
parseOutputProducts node =
    findNodeByName node "outputProducts"
        |> Maybe.map (findNodesByType "ItemStack")
        |> Maybe.withDefault []
        |> List.filterMap parseItemStack


-- Parse cycles remaining
parseCyclesRemaining : UITreeNodeWithDisplayRegion -> Int
parseCyclesRemaining node =
    findNodeByName node "cyclesRemaining"
        |> Maybe.andThen getDisplayText
        |> Maybe.andThen String.toInt
        |> Maybe.withDefault 0


-- Parse if running
parseIsRunning : UITreeNodeWithDisplayRegion -> Bool
parseIsRunning node =
    findNodeByName node "isRunning"
        |> Maybe.andThen getDisplayText
        |> Maybe.map (String.toLower >> (==) "true")
        |> Maybe.withDefault False


-- Parse storage units
parseStorageUnits : UITreeNodeWithDisplayRegion -> List StorageUnit
parseStorageUnits windowNode =
    findNodesByType windowNode "StorageUnit"
        |> List.filterMap parseStorageUnit


-- Parse storage unit
parseStorageUnit : UITreeNodeWithDisplayRegion -> Maybe StorageUnit
parseStorageUnit node =
    let
        facility = parseFacilityFromNode StorageUnitFacility node
        capacity = parseCapacity node
        used = parseUsed node
        contents = parseContents node
    in
    Just
        { facility = facility
        , capacity = capacity
        , used = used
        , contents = contents
        }


-- Parse capacity
parseCapacity : UITreeNodeWithDisplayRegion -> Int
parseCapacity node =
    findNodeByName node "capacity"
        |> Maybe.andThen getDisplayText
        |> Maybe.andThen String.toInt
        |> Maybe.withDefault 0


-- Parse used
parseUsed : UITreeNodeWithDisplayRegion -> Int
parseUsed node =
    findNodeByName node "used"
        |> Maybe.andThen getDisplayText
        |> Maybe.andThen String.toInt
        |> Maybe.withDefault 0


-- Parse launchpads
parseLaunchpads : UITreeNodeWithDisplayRegion -> List Launchpad
parseLaunchpads windowNode =
    findNodesByType windowNode "Launchpad"
        |> List.filterMap parseLaunchpad


-- Parse launchpad
parseLaunchpad : UITreeNodeWithDisplayRegion -> Maybe Launchpad
parseLaunchpad node =
    let
        facility = parseFacilityFromNode LaunchpadFacility node
        capacity = parseCapacity node
        used = parseUsed node
        contents = parseContents node
        pendingTransfers = parsePendingTransfers node
    in
    Just
        { facility = facility
        , capacity = capacity
        , used = used
        , contents = contents
        , pendingTransfers = pendingTransfers
        }


-- Parse pending transfers
parsePendingTransfers : UITreeNodeWithDisplayRegion -> List Transfer
parsePendingTransfers node =
    findNodesByType node "Transfer"
        |> List.filterMap parseTransfer


-- Parse transfer
parseTransfer : UITreeNodeWithDisplayRegion -> Maybe Transfer
parseTransfer node =
    let
        transferId = getFacilityId node
        transferType = parseTransferType node
        items = parseTransferItems node
        destination = parseDestination node
        estimatedTime = parseTime node "estimatedTime"
        status = parseTransferStatus node
    in
    Just
        { transferId = transferId
        , transferType = transferType
        , items = items
        , destination = destination
        , estimatedTime = estimatedTime
        , status = status
        }


-- Parse transfer type
parseTransferType : UITreeNodeWithDisplayRegion -> TransferType
parseTransferType node =
    let
        typeText = findNodeByName node "transferType"
            |> Maybe.andThen getDisplayText
            |> Maybe.withDefault ""
            |> String.toLower
    in
    case typeText of
        "import" -> Import
        "export" -> Export
        _ -> Export


-- Parse transfer items
parseTransferItems : UITreeNodeWithDisplayRegion -> List ItemStack
parseTransferItems node =
    findNodeByName node "transferItems"
        |> Maybe.map (findNodesByType "ItemStack")
        |> Maybe.withDefault []
        |> List.filterMap parseItemStack


-- Parse destination
parseDestination : UITreeNodeWithDisplayRegion -> String
parseDestination node =
    findNodeByName node "destination"
        |> Maybe.andThen getDisplayText
        |> Maybe.withDefault "Unknown"


-- Parse transfer status
parseTransferStatus : UITreeNodeWithDisplayRegion -> TransferStatus
parseTransferStatus node =
    let
        statusText = findNodeByName node "transferStatus"
            |> Maybe.andThen getDisplayText
            |> Maybe.withDefault ""
            |> String.toLower
    in
    case statusText of
        "pending" -> TransferPending
        "in progress" -> TransferInProgress
        "completed" -> TransferCompleted
        "failed" -> TransferFailed
        _ -> TransferPending


-- Parse links
parseLinks : UITreeNodeWithDisplayRegion -> List Link
parseLinks windowNode =
    findNodesByType windowNode "Link"
        |> List.filterMap parseLink


-- Parse link
parseLink : UITreeNodeWithDisplayRegion -> Maybe Link
parseLink node =
    let
        linkId = getFacilityId node
        fromFacility = parseFromFacility node
        toFacility = parseToFacility node
        length = parseLength node
        powerConsumption = parsePowerConsumption node
        cpuConsumption = parseCpuConsumption node
        isActive = parseIsActive node
    in
    Just
        { uiNode = node
        , linkId = linkId
        , fromFacility = fromFacility
        , toFacility = toFacility
        , length = length
        , powerConsumption = powerConsumption
        , cpuConsumption = cpuConsumption
        , isActive = isActive
        }


-- Parse from facility
parseFromFacility : UITreeNodeWithDisplayRegion -> String
parseFromFacility node =
    findNodeByName node "fromFacility"
        |> Maybe.andThen getDisplayText
        |> Maybe.withDefault "Unknown"


-- Parse to facility
parseToFacility : UITreeNodeWithDisplayRegion -> String
parseToFacility node =
    findNodeByName node "toFacility"
        |> Maybe.andThen getDisplayText
        |> Maybe.withDefault "Unknown"


-- Parse length
parseLength : UITreeNodeWithDisplayRegion -> Float
parseLength node =
    findNodeByName node "length"
        |> Maybe.andThen getDisplayText
        |> Maybe.andThen String.toFloat
        |> Maybe.withDefault 0.0


-- Parse routes
parseRoutes : UITreeNodeWithDisplayRegion -> List Route
parseRoutes windowNode =
    findNodesByType windowNode "Route"
        |> List.filterMap parseRoute


-- Parse route
parseRoute : UITreeNodeWithDisplayRegion -> Maybe Route
parseRoute node =
    let
        routeId = getFacilityId node
        sourceFacility = parseSourceFacility node
        destinationFacility = parseDestinationFacility node
        materialType = parseMaterialType node
        quantity = parseQuantity node
        isActive = parseIsActive node
    in
    Just
        { routeId = routeId
        , sourceFacility = sourceFacility
        , destinationFacility = destinationFacility
        , materialType = materialType
        , quantity = quantity
        , isActive = isActive
        }


-- Parse source facility
parseSourceFacility : UITreeNodeWithDisplayRegion -> String
parseSourceFacility node =
    findNodeByName node "sourceFacility"
        |> Maybe.andThen getDisplayText
        |> Maybe.withDefault "Unknown"


-- Parse destination facility
parseDestinationFacility : UITreeNodeWithDisplayRegion -> String
parseDestinationFacility node =
    findNodeByName node "destinationFacility"
        |> Maybe.andThen getDisplayText
        |> Maybe.withDefault "Unknown"


-- Parse material type
parseMaterialType : UITreeNodeWithDisplayRegion -> String
parseMaterialType node =
    findNodeByName node "materialType"
        |> Maybe.andThen getDisplayText
        |> Maybe.withDefault "Unknown"


-- Parse quantity
parseQuantity : UITreeNodeWithDisplayRegion -> Int
parseQuantity node =
    findNodeByName node "quantity"
        |> Maybe.andThen getDisplayText
        |> Maybe.andThen String.toInt
        |> Maybe.withDefault 0


-- Parse planet resources
parsePlanetResources : UITreeNodeWithDisplayRegion -> List PlanetResource
parsePlanetResources windowNode =
    findNodesByType windowNode "PlanetResource"
        |> List.filterMap parseResourceFromNode


-- Parse cycle info
parseCycleInfo : UITreeNodeWithDisplayRegion -> Maybe CycleInfo
parseCycleInfo windowNode =
    findNodeByName windowNode "cycleInfo"
        |> Maybe.andThen parseCycleInfoFromNode


-- Parse cycle info from node
parseCycleInfoFromNode : UITreeNodeWithDisplayRegion -> Maybe CycleInfo
parseCycleInfoFromNode node =
    let
        currentCycle = parseCurrentCycle node
        totalCycles = parseTotalCycles node
        timeRemaining = parseTimeRemaining node
        nextCycleTime = parseTime node "nextCycleTime"
    in
    Just
        { currentCycle = currentCycle
        , totalCycles = totalCycles
        , timeRemaining = timeRemaining
        , nextCycleTime = nextCycleTime
        }


-- Parse current cycle
parseCurrentCycle : UITreeNodeWithDisplayRegion -> Int
parseCurrentCycle node =
    findNodeByName node "currentCycle"
        |> Maybe.andThen getDisplayText
        |> Maybe.andThen String.toInt
        |> Maybe.withDefault 1


-- Parse total cycles
parseTotalCycles : UITreeNodeWithDisplayRegion -> Int
parseTotalCycles node =
    findNodeByName node "totalCycles"
        |> Maybe.andThen getDisplayText
        |> Maybe.andThen String.toInt
        |> Maybe.withDefault 1


-- Parse time remaining
parseTimeRemaining : UITreeNodeWithDisplayRegion -> Int
parseTimeRemaining node =
    findNodeByName node "timeRemaining"
        |> Maybe.andThen getDisplayText
        |> Maybe.andThen String.toInt
        |> Maybe.withDefault 0


-- Helper functions

-- Find node by name
findNodeByName : UITreeNodeWithDisplayRegion -> String -> Maybe UITreeNodeWithDisplayRegion
findNodeByName rootNode name =
    -- This would need to be implemented based on the actual Sanderling UI tree structure
    Nothing


-- Find nodes by type
findNodesByType : UITreeNodeWithDisplayRegion -> String -> List UITreeNodeWithDisplayRegion
findNodesByType rootNode typeName =
    -- This would need to be implemented based on the actual Sanderling UI tree structure
    []


-- Get display text from node
getDisplayText : UITreeNodeWithDisplayRegion -> Maybe String
getDisplayText node =
    -- This would need to be implemented based on the actual Sanderling UI tree structure
    Nothing


-- Simple hash code for generating IDs
hashCode : UITreeNodeWithDisplayRegion -> Int
hashCode node =
    -- Simple hash based on position and type
    node.selfDisplayRegion.x + node.selfDisplayRegion.y * 1000