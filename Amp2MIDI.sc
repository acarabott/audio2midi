Amp2MIDI {

    var s;
    var midiOut;
    var responder;
    var synth;
    
    var <>display;
    var <>audioMin;
    var <>audioMax;

    var <>midiMin;
    var <>midiMax;
    var <>midiChan;
    var <>midiCtlNum;
    
    var <attack;
    var <release;
    var <lag;
    
    var voiceAttack;
    var voiceRelease;
    var voiceLag;
    var percAttack;
    var percRelease;
    var percLag;
    
    var responderDefault;
    
    *new { 
        ^super.new.amp2midiInit;
    }

    amp2midiInit {
        s = Server.default;
        
        audioMin       = 0;
        audioMax       = 0.5;
        midiMin        = 0;
        midiMax        = 127;
        midiChan       = 0;
        midiCtlNum     = 7;
        display        = false;
        
        voiceAttack    = 1;
        voiceRelease   = 2;
        voiceLag       = 1;
        percAttack     = 0.01;
        percRelease    = 0.01;
        percLag        = 0.1;
        
        this.initMIDI;
        this.initResponder;
        this.initSynthDefs;
        this.initSynth;
        this.voicePreset;
    }
    
    initMIDI {
        MIDIClient.init;
        midiOut = MIDIOut(0);
        midiOut.latency = 0;
    }
    
    initSynthDefs {
        SynthDef(\AmpListener) { |out=0, in=0, attack=0.01, release=0.01, mul=1.0, add=0, rate=24, lag=0.05|
            var sig = SoundIn.ar(in);
            var amp = Amplitude.kr(sig, attack, release, mul, add);

            var imp = Impulse.kr(rate);

            SendTrig.kr(imp, 0, Lag.kr(amp, lag));

        }.load(s);
        
    }
    
    initResponder {
        responderDefault = {|t, r, msg| 
            var amp = msg[3];
            var val = amp.linlin(audioMin, audioMax, midiMin, midiMax).asInteger;
            midiOut.control(0, midiCtlNum, val);
            if(display) {
                amp.postln;
            };
        };
        
        responder = OSCresponderNode(s.addr, '/tr', responderDefault).add;
    }
    
    initSynth {
        synth = Synth(\AmpListener, [\attack, attack, \release, release, \lag, lag, \rate, 60]);
    }
    
    attack_{|val|
        attack = val;
        synth.set(\attack, attack);
    }
    
    release_{|val|
        release = val;
        synth.set(\release, release);
    }
    
    lag_{|val|
        lag = val;
        synth.set(\lag, lag);
    }
    
    voicePreset {
        attack = voiceAttack;
        release = voiceRelease;
        lag = voiceLag;
        synth.set(\attack, voiceAttack, \release, voiceRelease, \lag, voiceLag);
    }
    
    percPreset {
        attack = percAttack;
        release = percRelease;
        lag = percLag;
        synth.set(\attack, percAttack, \release, percRelease, \lag, percLag);
    }
    
    clear {
        synth.free;
        responder.remove;
    }
    
}