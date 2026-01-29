//
//  GroupNodeView.swift
//  SwiftFlow
//
//  Group node view for grouping other nodes.
//

import SwiftUI

/// Group node view - container for other nodes
public struct GroupNodeView: View {
    let node: any FlowNode
    let isSelected: Bool
    
    /// Current size from environment (for resize support)
    @Environment(\.nodeCurrentSize) private var currentSize
    
    /// Actual size to use (environment size during resize, or node's stored size)
    private var actualSize: CGSize {
        currentSize ?? CGSize(width: node.width, height: node.height)
    }
    
    public init(node: any FlowNode, isSelected: Bool) {
        self.node = node
        self.isSelected = isSelected
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "rectangle.3.group")
                    .font(.system(size: 12))
                Text("Group")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            
            // Content area
            Rectangle()
                .fill(Color.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: actualSize.width, height: actualSize.height)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isSelected ? Color.accentColor : Color.gray.opacity(0.3),
                    style: StrokeStyle(lineWidth: isSelected ? 2 : 1, dash: [5, 3])
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        GroupNodeView(node: PreviewNode(width: 300, height: 200), isSelected: false)
        GroupNodeView(node: PreviewNode(width: 300, height: 200), isSelected: true)
    }
    .padding()
}
