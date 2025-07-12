//
//  ChatViewModel.swift
//  Hello World
//
//  Created by mike on 04/07/2025.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
public class ChatViewModel: ObservableObject {
    @Published public var conversationHistory: [ChatMessage] = []
    @Published public var userInput: String = ""
    @Published public var showingAlert = false
    @Published public var isLoading = false
    @Published public var lastError: String?
    @Published public var useStructuredOutput = false
    @Published public var promptStrategy = "Standard"
    @Published var isBootedUp = false
    @Published public var showingSaveDialog = false
    @Published public var javascriptToSave: String = ""
    
    private let aiService = AIService()
    private var lastSuccessfulSavePath: String?
    
    // MARK: - Widget State Management
    
    /// Current widget code/state
    @Published var currentWidgetCode: String = ""
    
    public init() {
        // Default initializer
    }
    
    /// Track if we have a current widget
    var hasCurrentWidget: Bool {
        !currentWidgetCode.isEmpty
    }
    
    public func bootUpWithRole() {
        print("🚀 ChatViewModel: Booting up chat with widget designer role")
        
        let humanRolePrompt = """
        ### Introduction:

        Your task is to generate a "Übersicht widget" that satisfies the user's wishes, which will be communicated throughout this chat.

        Übersicht is a macOS desktop widget system that overlays custom, web-based information displays on the desktop background using React/JSX and shell commands.

        Widgets are built by producing a block of JSX code that follows specific rules, which will be outlined in this prompt.

        A well-formed Übersicht widget must declare a specific set of exports, explained below.

        Through an iterative process, the user will describe — in natural language — how they want the widget to look and behave. With each reply, you will regenerate and update the JSX code to reflect their evolving instructions.

        Below, you'll find a widget template. Value replacement placeholders are marked by `@@`; for exampls: `@@bash_command@@`.

        The meaning of these placeholders is explained after the template.

        Each time you generate a new version of the widget, replace the placeholders with values that reflect the user's current requests.

        ### General Rules: 
        1. Never use `className={className}` anywhere in the JSX code.
        2. Do not use `style` attributes anywhere in the JSX code.
        3. To position the widget container, use the `export const className` string. Do not attempt to position the widget on the screen by creating a style string for the root DOM element returned by the render function.

        ### JSX template of the widget:
        ```JSX

            import { css } from 'uebersicht'; // Optional, use when Emotion's css functions are needed.
            import { styled } from 'uebersicht'; // Optional, use when Emotion styled functions are needed.

            /* ----- Übersicht exports ---- */

            export const command = "@@bash_command@@"
            export const refreshFrequency = @@refresh_frequency@@

            export const render = ({ data_in }) => (
                @@JSX_DOMELEMENTS@@
            );

            export const className = css`
            @@css_for_the_widget_container@@
            `;

            /* ----- local stuff ---- */

            @@any_number_of_css_string_variables_as_needed@@
        ```

        ### Explanation of the placeholders:

        **1. `@@bash_command@@`**
        - **Purpose**: A terminal command that will be executed by Übersicht to generate the data 
          for the widget. This data is then passed as the `data_in` argument in the `render` function.
        - **Example**: `echo 'Widget Data'` returns "Widget Data", or `date` returns the system date and time at the moment the widget is refreshed.
        - **Usage**: The output will be passed as the `output` argument in the `render` function.
        
        **2. `@@refresh_frequency@@`**
        - **Purpose**: Controls how often (in milliseconds) the widget is refreshed by Übersicht.
        - **Example**: `3000` for a refresh every 3 seconds.
        - **Usage**: set low for frequent updates, high for infrequent updates. Set to 1000 to update the widget every second.

        **3. `@@css_for_the_widget_container@@`**
        - **Purpose**: CSS that applies to the widget container (the outer wrapper that Übersicht creates). No need to explicitly reference this from the JSX content returned by the render function.
        - **Example**: `background-color: pink; padding: 10px;`
        - **Usage**: Use this only for styles that apply to the widget container. 
          To position the widget container, use this string.
          Do not use flex keywords for positioning, use `left`, `top`, `right`, `bottom` and other non-flex keywords.
          flex CSS keywords for positioning, use `left`, `top`, `right`, `bottom` and other non-flex keywords.
          .

        **4. `@@JSX_DOMELEMENTS@@`**
        - **Purpose**: a block of DOM elements returned by the render function; will be rendered by Übersicht.
        - **Example**: 
            a) `<h1>{data_in}</h1>` references the render function's input argument
            b) `<div className={classXYZ}>Hello World!</div>` references the CSS constant 
            string variable `classXYZ` defined in `@@any_number_of_css_string_variables_as_needed@@`.
        - **Usage**: 
            a) can reference the data_in object argument of the render function (i.e. `{data_in}`).
            b) to define styles for a DOM element:
                1) in section `@@any_number_of_css_string_variables_as_needed@@` (explained below) 
                  declare a local string variable containing the CSS styles, 
                      e.g. 
                            const classXYZ = css`
                                background-color: red; padding: 10px;
                            `;

                2) reference it in the DOM elementby adding a `className` attribute that references
                 the new local string variable, 
                   e.g. `<div className={classXYZ}>Hello World!</div>`.
            
            c) Do not put a `style` attribute into any of the DOM elements; rather, use the `className` attribute qs described above.
            d) Do NOT use `className={className}` anywhere in the JSX code.
            e) Do NOT try to position the widget by creating a style string for the root DOM element returned by the render function. Instead,
            place positioning CSS keywords in the `export const className` string: it is the only way to control the styles of the 
            widget container.


        **5. `@@any_number_of_css_string_variables_as_needed@@`**
        - **Purpose**:  Can contain any number of CSS strings (requires importing Emotion's css library).
            These strings are referenced in the DOM elements by the `className` attribute.
        - **Example**: 
            ```JSX
                const classXYZ = css`
                    background-color: red; padding: 10px;
                `;
                const classABC = css`
                    foreground-color: blue; padding: 10px;
                `;
            ```
        - **Usage**: define CSS strings in this section only if the widget needs element-specific styles.

        ### Placeholder Rules: 
        1. Use `@@css_for_the_widget_container@@` only for styles that apply to the widget container (layout, positioning, overall styling).
        2. Use `@@any_number_of_css_string_variables_as_needed@@` only for styles that apply to specific content elements (colors, padding, margins for individual divs, headings, etc.).
        3. Never duplicate styles between these two areas.

        ### Sample 1 : "Widget Display" 

        The prompt: Create a widget that displays "Hello World!" and centre it on the screen.

        The generated JSX code:

        ```JSX
        export const command = "echo Hello World!"
        export const refreshFrequency = 5000; 
        export const render = ({ data_in }) => ( 
        <h1>{data_in}</h1>
        );

        export const className = `
            left: 50%;
            top: 50%;
            transform: translate(-50%, -50%);
            color: #fff;
        `;

        ``` 

        Notice:
        1) The widget will display the value of the data_in argument in a heading element.
        2) everything in the widget will be white, because of the color defined in `export const className = `
        3) The root div has no className attribute - the widget is centred by placing the following in `export const className` :
            `left: 50%; top: 50%; transform: translate(-50%, -50%);`
        4) there are no styles needed for the content of the widget, because the content is not styled.
           We therefore:
             a) do not insert any className attributes in any of the DOM elements ...
             b) which in turn means we do not define any CSS string variables in `@@any_number_of_css_string_variables_as_needed@@` ...
             c) which in turn means we do not import the Emotion css library.

        ### Sample 2 : "Left & Right" 
        
        The prompt: Please make a widget that is a table with two columns in it. The left column contains the word 
            “LEFT”, its background is red, the right column contains the word “RIGHT” and its 
            background is blue. The text of both is yellow. Align the widget against the right edge of the screen 
            but centred on the vertical axis.
            
        The generated JSX code:

        ```JSX
        import { css } from 'uebersicht';
        
        /* ----- Übersicht exports ---- */

        export const command = "echo 'Left and Right columns'"
        export const refreshFrequency = 3000
        export const render = ({ data_in }) => (
            <div className={tableRowStyle}>
                <div className={leftContent}>
                    <h2>LEFT</h2>
                </div>
                <div className={rightContent}>
                    <h2>RIGHT</h2>
                </div>
            </div>
        );

        export const className = `
            right: 0;
            top: 50%;
            transform: translateY(-50%);
            background-color: pink;
        `;

        /* ----- local stuff ---- */

        const tableRowStyle = css`
            display: flex;
            justify-content: space-between;
        `;

        const leftContent = css`
            background-color: red;
            padding: 10px;
            margin: 5px;
        `;

        const rightContent = css`
            background-color: blue;
            padding: 10px;
            margin: 5px;
        `;

        Notice:
        1) The widget is vertically centred on the right edge of the screen by placing the following
            in `export const className` : `right: 0; top: 50%; transform: translateY(-50%);`
        2) we use flex display in the tableRowStyle to be referenced in the root DOM element, 
           which then means we do import the Emotion css library (line 1 of the JSX sample code).
        3) styles are needed needed for both columns
           We therefore:
             a) insert a className attributes in the two child <div> DOM elements that in turn reference ...
             b) ... CSS string variables leftContent and rightContent in `@@any_number_of_css_string_variables_as_needed@@` ...

        ### Rules for the tone and content of the chat:

        1. Be concise: no explanation required for the user. Only generate one block of JSX code that contains the complete widget.
        2. At every generation, make sure to generate a block of JSX code that includes all the exported references
         (i.e. command, refreshFrequency, render, className) in the result. 
        3. Keep the terminal commands simple and safe.

        ### Next:
        In your first reply, there is no need to generate a widget. Just indicate that you're ready to take instructions from the user.
        ``` 
        """

        let compactifiedRolePrompt = """
        ### Introduction:
        Generate Übersicht widgets (macOS desktop widgets using React/JSX) based on user requests. Each response must be complete JSX code with all required exports.

        ### Rules:
        1. Never use `className={className}` in JSX
        2. No `style` attributes in JSX
        3. Position widget container only via `export const className`

        ### Template:
        ```JSX
        import { css } from 'uebersicht'; // Only if needed

        export const command = "@@bash_command@@"
        export const refreshFrequency = @@refresh_frequency@@
        export const render = ({ data_in }) => (@@JSX_DOMELEMENTS@@);
        export const className = css`@@css_for_the_widget_container@@`

        /* ----- local stuff ---- */
        @@any_number_of_css_string_variables_as_needed@@
        ```

        ### Placeholders:
        - `@@bash_command@@`: Terminal command (e.g., `echo 'Widget Data'`)
        - `@@refresh_frequency@@`: Refresh interval in ms (e.g., `3000`)
        - `@@css_for_the_widget_container@@`: Widget container styles (positioning, overall styling)
        - `@@JSX_DOMELEMENTS@@`: DOM elements (can reference `{data_in}`)
        - `@@any_number_of_css_string_variables_as_needed@@`: CSS variables for element styling

        ### Usage:
        - Widget positioning: Use `@@css_for_the_widget_container@@` (left, top, right, bottom)
        - Element styling: Create CSS variables in `@@any_number_of_css_string_variables_as_needed@@`, reference with `className={variableName}`
        - Import `css` only when creating CSS variables

        ### Sample 1 - Simple (no CSS import):
        Prompt: "Create a widget that displays 'Hello World!' and centre it on the screen."

        ```JSX
        export const command = "echo Hello World!"
        export const refreshFrequency = 5000
        export const render = ({ data_in }) => (<h1>{data_in}</h1>);
        export const className = `
            left: 50%; top: 50%; transform: translate(-50%, -50%);
            color: #fff;
        `;
        ```

        ### Sample 2 - Complex (with CSS import):
        Prompt: "Make a widget with two columns: left column 'LEFT' (red bg), right column 'RIGHT' (blue bg), yellow text. Align right edge, center vertically."

        ```JSX
        import { css } from 'uebersicht';

        export const command = "echo 'Left and Right columns'"
        export const refreshFrequency = 3000
        export const render = () => (
            <div className={tableRowStyle}>
                <div className={leftContent}><h2>LEFT</h2></div>
                <div className={rightContent}><h2>RIGHT</h2></div>
            </div>
        );
        export const className = `
            right: 0; top: 50%; transform: translateY(-50%);
            background-color: pink;
        `;

        const tableRowStyle = css`display: flex; justify-content: space-between;`;
        const leftContent = css`background-color: red; padding: 10px; margin: 5px;`;
        const rightContent = css`background-color: blue; padding: 10px; margin: 5px;`;
        ```

        ### Response Format:
        Generate only complete JSX code. No explanations needed.
        """

         let hiPrompt = """
        Hi.
        """
 
        // let firstPrompt = hiPrompt;
        let firstPrompt = humanRolePrompt;
        // let firstPrompt = compactifiedRolePrompt;

        // Add the role message to history
        let roleMessage = ChatMessage(
            content: firstPrompt,
            isUser: true,
            timestamp: Date())
        conversationHistory.append(roleMessage)
        
        // Send the role prompt to AI
        Task {
            await sendToAI(firstPrompt)
        }
        
        isBootedUp = true
    }
    
    public func sendMessage() {
        print("🔧 DEBUG: sendMessage called (regular mode)")
        print("🔧 DEBUG: useStructuredOutput = \(useStructuredOutput)")
        
        let trimmedInput = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        // Add user message to history
        let userMessage = ChatMessage(content: trimmedInput, isUser: true, timestamp: Date())
        conversationHistory.append(userMessage)
        
        // Clear input
        userInput = ""
        
        // Send to AI
        Task {
            await sendToAI(trimmedInput)
        }
    }
    
    public func sendStructuredMessage(_ basePrompt: String) {
        print("🔧 DEBUG: sendStructuredMessage called")
        print("🔧 DEBUG: promptStrategy = \(promptStrategy)")
        
        // Hardcoded concatenation for HTML + CSS
        let enhancedPrompt = basePrompt + " include the HTML followed by the CSS."
        
        let structuredPrompt: String
        
        switch promptStrategy {
        case "Direct":
            structuredPrompt = StructuredResponse.createDirectStructuredPrompt(enhancedPrompt, outputType: "HTML")
        case "Role-based":
            structuredPrompt = StructuredResponse.createRoleBasedPrompt(enhancedPrompt, outputType: "HTML")
        case "Markdown":
            structuredPrompt = StructuredResponse.createMarkdownFriendlyPrompt(enhancedPrompt, outputType: "HTML")
        default:
            structuredPrompt = StructuredResponse.createStructuredPrompt(enhancedPrompt, outputType: "HTML")
        }
        
        // Debug: Log what we're sending to AI
        print("🎯 DEBUG: Structured prompt being sent to AI:")
        print("---START OF PROMPT---")
        print(structuredPrompt)
        print("---END OF PROMPT---")
        
        // Add user message to history (show original prompt, not enhanced)
        let userMessage = ChatMessage(content: basePrompt, isUser: true, timestamp: Date())
        conversationHistory.append(userMessage)
        
        // Send structured prompt to AI with context management
        Task {
            await sendToAI(structuredPrompt)
        }
    }
    

    
    private func checkAndGenerateWidgetFile(from response: String) async {
        print("🔍 ChatViewModel: Checking for JavaScript blocks in response")
        
        let structuredResponse = StructuredResponse(from: response)
        let blocks = structuredResponse.extractedBlocks
        
        // Look for JavaScript blocks
        let jsBlock = blocks.first { $0.type.lowercased().contains("javascript") || $0.type.lowercased().contains("js") }
        
        if let js = jsBlock {
            print("🎯 ChatViewModel: Found JavaScript block, generating widget file")
            await generateWidgetFile(javascript: js.content)
        } else {
            print("🔍 ChatViewModel: JavaScript block not found in response")
        }
    }
    
    private func generateWidgetFile(javascript: String) async {
        print("📝 ChatViewModel: Generating widget file")
        print("📝 ChatViewModel: JavaScript content length: \(javascript.count)")
        print("📝 ChatViewModel: JavaScript content preview: \(String(javascript.prefix(100)))...")
        
        // Store the JavaScript content and show save dialog
        await MainActor.run {
            self.javascriptToSave = javascript
            self.currentWidgetCode = javascript  // Store as current widget state
            self.showingSaveDialog = true
        }
    }
    
    public func saveWidgetFile() {
        // If we have a previously successful save path, try that first
        if let lastPath = lastSuccessfulSavePath {
            let lastURL = URL(fileURLWithPath: lastPath)
            do {
                try javascriptToSave.write(to: lastURL, atomically: true, encoding: .utf8)
                print("✅ ChatViewModel: Widget file updated using previous path!")
                print("📁 File location: \(lastURL.path)")
                
                // Success - no need to show alert
                DispatchQueue.main.async {
                    self.lastError = nil
                    self.showingAlert = false
                }
                return
            } catch {
                print("⚠️ ChatViewModel: Previous path save failed: \(error)")
            }
        }
        
        // Try the default widgets folder
        let übersichtWidgetsPath = "\(NSHomeDirectory())/Library/Application Support/Übersicht/widgets"
        let directURL = URL(fileURLWithPath: übersichtWidgetsPath).appendingPathComponent("index.jsx")
        
        do {
            try javascriptToSave.write(to: directURL, atomically: true, encoding: .utf8)
            print("✅ ChatViewModel: Widget file updated directly in Übersicht folder!")
            print("📁 File location: \(directURL.path)")
            
            // Remember this successful path
            DispatchQueue.main.async {
                self.lastSuccessfulSavePath = directURL.path
            }
            
            // Success - no need to show alert
            DispatchQueue.main.async {
                self.lastError = nil
                self.showingAlert = false
            }
            return
        } catch {
            print("⚠️ ChatViewModel: Direct save failed, showing file picker: \(error)")
        }
        
        // If direct save fails, show the file picker
        showFilePicker()
    }
    
    private func showFilePicker() {
        let savePanel = NSSavePanel()
        savePanel.title = "Save Widget File"
        savePanel.nameFieldStringValue = "index.jsx"
        savePanel.allowedContentTypes = [UTType(filenameExtension: "jsx")!]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        
        // Set the initial directory to Übersicht widgets folder
        let übersichtWidgetsPath = "\(NSHomeDirectory())/Library/Application Support/Übersicht/widgets"
        savePanel.directoryURL = URL(fileURLWithPath: übersichtWidgetsPath)
        
        let javascriptContent = javascriptToSave
        savePanel.begin { [weak self] response in
            guard let self = self else { return }
            if response == .OK {
                DispatchQueue.main.async {
                    guard let saveURL = savePanel.url else { return }
                    do {
                        try javascriptContent.write(to: saveURL, atomically: true, encoding: .utf8)
                        print("✅ ChatViewModel: Widget file saved successfully!")
                        print("📁 File location: \(saveURL.path)")
                        
                        // Remember this successful path for future saves
                        self.lastSuccessfulSavePath = saveURL.path
                        
                        // Success - no need to show alert
                        self.lastError = nil
                        self.showingAlert = false
                    } catch {
                        print("❌ ChatViewModel: Failed to save widget file: \(error)")
                        print("❌ ChatViewModel: Error details: \(error.localizedDescription)")
                        
                        // Show error message
                        self.lastError = "Failed to save file: \(error.localizedDescription)"
                        self.showingAlert = true
                    }
                }
            }
        }
    }
    
    public func clearConversation() {
        conversationHistory.removeAll()
        currentWidgetCode = ""  // Clear widget state
        isBootedUp = false
    }
    

    
    /// Send message to AI (simplified - no context management)
    private func sendToAI(_ input: String) async {
        print("🔄 ChatViewModel: Starting AI request")
        isLoading = true
        lastError = nil
        
        if let response = await aiService.sendMessage(input) {
            print("✅ ChatViewModel: AI response received, adding to conversation")
            let aiMessage = ChatMessage(content: response, isUser: false, timestamp: Date())
            conversationHistory.append(aiMessage)
            
            // Log structured content if found
            if aiMessage.hasStructuredContent {
                print("🎯 ChatViewModel: Found structured content: \(aiMessage.extractedContent ?? "nil")")
            }
            
            // Check if we should generate widget file
            await checkAndGenerateWidgetFile(from: response)
            
            print("📝 ChatViewModel: Conversation history now has \(conversationHistory.count) messages")
        } else {
            print("❌ ChatViewModel: AI request failed")
            let errorMessage = ChatMessage(
                content: "Error: \(aiService.lastError ?? "Unknown error")",
                isUser: false,
                timestamp: Date()
            )
            conversationHistory.append(errorMessage)
        }
        
        isLoading = false
        print("🔄 ChatViewModel: AI request completed")
    }
} 
