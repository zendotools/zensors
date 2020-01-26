//
//  ContentView.swift
//  darling-nikki
//
//  Created by Douglas Purdy on 1/24/20.
//  Copyright © 2020 Zendo Tools. All rights reserved.
//

import SwiftUI


struct ZensorView: View
{
    @ObservedObject var model : Zensor
    
    var body: some View
    {
        HStack
            {
                VStack {
                    
                    Image(systemName: "dot.radiowaves.right").resizable()
                        .frame(width: 33.0, height: 33.0).padding(5)
                    
                    Text(model.name).font(.system(size: 10))
                }
                HStack {
                    
                    Image(systemName: "stopwatch")
                    Text(model.duration).font(.system(size: 10)).bold()
                    
                    Image(systemName: "gauge")
                    Text(model.samples.count.description).font(.system(size: 10)).bold()
                    
                }
                HStack {
                    
                    Image(systemName: "heart")
                    Text(model.hr).font(.system(size: 10)).bold()
                    
                    Image(systemName: "waveform.path.ecg")
                    Text(model.hrv).font(.system(size: 10))
                    
                    Image(systemName: "eye.fill")
                    Text(model.isMeditating.description).font(.system(size: 10))
                    
                    Image(systemName: "list.number")
                    Text(model.level.description).font(.system(size: 10))
                }
                
        }
    }
}

struct ContentView: View {
    
    @ObservedObject var zensors = Zensors()
    
    var body: some View
    {
        VStack {
            Text("Zensors").font(.headline)
                List {
                        ForEach(zensors.current) {
                            
                            zensor in
                            
                            ZensorView(model: zensor)
                            
                    }
            }

                Button("Reset")
                {
                    self.zensors.reset()
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    
    
    static var previews: some View {
        ContentView()
    }
}
