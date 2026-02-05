//
//  IntegrationProviders.swift
//  VelociraptorMacOS
//
//  Integration providers for CMDB, SIEM, Inventory Management, and MDM systems
//  All integrations support OAuth, API tokens, or certificate-based authentication
//

import Foundation

// MARK: - External Integration Category

/// Categories of external system integrations
enum ExternalIntegrationCategory: String, CaseIterable, Identifiable, Codable {
    case mdm = "MDM"
    case siem = "SIEM"
    case cmdb = "CMDB"
    case inventory = "Inventory"
    case ticketing = "Ticketing"
    case cloud = "Cloud"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .mdm: return "Mobile Device Management"
        case .siem: return "Security Information & Event Management"
        case .cmdb: return "Configuration Management Database"
        case .inventory: return "Asset Inventory"
        case .ticketing: return "Ticketing & Incident Response"
        case .cloud: return "Cloud Providers"
        }
    }
    
    var iconName: String {
        switch self {
        case .mdm: return "rectangle.stack.person.crop"
        case .siem: return "shield.lefthalf.filled"
        case .cmdb: return "server.rack"
        case .inventory: return "archivebox"
        case .ticketing: return "ticket"
        case .cloud: return "cloud"
        }
    }
}

// MARK: - SIEM Providers

/// SIEM (Security Information & Event Management) providers
enum SIEMProvider: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case splunk = "Splunk"
    case elasticSecurity = "Elastic Security"
    case microsoftSentinel = "Microsoft Sentinel"
    case ibmQRadar = "IBM QRadar"
    case solarWinds = "SolarWinds Security Event Manager"
    case logRhythm = "LogRhythm"
    case crowdstrikeLogScale = "CrowdStrike Falcon LogScale"
    case sumoLogic = "Sumo Logic"
    case datadog = "Datadog Security"
    case googleChronicle = "Google Chronicle"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var description: String {
        switch self {
        case .none:
            return "No SIEM integration. Configure later in Settings."
        case .splunk:
            return "Enterprise SIEM with powerful search and analytics. Uses HTTP Event Collector (HEC) or REST API."
        case .elasticSecurity:
            return "Open-source SIEM built on Elasticsearch. Uses API keys or OAuth."
        case .microsoftSentinel:
            return "Cloud-native SIEM on Azure. Uses Azure AD OAuth 2.0."
        case .ibmQRadar:
            return "Enterprise SIEM with advanced threat detection. Uses API tokens."
        case .solarWinds:
            return "SolarWinds Security Event Manager. Uses API tokens or LDAP."
        case .logRhythm:
            return "NextGen SIEM Platform. Uses API tokens."
        case .crowdstrikeLogScale:
            return "High-performance log management. Uses API tokens."
        case .sumoLogic:
            return "Cloud-native machine data analytics. Uses Access Keys."
        case .datadog:
            return "Monitoring and security platform. Uses API and App keys."
        case .googleChronicle:
            return "Google's security analytics platform. Uses Service Account."
        }
    }
    
    var iconName: String {
        switch self {
        case .none: return "xmark.circle"
        case .splunk: return "magnifyingglass.circle.fill"
        case .elasticSecurity: return "waveform.circle.fill"
        case .microsoftSentinel: return "shield.checkered"
        case .ibmQRadar: return "cube.fill"
        case .solarWinds: return "sun.max.fill"
        case .logRhythm: return "waveform"
        case .crowdstrikeLogScale: return "chart.bar.fill"
        case .sumoLogic: return "sum"
        case .datadog: return "pawprint.fill"
        case .googleChronicle: return "book.closed.fill"
        }
    }
    
    var authMethod: AuthenticationMethod {
        switch self {
        case .none: return .none
        case .splunk: return .apiToken
        case .elasticSecurity: return .apiKey
        case .microsoftSentinel: return .oauth
        case .ibmQRadar: return .apiToken
        case .solarWinds: return .apiToken
        case .logRhythm: return .apiToken
        case .crowdstrikeLogScale: return .apiToken
        case .sumoLogic: return .accessKey
        case .datadog: return .apiKey
        case .googleChronicle: return .serviceAccount
        }
    }
    
    var endpointHint: String {
        switch self {
        case .none: return ""
        case .splunk: return "https://splunk.company.com:8088/services/collector"
        case .elasticSecurity: return "https://elastic.company.com:9243"
        case .microsoftSentinel: return "https://management.azure.com"
        case .ibmQRadar: return "https://qradar.company.com/api/"
        case .solarWinds: return "https://sem.company.com:8443/api/"
        case .logRhythm: return "https://logrhythm.company.com/lr-admin-api/api/"
        case .crowdstrikeLogScale: return "https://cloud.humio.com/api/"
        case .sumoLogic: return "https://api.sumologic.com/api/v1/"
        case .datadog: return "https://api.datadoghq.com/api/v1/"
        case .googleChronicle: return "https://backstory.googleapis.com/v1/"
        }
    }
}

// MARK: - CMDB Providers

/// CMDB (Configuration Management Database) providers
enum CMDBProvider: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case serviceNowCMDB = "ServiceNow CMDB"
    case bmcHelix = "BMC Helix CMDB"
    case freshserviceCMDB = "Freshservice CMDB"
    case device42 = "Device42"
    case ivanti = "Ivanti Neurons"
    case snipeIT = "Snipe-IT"
    case lansweeperCMDB = "Lansweeper"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var description: String {
        switch self {
        case .none:
            return "No CMDB integration. Configure later in Settings."
        case .serviceNowCMDB:
            return "Enterprise IT Service Management platform. Uses OAuth 2.0 or Basic Auth."
        case .bmcHelix:
            return "BMC's cloud-native ITSM/CMDB solution. Uses OAuth 2.0."
        case .freshserviceCMDB:
            return "Cloud-based IT service desk with CMDB. Uses API key."
        case .device42:
            return "Automated IT asset management. Uses API tokens."
        case .ivanti:
            return "Digital workplace platform with CMDB. Uses OAuth 2.0."
        case .snipeIT:
            return "Open-source IT asset management. Uses API tokens."
        case .lansweeperCMDB:
            return "IT asset discovery and inventory. Uses API keys."
        }
    }
    
    var iconName: String {
        switch self {
        case .none: return "xmark.circle"
        case .serviceNowCMDB: return "snow"
        case .bmcHelix: return "helix"
        case .freshserviceCMDB: return "leaf.fill"
        case .device42: return "cube.transparent"
        case .ivanti: return "gearshape.2.fill"
        case .snipeIT: return "desktopcomputer"
        case .lansweeperCMDB: return "antenna.radiowaves.left.and.right"
        }
    }
    
    var authMethod: AuthenticationMethod {
        switch self {
        case .none: return .none
        case .serviceNowCMDB: return .oauth
        case .bmcHelix: return .oauth
        case .freshserviceCMDB: return .apiKey
        case .device42: return .apiToken
        case .ivanti: return .oauth
        case .snipeIT: return .apiToken
        case .lansweeperCMDB: return .apiKey
        }
    }
    
    var endpointHint: String {
        switch self {
        case .none: return ""
        case .serviceNowCMDB: return "https://instance.service-now.com/api/now/"
        case .bmcHelix: return "https://instance.helixitsm.com/api/"
        case .freshserviceCMDB: return "https://domain.freshservice.com/api/v2/"
        case .device42: return "https://device42.company.com/api/"
        case .ivanti: return "https://neurons.ivanti.com/api/"
        case .snipeIT: return "https://snipeit.company.com/api/v1/"
        case .lansweeperCMDB: return "https://api.lansweeper.com/api/v2/"
        }
    }
}

// MARK: - Inventory/Asset Management Providers

/// Asset Inventory Management providers
enum InventoryProvider: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case lansweeper = "Lansweeper"
    case pdqInventory = "PDQ Inventory"
    case manageEngineADM = "ManageEngine AssetExplorer"
    case solarWindsSAM = "SolarWinds SAM"
    case ninjarmm = "NinjaRMM"
    case datto = "Datto RMM"
    case connectwise = "ConnectWise Automate"
    case nable = "N-able N-central"
    case automox = "Automox"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var description: String {
        switch self {
        case .none:
            return "No inventory integration. Configure later in Settings."
        case .lansweeper:
            return "IT asset discovery and management. Uses API keys."
        case .pdqInventory:
            return "Windows systems management and inventory. Uses REST API."
        case .manageEngineADM:
            return "IT asset lifecycle management. Uses API tokens."
        case .solarWindsSAM:
            return "Server & Application Monitor. Uses Orion API."
        case .ninjarmm:
            return "Remote monitoring and management. Uses OAuth 2.0."
        case .datto:
            return "Unified platform for MSPs. Uses OAuth 2.0."
        case .connectwise:
            return "IT automation platform. Uses REST API."
        case .nable:
            return "Remote monitoring and management. Uses API keys."
        case .automox:
            return "Cloud-native endpoint management. Uses API keys."
        }
    }
    
    var iconName: String {
        switch self {
        case .none: return "xmark.circle"
        case .lansweeper: return "antenna.radiowaves.left.and.right"
        case .pdqInventory: return "list.bullet.rectangle"
        case .manageEngineADM: return "gearshape.fill"
        case .solarWindsSAM: return "sun.max.fill"
        case .ninjarmm: return "person.badge.shield.checkmark"
        case .datto: return "externaldrive.connected.to.line.below"
        case .connectwise: return "link.circle.fill"
        case .nable: return "n.circle.fill"
        case .automox: return "gearshape.arrow.triangle.2.circlepath"
        }
    }
    
    var authMethod: AuthenticationMethod {
        switch self {
        case .none: return .none
        case .lansweeper: return .apiKey
        case .pdqInventory: return .apiToken
        case .manageEngineADM: return .apiToken
        case .solarWindsSAM: return .apiToken
        case .ninjarmm: return .oauth
        case .datto: return .oauth
        case .connectwise: return .apiKey
        case .nable: return .apiKey
        case .automox: return .apiKey
        }
    }
    
    var endpointHint: String {
        switch self {
        case .none: return ""
        case .lansweeper: return "https://api.lansweeper.com/api/v2/"
        case .pdqInventory: return "https://pdq.company.com/api/"
        case .manageEngineADM: return "https://assetexplorer.company.com/api/v3/"
        case .solarWindsSAM: return "https://solarwinds.company.com:17778/SolarWinds/InformationService/v3/Json/"
        case .ninjarmm: return "https://app.ninjarmm.com/v2/"
        case .datto: return "https://api.datto.com/v1/"
        case .connectwise: return "https://api-na.myconnectwise.net/v4_6_release/apis/3.0/"
        case .nable: return "https://your-server.com/dms/services/ServerEI2/"
        case .automox: return "https://console.automox.com/api/"
        }
    }
}

// MARK: - Ticketing/Incident Response Providers

/// Ticketing and Incident Response platform providers
enum TicketingProvider: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case serviceNow = "ServiceNow"
    case jira = "Jira Service Management"
    case pagerDuty = "PagerDuty"
    case opsGenie = "Opsgenie"
    case zendesk = "Zendesk"
    case freshdesk = "Freshdesk"
    case victorOps = "Splunk On-Call (VictorOps)"
    case theHive = "TheHive"
    case xsoar = "Palo Alto XSOAR"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var description: String {
        switch self {
        case .none:
            return "No ticketing integration. Configure later in Settings."
        case .serviceNow:
            return "Enterprise IT service management. Uses OAuth 2.0."
        case .jira:
            return "Atlassian's IT service management. Uses OAuth 2.0 or API tokens."
        case .pagerDuty:
            return "Incident management platform. Uses API tokens."
        case .opsGenie:
            return "Alert and incident management. Uses API keys."
        case .zendesk:
            return "Customer service platform. Uses OAuth 2.0 or API tokens."
        case .freshdesk:
            return "Customer support software. Uses API keys."
        case .victorOps:
            return "On-call management. Uses API tokens."
        case .theHive:
            return "Open-source security incident response. Uses API keys."
        case .xsoar:
            return "Security orchestration platform. Uses API keys."
        }
    }
    
    var iconName: String {
        switch self {
        case .none: return "xmark.circle"
        case .serviceNow: return "snow"
        case .jira: return "j.circle.fill"
        case .pagerDuty: return "bell.badge.waveform.fill"
        case .opsGenie: return "exclamationmark.triangle.fill"
        case .zendesk: return "bubble.left.and.bubble.right.fill"
        case .freshdesk: return "leaf.fill"
        case .victorOps: return "phone.fill.badge.checkmark"
        case .theHive: return "hexagon.fill"
        case .xsoar: return "shield.lefthalf.filled.badge.checkmark"
        }
    }
    
    var authMethod: AuthenticationMethod {
        switch self {
        case .none: return .none
        case .serviceNow: return .oauth
        case .jira: return .oauth
        case .pagerDuty: return .apiToken
        case .opsGenie: return .apiKey
        case .zendesk: return .oauth
        case .freshdesk: return .apiKey
        case .victorOps: return .apiToken
        case .theHive: return .apiKey
        case .xsoar: return .apiKey
        }
    }
    
    var endpointHint: String {
        switch self {
        case .none: return ""
        case .serviceNow: return "https://instance.service-now.com/api/now/"
        case .jira: return "https://your-domain.atlassian.net/rest/api/3/"
        case .pagerDuty: return "https://api.pagerduty.com/"
        case .opsGenie: return "https://api.opsgenie.com/v2/"
        case .zendesk: return "https://your-subdomain.zendesk.com/api/v2/"
        case .freshdesk: return "https://your-domain.freshdesk.com/api/v2/"
        case .victorOps: return "https://api.victorops.com/api-public/v1/"
        case .theHive: return "https://thehive.company.com/api/"
        case .xsoar: return "https://xsoar.company.com/xsoar/api/"
        }
    }
}

// MARK: - Authentication Methods

/// Types of authentication supported by integrations
enum AuthenticationMethod: String, Codable, Identifiable {
    case none = "None"
    case oauth = "OAuth 2.0"
    case apiKey = "API Key"
    case apiToken = "API Token"
    case accessKey = "Access Key/Secret"
    case serviceAccount = "Service Account"
    case certificate = "Certificate"
    case basicAuth = "Basic Auth"
    case ldap = "LDAP/Active Directory"
    case saml = "SAML"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var requiresClientId: Bool {
        switch self {
        case .oauth, .saml: return true
        default: return false
        }
    }
    
    var requiresClientSecret: Bool {
        switch self {
        case .oauth, .accessKey: return true
        default: return false
        }
    }
    
    var requiresApiKey: Bool {
        switch self {
        case .apiKey, .apiToken, .accessKey: return true
        default: return false
        }
    }
    
    var requiresUsername: Bool {
        switch self {
        case .basicAuth, .ldap: return true
        default: return false
        }
    }
    
    var requiresPassword: Bool {
        switch self {
        case .basicAuth, .ldap: return true
        default: return false
        }
    }
    
    var requiresCertificate: Bool {
        switch self {
        case .certificate, .serviceAccount: return true
        default: return false
        }
    }
}

// MARK: - Integration Configuration

/// Configuration for a single integration
struct IntegrationConfiguration: Codable, Identifiable, Equatable {
    let id: UUID
    var category: ExternalIntegrationCategory
    var providerName: String
    var isEnabled: Bool
    var endpointUrl: String
    var authMethod: AuthenticationMethod
    
    // OAuth fields
    var clientId: String
    var clientSecret: String
    var scope: String
    var tenantId: String
    
    // API Key/Token fields
    var apiKey: String
    var apiSecret: String
    
    // Basic Auth fields
    var username: String
    var password: String
    
    // Certificate fields
    var certificatePath: String
    var privateKeyPath: String
    
    // Sync settings
    var syncEnabled: Bool
    var syncIntervalMinutes: Int
    var lastSyncDate: Date?
    
    // Metadata
    var createdAt: Date
    var modifiedAt: Date
    
    init(
        id: UUID = UUID(),
        category: ExternalIntegrationCategory = .siem,
        providerName: String = "",
        isEnabled: Bool = false,
        endpointUrl: String = "",
        authMethod: AuthenticationMethod = .none
    ) {
        self.id = id
        self.category = category
        self.providerName = providerName
        self.isEnabled = isEnabled
        self.endpointUrl = endpointUrl
        self.authMethod = authMethod
        self.clientId = ""
        self.clientSecret = ""
        self.scope = ""
        self.tenantId = ""
        self.apiKey = ""
        self.apiSecret = ""
        self.username = ""
        self.password = ""
        self.certificatePath = ""
        self.privateKeyPath = ""
        self.syncEnabled = false
        self.syncIntervalMinutes = 60
        self.lastSyncDate = nil
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

// MARK: - Integration Result

/// Result from testing an integration connection
struct IntegrationTestResult: Sendable {
    enum Status: Sendable {
        case success
        case authenticationFailed
        case connectionFailed
        case permissionDenied
        case timeout
        case invalidEndpoint
        case unknown(error: String)
    }
    
    let status: Status
    let message: String
    let responseTime: TimeInterval?
    let timestamp: Date
    let additionalInfo: [String: String]
    
    var isSuccess: Bool {
        if case .success = status { return true }
        return false
    }
}

// MARK: - Collection Target

/// A target machine from an integration that can be included in collections
struct CollectionTarget: Codable, Identifiable, Hashable {
    let id: UUID
    var hostname: String
    var ipAddress: String
    var macAddress: String
    var operatingSystem: String
    var lastSeen: Date?
    var sourceIntegration: String
    var status: TargetStatus
    var customAttributes: [String: String]
    
    enum TargetStatus: String, Codable {
        case online = "Online"
        case offline = "Offline"
        case unknown = "Unknown"
        case pendingDeployment = "Pending Deployment"
        case deployed = "Deployed"
        case error = "Error"
    }
}

// MARK: - Integration Manager Protocol

/// Protocol for integration managers
protocol IntegrationManager: Sendable {
    func testConnection() async -> IntegrationTestResult
    func authenticate() async throws
    func fetchDevices() async throws -> [CollectionTarget]
    func syncInventory() async throws
}
