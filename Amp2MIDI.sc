Amp2MIDI {

    var <s;
    var midiOut;
    var responder;
    var <synth;
    
    var <>display;
    
    var <audioIn;
    var <>audioMin;
    var <>audioMax;
    
    var midiDevice;
    var <>midiMin;
    var <>midiMax;
    var <>midiChan;
    var <>midiCtlNum;
    
    var <attack;
    var <release;
    var <lag;
    
    var <voiceAttack;
    var <voiceRelease;
    var <voiceLag;
    var <percAttack;
    var <percRelease;
    var <percLag;
    
    var responderDefault;
    
    *new {
        ^super.new.amp2midiInit;
    }

    amp2midiInit {
        s = Server.default;
        
        audioIn        = 0;
        audioMin       = 0;
        audioMax       = 0.1;

        midiMin        = 0;
        midiMax        = 127;
		midiDevice     = 0;
        midiChan       = 0;
        midiCtlNum     = 7;

        display        = false;
        
        voiceAttack    = 1;
        voiceRelease   = 2;
        voiceLag       = 1;
        percAttack     = 0.01;
        percRelease    = 0.01;
        percLag        = 0.1;
        
        {
            this.initSynthDefs;
            s.sync;
            // this.initSynth;            
        }.fork;
        this.initMIDI;
        // this.initResponder;
        this.voicePreset;
    }
    
    initMIDI {
        MIDIClient.init;
        midiOut = MIDIOut(midiDevice);
        midiOut.latency = 0;
    }
    
    initSynthDefs {
        SynthDef(\AmpListener) { |out=0, in=0, attack=0.01, release=0.01, mul=1.0, add=0, rate=24, lag=0.05, meter=24|
            var sig = SoundIn.ar(in);
            var amp = Amplitude.kr(sig, attack, release, mul, add);
            var lagged = Lag.kr(amp, lag);
            var sigImp = Impulse.kr(rate);
            var meterImp = Impulse.kr(meter);
            
            SendReply.kr(sigImp, \a2m_midi, lagged);
            
            SendReply.kr(meterImp, \a2m_levels, [ amp, K2A.ar(Peak.ar(sig, Delay1.ar(meterImp))).lag(0, 3)]
			);
        }.add;    
    }

    initResponder {
        responderDefault = {|t, r, msg| 
            var amp = msg[3];
            var val = amp.linlin(audioMin, audioMax, midiMin, midiMax).asInteger;
            midiOut.control(midiChan, midiCtlNum, val);
            if(display) {
                amp.postln;
            };
        };
        
        responder = OSCresponderNode(s.addr, \a2m_midi, responderDefault).add;
    }
    
    initSynth {
        synth = Synth(\AmpListener, [\in, audioIn, \attack, attack, \release, release, \lag, lag, \rate, 60]);
    }
    
    audioIn_{|index|
        audioIn = index;
        synth.set(\in, audioIn);
    }
    
    midiDevice {
        ^MIDIClient.destinations[midiDevice];
    }
    
    midiDevice_{|index|
        midiDevice = index;
        midiOut = MIDIOut(midiDevice);    
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
    
    stop {
        synth.free;
        responder.remove;
    }
    
    start {
        this.initResponder;
        this.initSynth;
    }
}

/*
    TODO Lock button
    
*/