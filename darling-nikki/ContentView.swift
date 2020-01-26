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
                Text(model.name)
                Text(model.duration)
                Text(model.samples.count.description)
                Text(model.hr)
                Text(model.hrv)
                Text(model.isMeditating.description)
                Text(model.level.description)
                
        }
    }
}

struct ContentView: View {
    
    @ObservedObject var zensors = Zensors()
    
    var body: some View
    {
        VStack {
            Text("Zensors")
                List {
                    HStack
                        {
                            Text("Name")
                            Text("Duration")
                            Text("Samples")
                            Text("HR")
                            Text("HRV")
                            Text("Meditating")
                            Text("Level")
                    }
                        ForEach(zensors.current) {
                            
                            zensor in
                            
                            ZensorView(model: zensor)
                            
                    }
                }

                Button("Reset")
                {
                        
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
