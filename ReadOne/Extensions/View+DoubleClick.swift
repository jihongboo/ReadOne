//
//  View+DoubleClick.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftUI

#if os(macOS)
    extension View {
        /// 添加双击手势处理
        func onDoubleClick(perform action: @escaping () -> Void) -> some View {
            self.overlay {
                DoubleClickHandler(action: action)
            }
        }
    }

    struct DoubleClickHandler: NSViewRepresentable {
        let action: () -> Void

        func makeNSView(context: Context) -> NSView {
            let view = DoubleClickView()
            view.action = action
            return view
        }

        func updateNSView(_ nsView: NSView, context: Context) {
            (nsView as? DoubleClickView)?.action = action
        }
    }

    class DoubleClickView: NSView {
        var action: (() -> Void)?

        override func mouseDown(with event: NSEvent) {
            super.mouseDown(with: event)
            if event.clickCount == 2 {
                action?()
            }
        }
    }
#endif
