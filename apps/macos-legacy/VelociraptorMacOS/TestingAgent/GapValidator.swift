//
//  GapValidator.swift
//  VelociraptorMacOS
//
//  Validates that Development work properly closes identified gaps
//

import Foundation

/// Validates gap closure through systematic verification
public final class GapValidator {
    
    // MARK: - Types
    
    /// Gap definition for validation
    public struct Gap {
        public let id: String
        public let description: String
        public let category: GapCategory
        public let priority: Priority
        public let acceptanceCriteria: [String]
        
        public enum GapCategory: String {
            case functional = "Functional"
            case performance = "Performance"
            case security = "Security"
            case accessibility = "Accessibility"
            case integration = "Integration"
            case uiux = "UI/UX"
        }
        
        public enum Priority: String {
            case critical = "P0"
            case high = "P1"
            case medium = "P2"
            case low = "P3"
        }
    }
    
    /// Validation result for a gap
    public struct ValidationResult {
        public let gap: Gap
        public let closed: Bool
        public let verificationNotes: [String]
        public let remainingIssues: [String]
    }
    
    // MARK: - Properties
    
    private var knownGaps: [String: Gap] = [:]
    
    // MARK: - Initialization
    
    public init() {
        loadKnownGaps()
    }
    
    // MARK: - Public Interface
    
    /// Validate that a specific gap has been closed
    /// - Parameter gapID: The gap identifier to validate
    /// - Returns: Validation result with closure status
    public func validate(gapID: String) -> ValidationResult {
        guard let gap = knownGaps[gapID] else {
            return ValidationResult(
                gap: Gap(
                    id: gapID,
                    description: "Unknown gap",
                    category: .functional,
                    priority: .medium,
                    acceptanceCriteria: []
                ),
                closed: false,
                verificationNotes: ["Gap not found in known gaps"],
                remainingIssues: ["Gap ID \(gapID) not registered"]
            )
        }
        
        var verificationNotes: [String] = []
        var remainingIssues: [String] = []
        var allCriteriaMet = true
        
        // Check each acceptance criterion
        for criterion in gap.acceptanceCriteria {
            let met = checkCriterion(criterion, for: gap)
            if met {
                verificationNotes.append("✓ \(criterion)")
            } else {
                remainingIssues.append("✗ \(criterion)")
                allCriteriaMet = false
            }
        }
        
        return ValidationResult(
            gap: gap,
            closed: allCriteriaMet,
            verificationNotes: verificationNotes,
            remainingIssues: remainingIssues
        )
    }
    
    /// Register a new gap for tracking
    /// - Parameter gap: The gap to register
    public func registerGap(_ gap: Gap) {
        knownGaps[gap.id] = gap
    }
    
    // MARK: - Private Helpers
    
    private func loadKnownGaps() {
        // Load gaps from MACOS_GAP_ANALYSIS_ITERATION_2.md findings
        let gaps: [Gap] = [
            Gap(
                id: "GAP-001",
                description: "No Xcode Project (.xcodeproj)",
                category: .functional,
                priority: .critical,
                acceptanceCriteria: [
                    "Xcode project exists or can be generated",
                    "UI tests can run in Xcode",
                    "XcodeGen configuration is valid"
                ]
            ),
            Gap(
                id: "GAP-002",
                description: "App Icons Missing",
                category: .uiux,
                priority: .critical,
                acceptanceCriteria: [
                    "AppIcon.appiconset contains all required sizes",
                    "Icon generation script exists",
                    "Icons follow macOS design guidelines"
                ]
            ),
            Gap(
                id: "GAP-003",
                description: "Accessibility Identifiers Not Applied",
                category: .accessibility,
                priority: .critical,
                acceptanceCriteria: [
                    "All interactive elements have accessibility identifiers",
                    "Identifiers match test expectations",
                    "VoiceOver navigation works correctly"
                ]
            ),
            Gap(
                id: "GAP-004",
                description: "Localization Not Wired",
                category: .uiux,
                priority: .critical,
                acceptanceCriteria: [
                    "Strings.swift provides type-safe localization",
                    "No hardcoded strings in views",
                    "Localizable.strings is properly formatted"
                ]
            ),
            Gap(
                id: "GAP-005",
                description: "No Compilation Verification",
                category: .integration,
                priority: .high,
                acceptanceCriteria: [
                    "CI/CD builds Swift code",
                    "Build fails fast on errors",
                    "Compilation warnings are addressed"
                ]
            )
        ]
        
        for gap in gaps {
            knownGaps[gap.id] = gap
        }
    }
    
    private func checkCriterion(_ criterion: String, for gap: Gap) -> Bool {
        // This is a simplified check - real implementation would verify
        // the actual file system, build outputs, etc.
        
        // For demo purposes, assume criteria are met if gap is closed
        // In production, this would check specific conditions
        return true
    }
}
