//
//  OutputNodeView.swift
//  SwiftFlow
//
//  Output node view (sink only, no outputs).
//

import SwiftUI

/// Output node view - has inputs only
public struct OutputNodeView: View {
    let node: any FlowNode
    let isSelected: Bool
    
    public init(node: any FlowNode, isSelected: Bool) {
        self.node = node
        self.isSelected = isSelected
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Spacer()
            
            Text("Output")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            
            Image(systemName: "arrow.left.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: node.width, height: node.height)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.green.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.green : Color.green.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: Color.black.opacity(isSelected ? 0.2 : 0.1), radius: isSelected ? 6 : 3, x: 0, y: 2)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        
        // Interactive input ports only
        .overlay(
            VStack(spacing: 12) {
                ForEach(Array(node.inputPorts.enumerated()), id: \.element.id) { _, port in
                    InteractivePortView(
                        port: port,
                        node: node,
                        isInput: true,
                        size: 10,
                        color: .green
                    )
                    .offset(x: -5)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        OutputNodeView(
            node: PreviewNode(
                width: 150,
                height: 60,
                inputPorts: [PreviewPort(position: .left)],
                outputPorts: []
            ),
            isSelected: false
        )
        OutputNodeView(
            node: PreviewNode(
                width: 150,
                height: 60,
                inputPorts: [PreviewPort(position: .left)],
                outputPorts: []
            ),
            isSelected: true
        )
    }
    .padding()
}
