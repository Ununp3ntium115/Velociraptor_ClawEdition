# Claude Agents for Velociraptor Setup Scripts

This directory contains specialized Claude agents that provide expert guidance across different domains of the project.

## Available Agents

### 🔍 macos-qa-agent
**Purpose**: Holistic Quality Gate validation for macOS features  
**When to Use**: When features have passed testing and need quality validation before UAT  
**Expertise**:
- Workflow integrity and regression testing
- UI consistency (SwiftUI patterns, AppKit integration)
- Performance validation for DFIR workflows
- Operator-friendly error handling
- macOS-specific integrations (window lifecycle, focus, accessibility)

**Example Usage**:
```
The Emergency Mode feature has passed all tests. 
Can you perform QA validation to check if it's ready for UAT?
```

**Output**: Approve/reject decision with concrete quality assessment across 5 dimensions

---

### 🛡️ velociraptor-dfir-expert
**Purpose**: DFIR methodology and Velociraptor platform expertise  
**When to Use**: When you need guidance on digital forensics, incident response, or Velociraptor-specific features  
**Expertise**:
- Digital forensics and incident response best practices
- Velociraptor architecture and features
- Artifact development and VQL queries
- DFIR workflow optimization
- Evidence handling and chain of custody

**Example Usage**:
```
How should we structure the incident response workflow for 
ransomware detection using Velociraptor artifacts?
```

---

### 🎨 ui-ux-engineer
**Purpose**: User interface and user experience design  
**When to Use**: When designing or improving UI, optimizing workflows, or enhancing accessibility  
**Expertise**:
- User experience design and journey mapping
- Interface design principles and visual hierarchy
- Accessibility standards (WCAG 2.1 AA)
- Design systems and component libraries
- Enterprise software UX patterns
- Security tool interface design

**Example Usage**:
```
The configuration wizard feels clunky. Can you help improve 
the user flow and make it more intuitive?
```

---

### 💻 powershell-expert
**Purpose**: PowerShell development and automation  
**When to Use**: When writing, debugging, or optimizing PowerShell scripts  
**Expertise**:
- PowerShell scripting best practices
- Module development and distribution
- Cross-platform PowerShell (Core)
- Error handling and debugging
- Performance optimization
- Windows automation and system administration

**Example Usage**:
```
I need to create a PowerShell module that handles certificate 
management for Velociraptor deployments.
```

---

### 🔧 dfir-code-engineer
**Purpose**: Code engineering for DFIR tools  
**When to Use**: When implementing DFIR-specific features or optimizing forensic data handling  
**Expertise**:
- DFIR tool development
- Forensic data processing and analysis
- Performance optimization for large datasets
- Evidence integrity and validation
- Integration with forensic frameworks

**Example Usage**:
```
How can we optimize the artifact collection process for 
systems with millions of files?
```

---

### 📊 velociraptor-project-coordinator
**Purpose**: Project management and coordination  
**When to Use**: When planning features, managing releases, or coordinating development efforts  
**Expertise**:
- Project planning and roadmap management
- Release coordination and versioning
- Documentation and communication
- Quality assurance coordination
- Stakeholder management

**Example Usage**:
```
We're planning the v5.1 release. Can you help prioritize 
features and create a release checklist?
```

---

### 🔍 velociraptor-vql-engineer
**Purpose**: VQL (Velociraptor Query Language) development  
**When to Use**: When writing, optimizing, or debugging VQL queries and artifacts  
**Expertise**:
- VQL syntax and best practices
- Artifact development
- Query optimization
- Plugin development
- Custom data collection

**Example Usage**:
```
I need to create a VQL artifact that detects persistence 
mechanisms across Windows, Linux, and macOS.
```

---

## Agent Selection Guide

Choose the right agent based on your task:

| Task Type | Recommended Agent |
|-----------|------------------|
| Quality validation before UAT | **macos-qa-agent** |
| UI/UX design and improvement | **ui-ux-engineer** |
| PowerShell script development | **powershell-expert** |
| DFIR methodology questions | **velociraptor-dfir-expert** |
| Code implementation for DFIR | **dfir-code-engineer** |
| VQL query development | **velociraptor-vql-engineer** |
| Project planning and releases | **velociraptor-project-coordinator** |

## How to Use Agents

### In Claude Code Chat

Simply mention what you need help with, and Claude will automatically select the appropriate agent:

```
user: "Can you validate the quality of the new Emergency Mode feature?"
→ Uses: macos-qa-agent

user: "How do I write a PowerShell function to download artifacts?"
→ Uses: powershell-expert

user: "The wizard UI needs better navigation flow"
→ Uses: ui-ux-engineer
```

### Explicit Agent Invocation

You can also explicitly request a specific agent:

```
Use the macos-qa-agent to validate the incident response feature
```

### Agent Workflow

1. **Development** → Create feature
2. **Testing** → Unit/Integration tests (pass)
3. **QA Validation** → macos-qa-agent (approve/reject)
4. **UAT** → User acceptance testing
5. **Release** → Production deployment

## Agent Collaboration

Agents can work together on complex tasks:

```
Example: New DFIR Feature Development

1. velociraptor-dfir-expert
   → Define requirements and methodology

2. dfir-code-engineer
   → Implement the feature

3. ui-ux-engineer
   → Design the user interface

4. powershell-expert
   → Create PowerShell integration

5. macos-qa-agent
   → Validate quality before UAT
```

## Adding New Agents

To add a new specialized agent:

1. Create `[agent-name].md` in this directory
2. Follow the existing agent structure:
   ```markdown
   ---
   name: agent-name
   description: Brief description with examples
   model: inherit
   ---
   
   [Agent system prompt and instructions]
   ```
3. Update this README with the new agent
4. Add to `.claude/settings.local.json` if needed

## Best Practices

1. **Use the right agent** - Choose based on expertise needed
2. **Provide context** - Give agents relevant background information
3. **Be specific** - Clear requests get better results
4. **Iterate** - Refine based on agent feedback
5. **Validate output** - Always review agent suggestions before implementing

## Resources

- Agent definitions: `.claude/agents/*.md`
- Claude settings: `.claude/settings.local.json`
- Main documentation: `CLAUDE.md` (project root)

---

**Note**: These agents are specialized assistants that provide expert guidance within their domains. They help maintain high quality standards and best practices across the Velociraptor Setup Scripts project.
