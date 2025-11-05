-- Integration of Planetary Interaction parsing into Sanderling
-- This shows how to add PI support to the existing ParseUserInterface module

module PIIntegration exposing (..)

-- Add this to the ParsedUserInterface type alias:
-- , planetaryInteractionWindows : List PlanetaryInteractionWindow

-- Add this to the parseUserInterfaceFromUITreeRoot function:
-- , planetaryInteractionWindows = parsePlanetaryInteractionWindowsFromUITreeRoot uiTree

-- Function to parse PI windows from UI tree root
parsePlanetaryInteractionWindowsFromUITreeRoot : UITreeNodeWithDisplayRegion -> List PlanetaryInteractionWindow
parsePlanetaryInteractionWindowsFromUITreeRoot uiTreeRoot =
    uiTreeRoot
        |> listDescendantsWithDisplayRegion
        |> List.filter isPlanetaryInteractionWindow
        |> List.filterMap parsePlanetaryInteractionWindow


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
            , "PlanetaryColony"
            ]
    in
    List.member typeName piWindowTypes


-- Simplified PI window type for integration
type alias PlanetaryInteractionWindow =
    { uiNode : UITreeNodeWithDisplayRegion
    , planetName : Maybe String
    , colonies : List PIColony
    , powerUsage : Maybe PowerUsage
    , cpuUsage : Maybe CpuUsage
    , facilities : List PIFacility
    , extractors : List PIExtractor
    , status : PIStatus
    }


type alias PIColony =
    { uiNode : UITreeNodeWithDisplayRegion
    , name : String
    , status : ColonyStatus
    }


type alias PowerUsage =
    { used : Int
    , total : Int
    , percentage : Float
    }


type alias CpuUsage =
    { used : Int
    , total : Int
    , percentage : Float
    }


type alias PIFacility =
    { uiNode : UITreeNodeWithDisplayRegion
    , facilityType : String
    , status : String
    , contents : List String
    }


type alias PIExtractor =
    { uiNode : UITreeNodeWithDisplayRegion
    , resourceType : String
    , extractionRate : Float
    , cycleTime : Int
    , isActive : Bool
    }


type ColonyStatus
    = ColonyActive
    | ColonyInactive
    | ColonyNeedsAttention


type PIStatus
    = PIActive
    | PIInactive
    | PIError


-- Parse planetary interaction window
parsePlanetaryInteractionWindow : UITreeNodeWithDisplayRegion -> Maybe PlanetaryInteractionWindow
parsePlanetaryInteractionWindow windowNode =
    let
        planetName = parsePlanetName windowNode
        colonies = parsePIColonies windowNode
        powerUsage = parsePowerUsage windowNode
        cpuUsage = parseCpuUsage windowNode
        facilities = parsePIFacilities windowNode
        extractors = parsePIExtractors windowNode
        status = parsePIStatus windowNode
    in
    Just
        { uiNode = windowNode
        , planetName = planetName
        , colonies = colonies
        , powerUsage = powerUsage
        , cpuUsage = cpuUsage
        , facilities = facilities
        , extractors = extractors
        , status = status
        }


-- Parse planet name
parsePlanetName : UITreeNodeWithDisplayRegion -> Maybe String
parsePlanetName windowNode =
    windowNode
        |> listDescendantsWithDisplayRegion
        |> List.filter (.uiNode >> .pythonObjectTypeName >> (==) "LabelCore")
        |> List.concatMap (.uiNode >> getAllContainedDisplayTexts)
        |> List.filter (String.contains "Planet")
        |> List.head


-- Parse PI colonies
parsePIColonies : UITreeNodeWithDisplayRegion -> List PIColony
parsePIColonies windowNode =
    windowNode
        |> listDescendantsWithDisplayRegion
        |> List.filter (.uiNode >> .pythonObjectTypeName >> String.contains "Colony")
        |> List.filterMap parsePIColony


-- Parse PI colony
parsePIColony : UITreeNodeWithDisplayRegion -> Maybe PIColony
parsePIColony colonyNode =
    let
        name = colonyNode.uiNode
            |> getAllContainedDisplayTexts
            |> List.head
            |> Maybe.withDefault "Unknown Colony"
        
        status = parseColonyStatusFromNode colonyNode
    in
    Just
        { uiNode = colonyNode
        , name = name
        , status = status
        }


-- Parse colony status from node
parseColonyStatusFromNode : UITreeNodeWithDisplayRegion -> ColonyStatus
parseColonyStatusFromNode node =
    let
        statusTexts = node.uiNode |> getAllContainedDisplayTexts
        hasActiveIndicator = statusTexts |> List.any (String.contains "Active")
        hasAttentionIndicator = statusTexts |> List.any (String.contains "Attention")
    in
    if hasAttentionIndicator then
        ColonyNeedsAttention
    else if hasActiveIndicator then
        ColonyActive
    else
        ColonyInactive


-- Parse power usage
parsePowerUsage : UITreeNodeWithDisplayRegion -> Maybe PowerUsage
parsePowerUsage windowNode =
    let
        powerTexts = windowNode
            |> listDescendantsWithDisplayRegion
            |> List.concatMap (.uiNode >> getAllContainedDisplayTexts)
            |> List.filter (String.contains "Power")
        
        powerUsageText = powerTexts
            |> List.filter (String.contains "/")
            |> List.head
    in
    case powerUsageText of
        Just text ->
            parsePowerUsageFromText text
        
        Nothing ->
            Nothing


-- Parse power usage from text
parsePowerUsageFromText : String -> Maybe PowerUsage
parsePowerUsageFromText text =
    let
        -- Extract numbers from text like "1500 / 2000 MW"
        numbers = text
            |> String.words
            |> List.filterMap String.toInt
    in
    case numbers of
        [used, total] ->
            let
                percentage = if total > 0 then toFloat used / toFloat total * 100 else 0
            in
            Just
                { used = used
                , total = total
                , percentage = percentage
                }
        
        _ ->
            Nothing


-- Parse CPU usage
parseCpuUsage : UITreeNodeWithDisplayRegion -> Maybe CpuUsage
parseCpuUsage windowNode =
    let
        cpuTexts = windowNode
            |> listDescendantsWithDisplayRegion
            |> List.concatMap (.uiNode >> getAllContainedDisplayTexts)
            |> List.filter (String.contains "CPU")
        
        cpuUsageText = cpuTexts
            |> List.filter (String.contains "/")
            |> List.head
    in
    case cpuUsageText of
        Just text ->
            parseCpuUsageFromText text
        
        Nothing ->
            Nothing


-- Parse CPU usage from text
parseCpuUsageFromText : String -> Maybe CpuUsage
parseCpuUsageFromText text =
    let
        -- Extract numbers from text like "750 / 1000 tf"
        numbers = text
            |> String.words
            |> List.filterMap String.toInt
    in
    case numbers of
        [used, total] ->
            let
                percentage = if total > 0 then toFloat used / toFloat total * 100 else 0
            in
            Just
                { used = used
                , total = total
                , percentage = percentage
                }
        
        _ ->
            Nothing


-- Parse PI facilities
parsePIFacilities : UITreeNodeWithDisplayRegion -> List PIFacility
parsePIFacilities windowNode =
    let
        facilityTypes = 
            [ "CommandCenter"
            , "Extractor"
            , "Processor"
            , "StorageUnit"
            , "Launchpad"
            ]
    in
    facilityTypes
        |> List.concatMap (\facilityType ->
            windowNode
                |> listDescendantsWithDisplayRegion
                |> List.filter (.uiNode >> .pythonObjectTypeName >> String.contains facilityType)
                |> List.map (parsePIFacility facilityType)
        )


-- Parse PI facility
parsePIFacility : String -> UITreeNodeWithDisplayRegion -> PIFacility
parsePIFacility facilityType facilityNode =
    let
        status = facilityNode.uiNode
            |> getAllContainedDisplayTexts
            |> List.filter (String.contains "Status")
            |> List.head
            |> Maybe.withDefault "Unknown"
        
        contents = facilityNode.uiNode
            |> getAllContainedDisplayTexts
            |> List.filter (\text -> 
                String.contains "units" text || 
                String.contains "m³" text ||
                String.contains "items" text
            )
    in
    { uiNode = facilityNode
    , facilityType = facilityType
    , status = status
    , contents = contents
    }


-- Parse PI extractors
parsePIExtractors : UITreeNodeWithDisplayRegion -> List PIExtractor
parsePIExtractors windowNode =
    windowNode
        |> listDescendantsWithDisplayRegion
        |> List.filter (.uiNode >> .pythonObjectTypeName >> String.contains "Extractor")
        |> List.filterMap parsePIExtractor


-- Parse PI extractor
parsePIExtractor : UITreeNodeWithDisplayRegion -> Maybe PIExtractor
parsePIExtractor extractorNode =
    let
        texts = extractorNode.uiNode |> getAllContainedDisplayTexts
        
        resourceType = texts
            |> List.filter (String.contains "Resource")
            |> List.head
            |> Maybe.withDefault "Unknown"
        
        extractionRateText = texts
            |> List.filter (String.contains "units/hour")
            |> List.head
        
        extractionRate = extractionRateText
            |> Maybe.andThen (String.words >> List.head)
            |> Maybe.andThen String.toFloat
            |> Maybe.withDefault 0.0
        
        cycleTimeText = texts
            |> List.filter (String.contains "hours")
            |> List.head
        
        cycleTime = cycleTimeText
            |> Maybe.andThen (String.words >> List.head)
            |> Maybe.andThen String.toInt
            |> Maybe.withDefault 24
        
        isActive = texts
            |> List.any (String.contains "Active")
    in
    Just
        { uiNode = extractorNode
        , resourceType = resourceType
        , extractionRate = extractionRate
        , cycleTime = cycleTime
        , isActive = isActive
        }


-- Parse PI status
parsePIStatus : UITreeNodeWithDisplayRegion -> PIStatus
parsePIStatus windowNode =
    let
        statusTexts = windowNode
            |> listDescendantsWithDisplayRegion
            |> List.concatMap (.uiNode >> getAllContainedDisplayTexts)
        
        hasError = statusTexts |> List.any (String.contains "Error")
        hasActive = statusTexts |> List.any (String.contains "Active")
    in
    if hasError then
        PIError
    else if hasActive then
        PIActive
    else
        PIInactive


-- Helper functions (these would need to be imported from the main ParseUserInterface module)

-- Placeholder for listDescendantsWithDisplayRegion
listDescendantsWithDisplayRegion : UITreeNodeWithDisplayRegion -> List UITreeNodeWithDisplayRegion
listDescendantsWithDisplayRegion node =
    -- This would be implemented using the actual Sanderling function
    []


-- Placeholder for getAllContainedDisplayTexts
getAllContainedDisplayTexts : EveOnline.MemoryReading.UITreeNode -> List String
getAllContainedDisplayTexts node =
    -- This would be implemented using the actual Sanderling function
    []


-- Placeholder types (these would be imported from the main module)
type alias UITreeNodeWithDisplayRegion =
    { uiNode : EveOnline.MemoryReading.UITreeNode
    , selfDisplayRegion : DisplayRegion
    , totalDisplayRegion : DisplayRegion
    }


type alias DisplayRegion =
    { x : Int
    , y : Int
    , width : Int
    , height : Int
    }


-- Placeholder module reference
module EveOnline.MemoryReading exposing (UITreeNode)

type alias UITreeNode =
    { pythonObjectTypeName : String
    }