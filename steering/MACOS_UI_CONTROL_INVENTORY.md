# macOS UI Control Inventory (UCI)

**Document Version**: 1.0  
**Analysis Date**: January 23, 2026  
**Purpose**: Complete inventory of all UI controls requiring macOS implementation

---

## 1. VelociraptorGUI.ps1 - Configuration Wizard

### 1.1 Main Window Controls

| Control ID | Windows Type | SwiftUI Equivalent | Selector Strategy | Preconditions | Expected Outcome | Evidence | Cleanup |
|------------|-------------|-------------------|-------------------|---------------|------------------|----------|---------|
| `MainForm` | Form | WindowGroup/Window | `window("Velociraptor")` | App launched | Window displays | Screenshot | Close window |
| `HeaderPanel` | Panel | VStack/Header | `staticText("VELOCIRAPTOR")` | Window visible | Header shows branding | Screenshot | None |
| `ContentPanel` | Panel | ScrollView | `scrollView.firstMatch` | Window visible | Content area scrollable | Scroll test | None |
| `ButtonPanel` | Panel | HStack | `group("Navigation")` | Window visible | Buttons visible | Screenshot | None |

### 1.2 Navigation Controls

| Control ID | Windows Type | SwiftUI Equivalent | AutomationId | Action | Expected Result | Evidence Path |
|------------|-------------|-------------------|--------------|--------|-----------------|---------------|
| `BackButton` | Button | Button("Back") | `btn_back` | Tap | Previous step | artifacts/{run}/back_nav.png |
| `NextButton` | Button | Button("Next") | `btn_next` | Tap | Next step | artifacts/{run}/next_nav.png |
| `CancelButton` | Button | Button("Cancel") | `btn_cancel` | Tap | Confirmation dialog | artifacts/{run}/cancel_confirm.png |

### 1.3 Step 1 - Welcome

| Control ID | Windows Type | SwiftUI Equivalent | AutomationId | Validation |
|------------|-------------|-------------------|--------------|------------|
| `TitleLabel` | Label | Text("Welcome...") | `lbl_welcome_title` | Text visible |
| `WelcomeLabel` | Label | Text(instructions) | `lbl_welcome_content` | Text readable |

### 1.4 Step 2 - Deployment Type Selection

| Control ID | Windows Type | SwiftUI Equivalent | AutomationId | State | Validation |
|------------|-------------|-------------------|--------------|-------|------------|
| `ServerRadio` | RadioButton | Picker+.radioGroup | `radio_server` | Selectable | One selected |
| `StandaloneRadio` | RadioButton | Picker+.radioGroup | `radio_standalone` | Selectable | One selected |
| `ClientRadio` | RadioButton | Picker+.radioGroup | `radio_client` | Selectable | One selected |
| `ServerDescLabel` | Label | Text(description) | `lbl_server_desc` | Visible | Describes server mode |
| `StandaloneDescLabel` | Label | Text(description) | `lbl_standalone_desc` | Visible | Describes standalone |
| `ClientDescLabel` | Label | Text(description) | `lbl_client_desc` | Visible | Describes client mode |

### 1.5 Step 3 - Certificate Settings

| Control ID | Windows Type | SwiftUI Equivalent | AutomationId | Validation |
|------------|-------------|-------------------|--------------|------------|
| `SelfSignedRadio` | RadioButton | Picker+.radioGroup | `radio_selfsigned` | Default selected |
| `CustomCertRadio` | RadioButton | Picker+.radioGroup | `radio_customcert` | Enables cert fields |
| `LetsEncryptRadio` | RadioButton | Picker+.radioGroup | `radio_letsencrypt` | Enables domain field |
| `CustomCertPathTextBox` | TextBox | TextField | `txt_cert_path` | Valid file path |
| `CustomKeyPathTextBox` | TextBox | TextField | `txt_key_path` | Valid file path |
| `LetsEncryptDomainTextBox` | TextBox | TextField | `txt_le_domain` | Valid domain |
| `BrowseCertButton` | Button | Button+FilePicker | `btn_browse_cert` | Opens file picker |
| `BrowseKeyButton` | Button | Button+FilePicker | `btn_browse_key` | Opens file picker |

### 1.6 Step 4 - Security Settings

| Control ID | Windows Type | SwiftUI Equivalent | AutomationId | Default | Validation |
|------------|-------------|-------------------|--------------|---------|------------|
| `EnvironmentComboBox` | ComboBox | Picker | `picker_environment` | Production | Valid selection |
| `LogLevelComboBox` | ComboBox | Picker | `picker_loglevel` | INFO | Valid selection |
| `EnforceTLSCheckBox` | CheckBox | Toggle | `toggle_tls12` | ON | Boolean state |
| `ValidateCertsCheckBox` | CheckBox | Toggle | `toggle_validate_certs` | ON | Boolean state |
| `DebugLoggingCheckBox` | CheckBox | Toggle | `toggle_debug_logging` | OFF | Boolean state |

### 1.7 Step 5 - Storage Configuration

| Control ID | Windows Type | SwiftUI Equivalent | AutomationId | macOS Default | Validation |
|------------|-------------|-------------------|--------------|---------------|------------|
| `DatastoreTextBox` | TextBox | TextField | `txt_datastore` | ~/Library/Application Support/Velociraptor | Valid path |
| `LogsTextBox` | TextBox | TextField | `txt_logs` | ~/Library/Logs/Velociraptor | Valid path |
| `BrowseDatastoreButton` | Button | Button+FilePicker | `btn_browse_datastore` | N/A | Opens picker |
| `BrowseLogsButton` | Button | Button+FilePicker | `btn_browse_logs` | N/A | Opens picker |
| `DatastoreSizeComboBox` | ComboBox | Picker | `picker_datastore_size` | Medium | Valid selection |

### 1.8 Step 6 - Network Configuration

| Control ID | Windows Type | SwiftUI Equivalent | AutomationId | Default | Validation |
|------------|-------------|-------------------|--------------|---------|------------|
| `BindAddressTextBox` | TextBox | TextField | `txt_bind_address` | 0.0.0.0 | Valid IP |
| `BindPortTextBox` | TextBox | TextField | `txt_bind_port` | 8000 | Valid port (1-65535) |
| `GUIBindAddressTextBox` | TextBox | TextField | `txt_gui_bind_address` | 127.0.0.1 | Valid IP |
| `GUIBindPortTextBox` | TextBox | TextField | `txt_gui_bind_port` | 8889 | Valid port |

### 1.9 Step 7 - Authentication

| Control ID | Windows Type | SwiftUI Equivalent | AutomationId | Validation |
|------------|-------------|-------------------|--------------|------------|
| `AdminUsernameTextBox` | TextBox | TextField | `txt_admin_username` | Non-empty, valid chars |
| `AdminPasswordTextBox` | TextBox (Password) | SecureField | `txt_admin_password` | Min 8 chars, complexity |
| `ConfirmPasswordTextBox` | TextBox (Password) | SecureField | `txt_confirm_password` | Matches password |
| `OrganizationTextBox` | TextBox | TextField | `txt_organization` | Non-empty |
| `ShowPasswordCheckBox` | CheckBox | Toggle | `toggle_show_password` | OFF |

### 1.10 Step 8 - Review

| Control ID | Windows Type | SwiftUI Equivalent | AutomationId | Action |
|------------|-------------|-------------------|--------------|--------|
| `ReviewLabel` | Label | Text(summary) | `lbl_review_summary` | Display config |
| `GenerateButton` | Button | Button("Generate") | `btn_generate` | Create config file |

### 1.11 Step 9 - Complete

| Control ID | Windows Type | SwiftUI Equivalent | AutomationId | Action |
|------------|-------------|-------------------|--------------|--------|
| `SuccessLabel` | Label | Text(success) | `lbl_success` | Show completion |
| `OpenConfigButton` | Button | Button("Open Config") | `btn_open_config` | Open file |
| `LaunchButton` | Button | Button("Launch") | `btn_launch` | Start Velociraptor |
| `FinishButton` | Button | Button("Finish") | `btn_finish` | Close wizard |

---

## 2. IncidentResponseGUI.ps1 - Incident Response Collector

### 2.1 Main Window Controls

| Control ID | Windows Type | SwiftUI Equivalent | AutomationId | Purpose |
|------------|-------------|-------------------|--------------|---------|
| `MainForm` | Form | WindowGroup | `window_ir` | Main IR window |
| `HeaderPanel` | Panel | VStack | `panel_ir_header` | Branding header |
| `ContentPanel` | Panel | ScrollView | `panel_ir_content` | Main content |

### 2.2 Incident Selection Controls

| Control ID | Windows Type | SwiftUI Equivalent | AutomationId | Items | Validation |
|------------|-------------|-------------------|--------------|-------|------------|
| `CategoryComboBox` | ComboBox | Picker | `picker_ir_category` | 7 categories | One selected |
| `IncidentComboBox` | ComboBox | Picker | `picker_ir_incident` | 100 scenarios | Enabled after category |
| `IncidentLabel` | Label | Text | `lbl_ir_selection` | N/A | Visible |

### 2.3 Incident Details Panel

| Control ID | Windows Type | SwiftUI Equivalent | AutomationId | Content |
|------------|-------------|-------------------|--------------|---------|
| `DetailsPanel` | Panel | GroupBox/Section | `panel_ir_details` | Container |
| `DetailsLabel` | Label | Text | `lbl_ir_details_title` | "INCIDENT DETAILS" |
| `DetailsTextBox` | RichTextBox | TextEditor (readonly) | `txt_ir_details` | Dynamic content |

### 2.4 Configuration Panel

| Control ID | Windows Type | SwiftUI Equivalent | AutomationId | Default | Validation |
|------------|-------------|-------------------|--------------|---------|------------|
| `PathTextBox` | TextBox | TextField | `txt_ir_path` | ~/VelociraptorCollectors | Valid path |
| `BrowseButton` | Button | Button+FilePicker | `btn_ir_browse` | N/A | Opens picker |
| `OfflineCheckBox` | CheckBox | Toggle | `toggle_ir_offline` | ON | Boolean |
| `PortableCheckBox` | CheckBox | Toggle | `toggle_ir_portable` | ON | Boolean |
| `EncryptCheckBox` | CheckBox | Toggle | `toggle_ir_encrypt` | OFF | Boolean |
| `PriorityComboBox` | ComboBox | Picker | `picker_ir_priority` | High | 4 options |
| `UrgencyComboBox` | ComboBox | Picker | `picker_ir_urgency` | Rapid | 4 options |

### 2.5 Action Buttons

| Control ID | Windows Type | SwiftUI Equivalent | AutomationId | Style | Action |
|------------|-------------|-------------------|--------------|-------|--------|
| `DeployButton` | Button | Button (primary) | `btn_ir_deploy` | Green/accent | Deploy collector |
| `PreviewButton` | Button | Button (secondary) | `btn_ir_preview` | Blue | Preview config |
| `SaveButton` | Button | Button | `btn_ir_save` | Standard | Save config |
| `LoadButton` | Button | Button | `btn_ir_load` | Standard | Load config |
| `HelpButton` | Button | Button | `btn_ir_help` | Orange | Show help |
| `ExitButton` | Button | Button (destructive) | `btn_ir_exit` | Red | Close window |

### 2.6 Status Bar

| Control ID | Windows Type | SwiftUI Equivalent | AutomationId | Update Frequency |
|------------|-------------|-------------------|--------------|------------------|
| `StatusBar` | StatusStrip | HStack (footer) | `status_ir` | On action |
| `StatusLabel` | ToolStripStatusLabel | Text | `lbl_ir_status` | On action |

---

## 3. Emergency Deployment Mode Controls

### 3.1 VelociraptorGUI-InstallClean.ps1

| Control ID | Windows Type | SwiftUI Equivalent | AutomationId | Style | Action |
|------------|-------------|-------------------|--------------|-------|--------|
| `EmergencyButton` | Button | Button (destructive) | `btn_emergency` | Red, prominent | Trigger emergency |
| `EmergencyConfirmDialog` | MessageBox | Alert | `alert_emergency` | Warning icon | Confirm action |
| `EmergencyProgressBar` | ProgressBar | ProgressView | `progress_emergency` | Indeterminate | Show progress |
| `EmergencyStatusLabel` | Label | Text | `lbl_emergency_status` | Bold | Status updates |

---

## 4. macOS-Specific Controls (New)

### 4.1 Menu Bar

| Control ID | SwiftUI Component | AutomationId | Standard macOS |
|------------|------------------|--------------|----------------|
| `AppMenu` | Menu("Velociraptor") | `menu_app` | Yes |
| `FileMenu` | Menu("File") | `menu_file` | Yes |
| `EditMenu` | Menu("Edit") | `menu_edit` | Yes |
| `ViewMenu` | Menu("View") | `menu_view` | Yes |
| `WindowMenu` | Menu("Window") | `menu_window` | Yes |
| `HelpMenu` | Menu("Help") | `menu_help` | Yes |

### 4.2 Toolbar

| Control ID | SwiftUI Component | AutomationId | Action |
|------------|------------------|--------------|--------|
| `ToolbarDeploy` | ToolbarItem | `toolbar_deploy` | Quick deploy |
| `ToolbarHealth` | ToolbarItem | `toolbar_health` | Health check |
| `ToolbarLogs` | ToolbarItem | `toolbar_logs` | View logs |
| `ToolbarSettings` | ToolbarItem | `toolbar_settings` | Preferences |

### 4.3 Preferences Window

| Control ID | SwiftUI Component | AutomationId | Setting |
|------------|------------------|--------------|---------|
| `GeneralTab` | TabView item | `tab_general` | General settings |
| `SecurityTab` | TabView item | `tab_security` | Security settings |
| `AdvancedTab` | TabView item | `tab_advanced` | Advanced settings |
| `AutoStartToggle` | Toggle | `toggle_autostart` | Launch at login |
| `UpdateCheckToggle` | Toggle | `toggle_updates` | Check for updates |
| `TelemetryToggle` | Toggle | `toggle_telemetry` | Usage analytics |
| `DarkModeSelector` | Picker | `picker_appearance` | Appearance mode |

### 4.4 Keychain Integration

| Control ID | SwiftUI Component | AutomationId | Purpose |
|------------|------------------|--------------|---------|
| `KeychainAccessPrompt` | System dialog | N/A (system) | Permission request |
| `KeychainItemName` | N/A | N/A | "Velociraptor Credentials" |
| `SecurePasswordField` | SecureField | `secure_password` | Password entry |

---

## 5. Test Case Mapping

### 5.1 UI Control to Test Case Matrix

| Control | Test Case | Assertion Type | Evidence |
|---------|-----------|----------------|----------|
| `MainForm` | TC001_WindowLaunch | UI visible | Screenshot |
| `NextButton` | TC002_NavigationForward | Step change | Screenshot + log |
| `BackButton` | TC003_NavigationBackward | Step change | Screenshot + log |
| `ServerRadio` | TC004_DeploymentSelection | State change | Config output |
| `DatastoreTextBox` | TC005_PathValidation | Input validation | Error/success |
| `AdminPasswordTextBox` | TC006_SecureInput | Keychain storage | Keychain query |
| `GenerateButton` | TC007_ConfigGeneration | File creation | File exists |
| `DeployButton` | TC008_Deployment | Process started | ps output |
| `EmergencyButton` | TC009_EmergencyMode | Rapid deploy | Process + files |

### 5.2 Accessibility Test Cases

| Control | VoiceOver Label | Accessibility Role | Test Case |
|---------|-----------------|-------------------|-----------|
| `MainForm` | "Velociraptor Configuration Wizard" | Window | TC_A001 |
| `NextButton` | "Next step" | Button | TC_A002 |
| `BackButton` | "Previous step" | Button | TC_A003 |
| `DatastoreTextBox` | "Datastore directory path" | TextField | TC_A004 |
| `EmergencyButton` | "Emergency deployment mode" | Button | TC_A005 |

---

## 6. Evidence Collection Paths

```
artifacts/
├── {YYYYMMDD-HHMMSS}/
│   ├── configuration-wizard/
│   │   ├── TC001_WindowLaunch/
│   │   │   ├── screenshot_initial.png
│   │   │   └── test_result.json
│   │   ├── TC002_NavigationForward/
│   │   │   ├── screenshot_step1.png
│   │   │   ├── screenshot_step2.png
│   │   │   └── test_result.json
│   │   └── ...
│   ├── incident-response/
│   │   ├── TC_IR001_CategorySelection/
│   │   │   └── ...
│   │   └── ...
│   ├── emergency-mode/
│   │   └── TC_EM001_EmergencyDeploy/
│   │       └── ...
│   └── summary/
│       ├── coverage_report.html
│       ├── coverage_report.json
│       └── test_summary.html
```

---

## 7. Control Count Summary

| UI Area | Total Controls | Implemented (macOS) | Coverage |
|---------|---------------|---------------------|----------|
| Configuration Wizard | 45 | 0 | 0% |
| Incident Response | 25 | 0 | 0% |
| Emergency Mode | 4 | 0 | 0% |
| macOS Specific | 20 | 0 | 0% |
| **TOTAL** | **94** | **0** | **0%** |

---

**Next Step**: Implement SwiftUI components following this inventory
