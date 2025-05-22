//
//  DropTest.swift
//  ArtistMusicNew
//
//  Created by Theo Battaglia on 5/21/25.
//


import SwiftUI

struct DropTest: View {
    @State private var log: [String] = []

    var body: some View {
        VStack {
            Text("DROP HERE")
                .font(.largeTitle)
                .frame(maxWidth: .infinity, maxHeight: 200)
                .background(Color.green.opacity(0.25))
                .onAudioFileDrop { log.append(contentsOf:$0.map(\.lastPathComponent)) }

            List(log, id: \.self) { Text($0) }
        }
        .frame(width: 420, height: 300)
    }
}
