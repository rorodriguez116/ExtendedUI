//
//  PagerView.swift
//  Campus
//
//  Created by Rolando Rodriguez on 1/27/20.
//  Copyright © 2020 Rolando Rodriguez. All rights reserved.
//

import Foundation
import SwiftUI

public struct PageIndicator: View {
    public var currentIndex = 0
    
    public var pages: Int
    
    public var selectedPageColor: Color

    public init(currentIndex: Int, pages: Int, selectedPageColor: Color) {
        self.currentIndex = currentIndex
        
        self.pages = pages
        
        self.selectedPageColor = selectedPageColor
    }
    
    
    public var body: some View {
        HStack(spacing: 9) {
            ForEach(0...pages - 1, id: \.self) { i in
                Circle()
                    .foregroundColor(self.currentIndex == i ? self.selectedPageColor : Color.main)
                    .frame(width: 10, height: 10)
            }
        }
    }
}

public struct PaginatedView<Content: View>: View {
    public struct Transform {
        var alpha: Double
        var scale: CGFloat
    }
    
    public enum Orientation {
        case horizontal
        case vertical
    }
    
    public enum DragToDismiss {
        case active(Binding<Double>, () -> Void)
        case inactive
    }
    
    public enum DisplayMode {
        case bottom
        case top
        case center
    }
    
    let content: (Int, Transform) -> Content
    
    let orientation: Orientation
    
    let numberOfElements: Int
    
    let noReturnIndex: Int?
    
    var onDismiss: (() -> Void)?
    
    var dragToDismiss: Bool = false
    
    var backgroundColor: Color
    
    var alignment: Alignment
    
    var isDragEnabled: Bool
    
    @State private var translation: CGSize = .zero
    
    @State private var previous: DragGesture.Value?
    
    @Binding var currentIndex: Int
    
    @Binding var controlsOpacity: Double
    
    private var screenSize: CGSize {
        #if os(iOS)
        return UIScreen.main.bounds.size
        #else
        return CGSize(width: 1024, height: 720)
        #endif
    }

    public init(_ count: Int, orientation: Orientation, alignment: Alignment = .center, currentIndex: Binding<Int>, dragToDismiss: DragToDismiss, backgroundColor: Color, isDragEnabled: Bool, noReturnOnIndex: Int? = nil, @ViewBuilder content: @escaping (Int, Transform) -> Content) {
        self.backgroundColor = backgroundColor
        
        self.isDragEnabled = isDragEnabled
        
        self.orientation = orientation
        
        self.alignment = alignment
        
        self._currentIndex = currentIndex
        
        self.numberOfElements = count
        
        self.content = content
        
        self.noReturnIndex = noReturnOnIndex
        
        self._controlsOpacity = .constant(1)
        
        if case .active(let opacity, let closure) = dragToDismiss {
            
            self.dragToDismiss = true
            
            self.onDismiss = closure
            
            self._controlsOpacity = opacity
        }
    }
    
    func calculateTransform(for index: Int, size: CGSize) -> Transform {
        guard let prev = self.previous else { return Transform(alpha: 1, scale: 1) }
        
        let ev = self.orientation == .vertical ? abs(prev.translation.height) >= abs(prev.translation.width) : abs(prev.translation.width) > abs(prev.translation.height)
        
        let defaultScale: CGFloat = 0.8
        
        if ev {
//            MARK: Logic to return content's transform in normal scroll
            let percentage = self.orientation == .horizontal ? translation.width / size.width : translation.height / size.height
            
            let ev = [self.currentIndex, self.currentIndex - 1, self.currentIndex + 1].contains(index)
            
            let scale = index == self.currentIndex ? max(1 - abs(percentage), defaultScale) : max(abs(percentage), defaultScale)
            
            let alpha = ev ? index == self.currentIndex ? 1 - abs(percentage) : abs(percentage) : 0
            
            return Transform(alpha: Double(alpha), scale: scale)
            
        } else {
//            MARK: Logic to return transform if user intends to dismiss the paginated view
            let percentage = self.orientation == .vertical ? translation.width / size.width : translation.height / size.height
            
            let ev = [self.currentIndex, self.currentIndex - 1, self.currentIndex + 1].contains(index)
            
            let scale = index == self.currentIndex ? max(1 - abs(percentage*1.5), 0.432) : defaultScale
            
            let alpha = ev ? 1 : 0
                        
            return Transform(alpha: Double(alpha), scale: scale)
        }
    }
    
    func startOffSet(height: CGFloat) -> CGFloat {
        let count = CGFloat(self.numberOfElements)
        
        let mod = CGFloat(Int(count) % 2)
        
        return mod == 0 ? ((count / 2) - 0.5) * height : (count - mod) / 2 * height
    }
    
    func backgroundOpacity(size: CGSize) -> Double {
        let percentage = self.orientation == .vertical ? translation.width / size.width : translation.height / size.height
        
        return 1 - Double(abs(percentage)*3)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: self.alignment) {
                self.backgroundColor
                    .opacity(self.backgroundOpacity(size: geometry.size))
                    .edgesIgnoringSafeArea(.all)
                
                Group {
                    if self.orientation == .horizontal {
                        HStack(spacing: 0) {
                            ForEach(0..<self.numberOfElements, id: \.self) { index in
                                self.content(index, self.calculateTransform(for: index, size: geometry.size))
                                    .frame(width: geometry.size.width)
                            }
                        }
                        .offset(x: -CGFloat(self.currentIndex) * geometry.size.width)
                        .offset(x: self.translation.width, y: self.translation.height)
                        
                    } else {
                        VStack(spacing: 0) {
                            ForEach(0..<self.numberOfElements, id: \.self) { index in
                                self.content(index, self.calculateTransform(for: index, size: geometry.size))
                                    .frame(height: geometry.size.height)
                            }
                        }
                        .offset(y: self.startOffSet(height: geometry.size.height))
                        .offset(x: self.translation.width, y: self.translation.height + -CGFloat(self.currentIndex) * geometry.size.height)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
            .animation(.spring())
            .gesture(
                DragGesture()
                    .onChanged({ (value) in
                       if self.isDragEnabled {
                            self.previous = value
                            if self.orientation == .horizontal {
                                self.translation.width = value.translation.width
                                if self.dragToDismiss {
                                    self.translation.height = abs(value.translation.height) > abs(self.translation.width) ? value.translation.height : self.translation.height
                                }
                            } else {
                                self.translation.height = value.translation.height
                                if self.dragToDismiss {
                                    self.translation.width = abs(value.translation.width) > abs(self.translation.height) ? value.translation.width : self.translation.width
                                    self.controlsOpacity = self.backgroundOpacity(size: geometry.size)
                                }
                            }
                        }
                    })
                    .onEnded { value in
                       if self.isDragEnabled {
                            withAnimation {
                                if let prev = self.previous {
                                    let ev = self.orientation == .vertical ? abs(prev.translation.height) >= abs(prev.translation.width) : abs(prev.translation.width) > abs(prev.translation.height)
                                    
                                    if ev {
                                        let velocityTreshold: CGFloat = screenSize.width == 375 ? 125 : 200
                                        let offset = self.orientation == .horizontal ? value.translation.width / geometry.size.width :
                                            value.translation.height / geometry.size.height
                                        let velocity = self.orientation == .horizontal ? abs(value.translationVelocity(base: prev).x) : abs(value.translationVelocity(base: prev).y)
                                        let newIndex = velocity >= velocityTreshold ? offset < 0 ? self.currentIndex + 1 : self.currentIndex - 1 : Int((CGFloat(self.currentIndex) - offset).rounded())
                                        self.currentIndex = min(max(Int(newIndex), 0), self.numberOfElements - 1)
                                    } else {
                                        if self.dragToDismiss {
                                            let velocityTreshold: CGFloat = screenSize.width == 375 ? 125 : 200
                                            let percentage = self.orientation == .vertical ? abs(value.translation.width) / geometry.size.width : abs(value.translation.height) / geometry.size.height
                                            let velocity = self.orientation == .vertical ? abs(value.translationVelocity(base: prev).x) : abs(value.translationVelocity(base: prev).y)
                                            let percentageDismiss = percentage >= 0.15
                                            let velocityDismiss = velocity >= velocityTreshold
                                            if percentageDismiss || velocityDismiss {
                                                self.previous = nil
                                                self.controlsOpacity = 1
                                                self.onDismiss?()
                                            }
                                        }
                                    }
                                }
                                self.translation = .zero
                            }
                        }
                }
            )
        }
    }
}

public extension DragGesture.Value {
    func translationVelocity(base value: DragGesture.Value) -> CGPoint {
        let timeInterval = self.time.timeIntervalSince(value.time)

        let diffXInTimeInterval = Double(self.translation.width - value.translation.width)
        
        let diffYInTimeInterval = Double(self.translation.height - value.translation.height)

        let velocityX = diffXInTimeInterval / timeInterval
        
        let velocityY = diffYInTimeInterval / timeInterval
        
        return CGPoint(x: velocityX, y: velocityY)
    }
}
