//
//  DefaultNodeView.swift
//  SwiftFlow
//
//  Default node view implementation.
//

import SwiftUI

/// Default node view with standard styling and layout
public struct DefaultNodeView: View {
    let node: any FlowNode
    let isSelected: Bool
    
    public init(node: any FlowNode, isSelected: Bool) {
        self.node = node
        self.isSelected = isSelected
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Node")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
            
            // Content
            VStack(spacing: 8) {
                Text("ID: \(node.id.uuidString.prefix(8))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(.green)
                    Text("Ready")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
        }
        .frame(width: node.width, height: node.height)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: Color.black.opacity(isSelected ? 0.2 : 0.1), radius: isSelected ? 8 : 4, x: 0, y: 2)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        
        // Interactive Ports
        .interactivePorts(for: node)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        DefaultNodeView(node: PreviewNode(), isSelected: false)
        DefaultNodeView(node: PreviewNode(), isSelected: true)
    }
    .padding()
}
