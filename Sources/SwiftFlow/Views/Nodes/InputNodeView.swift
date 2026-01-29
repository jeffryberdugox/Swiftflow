//
//  InputNodeView.swift
//  SwiftFlow
//
//  Input node view (source only, no inputs).
//

import SwiftUI

/// Input node view - has outputs only
public struct InputNodeView: View {
    let node: any FlowNode
    let isSelected: Bool
    
    public init(node: any FlowNode, isSelected: Bool) {
        self.node = node
        self.isSelected = isSelected
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.blue)
            
            Text("Input")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: node.width, height: node.height)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.blue : Color.blue.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: Color.black.opacity(isSelected ? 0.2 : 0.1), radius: isSelected ? 6 : 3, x: 0, y: 2)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        
        // Interactive output ports only
        .overlay(
            VStack(spacing: 12) {
                ForEach(Array(node.outputPorts.enumerated()), id: \.element.id) { _, port in
                    InteractivePortView(
                        port: port,
                        node: node,
                        isInput: false,
                        size: 10,
                        color: .blue
                    )
                    .offset(x: 5)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        InputNodeView(
            node: PreviewNode(
                width: 150,
                height: 60,
                inputPorts: [],
                outputPorts: [PreviewPort(position: .right)]
            ),
            isSelected: false
        )
        InputNodeView(
            node: PreviewNode(
                width: 150,
                height: 60,
                inputPorts: [],
                outputPorts: [PreviewPort(position: .right)]
            ),
            isSelected: true
        )
    }
    .padding()
}
