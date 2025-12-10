import SwiftUI
import PDFKit
import UIKit

// MARK: - Do It For Me Result View
struct DoItForMeResultView: View {
    let stepTitle: String
    let result: String
    let onDismiss: () -> Void
    let onMarkComplete: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSaveOptions = false
    @State private var showShareSheet = false
    @State private var pdfData: Data?
    @State private var savedToNotes = false
    @State private var showSavedConfirmation = false
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AclioSpacing.space5) {
                        // Header Card
                        headerCard
                        
                        // Result Content
                        resultCard
                        
                        // Action Buttons
                        actionButtons
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, AclioSpacing.screenHorizontal)
                    .padding(.top, AclioSpacing.space4)
                }
                
                // Bottom Action Bar
                VStack {
                    Spacer()
                    bottomActionBar
                }
                
                // Saved Confirmation
                if showSavedConfirmation {
                    savedConfirmationOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Exit") {
                        onDismiss()
                    }
                    .foregroundColor(colors.accentPrimary)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Done For You")
                        .font(AclioFont.navTitle)
                        .foregroundColor(colors.textPrimary)
                }
            }
        }
        .confirmationDialog("Save Result", isPresented: $showSaveOptions) {
            Button("Save as PDF") {
                saveToPDF()
            }
            Button("Save to Notes") {
                saveToNotes()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose how to save this result")
        }
        .sheet(isPresented: $showShareSheet) {
            if let pdfData = pdfData {
                ShareSheet(activityItems: [pdfData])
            }
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
            HStack(spacing: AclioSpacing.space3) {
                ZStack {
                    Circle()
                        .fill(AclioGradients.accentOrange)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Completed")
                        .font(AclioFont.captionMedium)
                        .foregroundColor(colors.textMuted)
                    
                    Text(stepTitle)
                        .font(AclioFont.cardTitle)
                        .foregroundColor(colors.textPrimary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
        }
        .padding(AclioSpacing.cardPadding)
        .background(colors.cardBackground)
        .cornerRadius(AclioRadius.card)
        .aclioCardShadow(isDark: colorScheme == .dark)
    }
    
    // MARK: - Result Card
    private var resultCard: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space4) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(colors.accentPrimary)
                Text("What Was Done")
                    .font(AclioFont.sectionTitle)
                    .foregroundColor(colors.textPrimary)
                Spacer()
            }
            
            // Parse and display bullet points
            VStack(alignment: .leading, spacing: AclioSpacing.space3) {
                ForEach(parseBulletPoints(result), id: \.self) { point in
                    HStack(alignment: .top, spacing: AclioSpacing.space3) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                            .padding(.top, 2)
                        
                        Text(point)
                            .font(AclioFont.body)
                            .foregroundColor(colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(AclioSpacing.cardPadding)
        .background(colors.cardBackground)
        .cornerRadius(AclioRadius.card)
        .aclioCardShadow(isDark: colorScheme == .dark)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: AclioSpacing.space3) {
            // Save Button
            Button(action: {
                AclioHaptics.light()
                showSaveOptions = true
            }) {
                HStack(spacing: AclioSpacing.space3) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 18, weight: .medium))
                    
                    Text("Save Result")
                        .font(AclioFont.buttonMedium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                }
                .foregroundColor(colors.textPrimary)
                .padding(AclioSpacing.cardPadding)
                .background(colors.cardBackground)
                .cornerRadius(AclioRadius.card)
                .aclioCardShadow(isDark: colorScheme == .dark)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: AclioSpacing.space3) {
                // Exit Button
                SecondaryButton("Exit") {
                    onDismiss()
                }
                
                // Mark Complete Button
                PrimaryButton("Mark Step Complete", icon: "checkmark") {
                    AclioHaptics.success()
                    onMarkComplete()
                    onDismiss()
                }
            }
            .padding(.horizontal, AclioSpacing.screenHorizontal)
            .padding(.vertical, AclioSpacing.space4)
            .padding(.bottom, ScreenSize.safeBottom)
        }
        .background(colors.cardBackground)
    }
    
    // MARK: - Saved Confirmation Overlay
    private var savedConfirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: AclioSpacing.space4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.green)
                
                Text(savedToNotes ? "Saved to Notes!" : "PDF Ready!")
                    .font(AclioFont.title2)
                    .foregroundColor(colors.textPrimary)
                
                Text(savedToNotes ? "Check your Notes app" : "Choose where to save")
                    .font(AclioFont.body)
                    .foregroundColor(colors.textSecondary)
            }
            .padding(AclioSpacing.space8)
            .background(colors.cardBackground)
            .cornerRadius(AclioRadius.xxl)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showSavedConfirmation = false
                    if !savedToNotes && pdfData != nil {
                        showShareSheet = true
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func parseBulletPoints(_ text: String) -> [String] {
        let lines = text.components(separatedBy: "\n")
        var points: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            // Remove bullet markers
            var cleanLine = trimmed
            let bulletPrefixes = ["- ", "• ", "* ", "✓ ", "✔ "]
            for prefix in bulletPrefixes {
                if cleanLine.hasPrefix(prefix) {
                    cleanLine = String(cleanLine.dropFirst(prefix.count))
                    break
                }
            }
            
            // Remove numbered prefixes like "1. " or "1) "
            if let match = cleanLine.range(of: #"^\d+[\.\)]\s*"#, options: .regularExpression) {
                cleanLine = String(cleanLine[match.upperBound...])
            }
            
            if !cleanLine.isEmpty {
                points.append(cleanLine)
            }
        }
        
        return points.isEmpty ? [text] : points
    }
    
    // MARK: - Save to PDF
    private func saveToPDF() {
        let pdfMetaData = [
            kCGPDFContextCreator: "Aclio",
            kCGPDFContextAuthor: "Aclio AI Coach",
            kCGPDFContextTitle: "Do It For Me: \(stepTitle)"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth: CGFloat = 612 // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - (margin * 2)
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = margin
            
            // Title
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.label
            ]
            
            let title = "✨ Do It For Me Result"
            let titleRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 40)
            title.draw(in: titleRect, withAttributes: titleAttributes)
            yPosition += 50
            
            // Step Title
            let subtitleFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.secondaryLabel
            ]
            
            let stepRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 30)
            stepTitle.draw(in: stepRect, withAttributes: subtitleAttributes)
            yPosition += 50
            
            // Divider line
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: margin, y: yPosition))
            linePath.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
            UIColor.separator.setStroke()
            linePath.lineWidth = 1
            linePath.stroke()
            yPosition += 20
            
            // Content
            let bodyFont = UIFont.systemFont(ofSize: 14)
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.label
            ]
            
            let points = parseBulletPoints(result)
            for point in points {
                let bulletText = "✓  \(point)"
                let textSize = bulletText.boundingRect(
                    with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin,
                    attributes: bodyAttributes,
                    context: nil
                )
                
                let textRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: textSize.height + 10)
                bulletText.draw(in: textRect, withAttributes: bodyAttributes)
                yPosition += textSize.height + 15
            }
            
            // Footer
            yPosition = pageHeight - margin - 30
            let footerFont = UIFont.systemFont(ofSize: 10)
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: footerFont,
                .foregroundColor: UIColor.tertiaryLabel
            ]
            
            let footer = "Generated by Aclio AI Coach • \(Date().formatted())"
            let footerRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 20)
            footer.draw(in: footerRect, withAttributes: footerAttributes)
        }
        
        pdfData = data
        savedToNotes = false
        showSavedConfirmation = true
    }
    
    // MARK: - Save to Notes
    private func saveToNotes() {
        let noteContent = """
        ✨ Do It For Me Result
        Step: \(stepTitle)
        
        ---
        
        \(result)
        
        ---
        Generated by Aclio • \(Date().formatted())
        """
        
        // Create URL scheme for Notes app
        if let url = URL(string: "mobilenotes://") {
            // Copy to clipboard and open Notes
            UIPasteboard.general.string = noteContent
            
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                savedToNotes = true
                showSavedConfirmation = true
            } else {
                // Fallback: just copy to clipboard
                savedToNotes = true
                showSavedConfirmation = true
            }
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
#Preview {
    DoItForMeResultView(
        stepTitle: "Research healthy breakfast options",
        result: """
        - Identified 5 quick healthy breakfast recipes (overnight oats, smoothie bowls, avocado toast, Greek yogurt parfait, egg muffins)
        - Created a weekly meal prep schedule for mornings
        - Made a shopping list with all necessary ingredients
        - Set up meal prep containers for the week
        - Bookmarked 3 reliable nutrition websites for future reference
        """,
        onDismiss: {},
        onMarkComplete: {}
    )
}

