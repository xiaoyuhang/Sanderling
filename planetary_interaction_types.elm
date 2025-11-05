-- Planetary Interaction (PI) data types for EVE Online
-- This module defines the data structures needed to represent planetary development status

module PlanetaryInteraction exposing (..)

import Dict
import Time


-- Main planetary interaction window
type alias PlanetaryInteractionWindow =
    { uiNode : UITreeNodeWithDisplayRegion
    , planetInfo : Maybe PlanetInfo
    , colonies : List Colony
    , commandCenter : Maybe CommandCenter
    , facilities : List Facility
    , extractors : List Extractor
    , processors : List Processor
    , storageUnits : List StorageUnit
    , launchpads : List Launchpad
    , links : List Link
    , routes : List Route
    , planetResources : List PlanetResource
    , cycleInfo : Maybe CycleInfo
    }


-- Planet information
type alias PlanetInfo =
    { name : String
    , planetType : PlanetType
    , securityStatus : Float
    , systemName : String
    , regionName : String
    }


-- Planet types in EVE Online
type PlanetType
    = Temperate
    | Barren
    | Oceanic
    | Ice
    | Gas
    | Lava
    | Storm
    | Plasma


-- Colony represents a single planetary colony
type alias Colony =
    { uiNode : UITreeNodeWithDisplayRegion
    , planetName : String
    , commandCenterLevel : Int
    , powerUsed : Int
    , powerTotal : Int
    , cpuUsed : Int
    , cpuTotal : Int
    , facilities : List Facility
    , lastUpdate : Maybe Time.Posix
    , status : ColonyStatus
    }


-- Colony status
type ColonyStatus
    = Active
    | Inactive
    | NeedsAttention
    | Extracting
    | Processing
    | Full


-- Base facility type
type alias Facility =
    { uiNode : UITreeNodeWithDisplayRegion
    , facilityId : String
    , facilityType : FacilityType
    , position : Location2d
    , powerConsumption : Int
    , cpuConsumption : Int
    , status : FacilityStatus
    , contents : List ItemStack
    }


-- Facility types
type FacilityType
    = CommandCenterFacility
    | ExtractorFacility
    | ProcessorFacility StorageUnitFacility
    | LaunchpadFacility
    | LinkFacility


-- Facility status
type FacilityStatus
    = FacilityActive
    | FacilityInactive
    | FacilityFull
    | FacilityEmpty
    | FacilityError


-- Command Center
type alias CommandCenter =
    { facility : Facility
    , level : Int
    , upgradeAvailable : Bool
    }


-- Extractor for harvesting planetary resources
type alias Extractor =
    { facility : Facility
    , extractorType : ExtractorType
    , targetResource : Maybe PlanetResource
    , extractionRate : Float
    , cycleTime : Int
    , heads : List ExtractorHead
    , program : Maybe ExtractionProgram
    }


-- Extractor types
type ExtractorType
    = BasicExtractor
    | AdvancedExtractor


-- Extractor head
type alias ExtractorHead =
    { position : Location2d
    , resourceDensity : Float
    , isActive : Bool
    }


-- Extraction program
type alias ExtractionProgram =
    { startTime : Time.Posix
    , duration : Int
    , cycles : List ExtractionCycle
    }


-- Extraction cycle
type alias ExtractionCycle =
    { cycleNumber : Int
    , startTime : Time.Posix
    , endTime : Time.Posix
    , extractionRate : Float
    , status : CycleStatus
    }


-- Cycle status
type CycleStatus
    = CycleActive
    | CycleCompleted
    | CyclePending


-- Processor for manufacturing
type alias Processor =
    { facility : Facility
    , processorTier : ProcessorTier
    , schematic : Maybe Schematic
    , inputMaterials : List ItemStack
    , outputProducts : List ItemStack
    , cyclesRemaining : Int
    , isRunning : Bool
    }


-- Processor tiers
type ProcessorTier
    = BasicProcessor
    | AdvancedProcessor
    | HighTechProcessor


-- Manufacturing schematic
type alias Schematic =
    { schematicId : String
    , name : String
    , inputs : List MaterialRequirement
    , outputs : List MaterialRequirement
    , cycleTime : Int
    }


-- Material requirement
type alias MaterialRequirement =
    { materialType : String
    , quantity : Int
    }


-- Storage unit
type alias StorageUnit =
    { facility : Facility
    , capacity : Int
    , used : Int
    , contents : List ItemStack
    }


-- Launchpad for importing/exporting
type alias Launchpad =
    { facility : Facility
    , capacity : Int
    , used : Int
    , contents : List ItemStack
    , pendingTransfers : List Transfer
    }


-- Transfer (import/export)
type alias Transfer =
    { transferId : String
    , transferType : TransferType
    , items : List ItemStack
    , destination : String
    , estimatedTime : Maybe Time.Posix
    , status : TransferStatus
    }


-- Transfer types
type TransferType
    = Import
    | Export


-- Transfer status
type TransferStatus
    = TransferPending
    | TransferInProgress
    | TransferCompleted
    | TransferFailed


-- Link between facilities
type alias Link =
    { uiNode : UITreeNodeWithDisplayRegion
    , linkId : String
    , fromFacility : String
    , toFacility : String
    , length : Float
    , powerConsumption : Int
    , cpuConsumption : Int
    , isActive : Bool
    }


-- Route for moving materials
type alias Route =
    { routeId : String
    , sourceFacility : String
    , destinationFacility : String
    , materialType : String
    , quantity : Int
    , isActive : Bool
    }


-- Planet resource
type alias PlanetResource =
    { resourceType : ResourceType
    , density : Float
    , position : Location2d
    , extractionRate : Float
    }


-- Resource types
type ResourceType
    = AqueousLiquids
    | AutootropicBacteria
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
    | Planktic
    | ReactiveGas
    | SuspendedPlasma


-- Item stack
type alias ItemStack =
    { itemType : String
    , quantity : Int
    , volume : Float
    }


-- Cycle information
type alias CycleInfo =
    { currentCycle : Int
    , totalCycles : Int
    , timeRemaining : Int
    , nextCycleTime : Maybe Time.Posix
    }


-- Location in 2D space
type alias Location2d =
    { x : Float
    , y : Float
    }


-- UI Tree Node (placeholder - should match the actual Sanderling type)
type alias UITreeNodeWithDisplayRegion =
    { uiNode : UITreeNode
    , selfDisplayRegion : DisplayRegion
    , totalDisplayRegion : DisplayRegion
    }


type alias UITreeNode =
    { pythonObjectTypeName : String
    }


type alias DisplayRegion =
    { x : Int
    , y : Int
    , width : Int
    , height : Int
    }