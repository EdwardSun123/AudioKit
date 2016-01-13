//
//  Conductor.swift
//  SwiftSynth
//
//  Created by Aurelius Prochazka on 1/11/16.
//  Copyright © 2016 AudioKit. All rights reserved.
//

import AudioKit

class Conductor {
    /// Globally accessible singleton
    static let sharedInstance = Conductor()
    
    let audiokit = AKManager.sharedInstance
    var midi = AKMIDI()
    
    var fm = AKFMOscillatorInstrument(voiceCount: 12)
    
    var sine1     = AKOscillatorInstrument(waveform: AKTable(.Sine), voiceCount: 12)
    var triangle1 = AKTriangleInstrument(voiceCount: 12)
    var sawtooth1 = AKSawtoothInstrument(voiceCount: 12)
    var square1   = AKSquareInstrument(voiceCount: 12)
    
    var sine2     = AKOscillatorInstrument(waveform: AKTable(.Sine), voiceCount: 12)
    var triangle2 = AKTriangleInstrument(voiceCount: 12)
    var sawtooth2 = AKSawtoothInstrument(voiceCount: 12)
    var square2   = AKSquareInstrument(voiceCount: 12)
    
    var noise = AKNoiseInstrument(whitePinkMix: 0.5, voiceCount: 12)
    
    var sourceMixer = AKMixer()
    
    var bitCrusher: AKBitCrusher?
    var bitCrushMixer: AKDryWetMixer?
    var fatten: Fatten
    var filterSection: FilterSection
    var multiDelay: MultiDelay
    var multiDelayMixer: AKDryWetMixer?
    
    var filterSectionParameters: [Double] = []
    
    var masterVolume = AKMixer()
    var reverb: AKReverb2?

    
    init() {
        
        fm.output.volume = 0.4
        noise.output.volume = 0.2
        
        midi.openMIDIIn("Session 1")
        
        sourceMixer = AKMixer(sine1, triangle1, sawtooth1, square1, fm, noise)
        
        bitCrusher = AKBitCrusher(sourceMixer)
        bitCrushMixer = AKDryWetMixer(sourceMixer, bitCrusher!, balance: 0)
        
        filterSection = FilterSection(bitCrushMixer!)
        
        fatten = Fatten(filterSection)
        multiDelay = MultiDelay(fatten)
        multiDelayMixer = AKDryWetMixer(fatten, multiDelay, balance: 0)
        
        masterVolume = AKMixer(multiDelayMixer!)
        reverb = AKReverb2(masterVolume)
        reverb!.decayTimeAt0Hz = 2.0
        audiokit.audioOutput = reverb
        audiokit.start()
        
        let defaultCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()
        
        defaultCenter.addObserverForName(AKMIDIStatus.NoteOn.name(), object: nil, queue: mainQueue, usingBlock: handleMIDINotification)
        defaultCenter.addObserverForName(AKMIDIStatus.NoteOff.name(), object: nil, queue: mainQueue, usingBlock: handleMIDINotification)

    }
    
    func handleMIDINotification(notification: NSNotification) {
        let note = Int((notification.userInfo?["note"])! as! NSNumber)
        let velocity = Int((notification.userInfo?["velocity"])! as! NSNumber)
        if notification.name == AKMIDIStatus.NoteOn.name() && velocity > 0 {
            
            switch 0 { // presumably something else
            case 0:
                sine1.playNote(note, velocity: velocity)
            case 1:
                triangle1.playNote(note, velocity: velocity)
            case 2:
                sawtooth1.playNote(note, velocity: velocity)
            case 3:
                square1.playNote(note, velocity: velocity)
            default:
                break
                // do nothing
            }
            fm.playNote(note, velocity: velocity)
            noise.playNote(note, velocity: velocity)
            
        } else if (notification.name == AKMIDIStatus.NoteOn.name() && velocity == 0) || notification.name == AKMIDIStatus.NoteOff.name() {
            
            
            switch 0 { // presumeably something else
            case 0:
                sine1.stopNote(note)
            case 1:
                triangle1.stopNote(note)
            case 2:
                sawtooth1.stopNote(note)
            case 3:
                square1.stopNote(note)
            default:
                break
                // do nothing
            }
            fm.stopNote(note)
            noise.stopNote(note)
            
        }
    }
    
}