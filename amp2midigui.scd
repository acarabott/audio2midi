s.waitForBoot {
    a = AmpToMIDI.new;
};
x = AmpToMIDIGUI.new(a, "presets")

{x.meter.value_(1)}.defer(2)
(
w = Window("Amplitude To MIDI", Rect(0,0,900,600)).front;
w.addFlowLayout;
~titleFont = Font(Font.defaultSansFace, 20);
~meterMasterComp = CompositeView(w, 440@590);
~meterMasterComp.addFlowLayout;
~meterMasterComp.decorator.left = 28;
~meterComp = CompositeView(~meterMasterComp, 80@460);
~meterComp.addFlowLayout;
~meterComp.decorator.top = 28;
~meter = LevelIndicator(~meterComp, 80@400)
    .warning_(0.7)
    .critical_(0.95)
    .numTicks_(11)
    .numMajorTicks_(3)
    .drawsPeak_(true);
~meterComp.decorator.top = 56;
~audioLabel = SCStaticText(~meterComp, 80@20)
    .string_("Audio Input")
    .align_(\center);

~audioComp = CompositeView(~meterMasterComp, 80@460);
~audioComp.addFlowLayout;
~audioMax = NumberBox(~audioComp, 80@20)
    .value_(a.audioMax.ampdb.linlin(-40, 0, 0, 1))
    .step_(0.01)
    .clipLo_(0)
    .clipHi_(1.0)
    .scroll_(false);
~audioRange = SCRangeSlider(~audioComp, 80@400)
    .hi_(a.audioMax.ampdb.linlin(-40, 0, 0, 1))
    .lo_(a.audioMin.ampdb.linlin(-40, 0, 0, 1))
    .step_(0.01)
	.action_({|slider|
		var hi = slider.hi.linlin(0, 1, -40, 0).dbamp;
		var lo = slider.lo.linlin(0, 1, -40, 0).dbamp;
        ~audioMax.value_(slider.hi);
        ~audioMin.value_(slider.lo);
        a.audioMax_(hi);
        a.audioMin_(lo);		
    });
~audioMin = NumberBox(~audioComp, 80@20)
    .value_(a.audioMin.ampdb.linlin(-40, 0, 0, 1))
    .step_(0.01)
    .clipLo_(0)
    .clipHi_(1.0)
    .scroll_(false);
~audioMin.action_({|box| 
    a.audioMin_(box.value.linlin(0, 1, -40, 0).dbamp);
    ~audioRange.lo_(box.value);
});
~audioMax.action_({|box| 
    a.audioMax_(box.value.linlin(0, 1, -40, 0).dbamp);
    ~audioRange.hi_(box.value);
});

~audioLabel = SCStaticText(~audioComp, 80@20)
    .string_("Audio Range")
    .align_(\center);

~meterMasterComp.decorator.left = 236;
~midiComp = CompositeView(~meterMasterComp, 80@460);
~midiComp.addFlowLayout;
~midiComp.decorator.top = 28;
~midiMeter = LevelIndicator(~midiComp, 80@400)
    .warning_(0.7)
    .critical_(0.95)
    .numTicks_(11)
    .numMajorTicks_(3)
    .drawsPeak_(false);

~midiComp.decorator.top = 56;
~midiInputMeter = SCStaticText(~midiComp, 80@20)
    .string_("MIDI Output")
    .align_(\center);

~midiSlideComp = CompositeView(~meterMasterComp, 80@460);
~midiSlideComp.addFlowLayout;

~midiMax = NumberBox(~midiSlideComp, 80@20)
    .value_(a.midiMax)
    .step_(1)
    .clipLo_(0)
    .clipHi_(127)
    .scroll_(false);

~midiRange = RangeSlider(~midiSlideComp, 80@400)
    .hi_(a.midiMax.linlin(0, 127, 0, 1))
    .lo_(a.midiMin.linlin(0, 127, 0, 1))
    .step_(1/128)
	.action_({|slider|
	    var max = slider.hi.linlin(0, 1, 0, 127).asInteger;
	    var min = slider.lo.linlin(0, 1, 0, 127).asInteger;
        ~midiMax.value_(max);
        ~midiMin.value_(min);
        a.midiMax_(max);
        a.midiMin_(min);		
    });
~midiMin = NumberBox(~midiSlideComp, 80@20)
    .value_(a.midiMin)
    .step_(1)
    .clipLo_(0)
    .clipHi_(127)
    .scroll_(false);
~midiMin.action_({|box| 
    a.midiMin_(box.value);
    ~midiRange.lo_(box.value.linlin(0, 127, 0, 1));
});
~midiMax.action_({|box| 
    a.midiMax_(box.value);
    ~midiRange.hi_(box.value.linlin(0, 127, 0, 1));
});
~midiMeterLabel = SCStaticText(~midiSlideComp, 80@20)
    .string_("MIDI Range")
    .align_(\center);

~meterMasterComp.decorator.top = 25;
~startStop = Button(~meterMasterComp, 430@100)
    .states_([
        ["OFF", Color.white, Color.black],
        ["ON", Color.black, Color.green]
    ])
    .action_({|butt|
        if(butt.value == 1) {
            a.start;
        } {
            a.stop;
            {
                ~meter.value = 0;
                ~midiMeter.value = 0;
            }.defer;
        };
    })
    .font_(~titleFont);
    


~meteringFunc = {|t, r, msg|    
	{
		~meter.value = msg[3].ampdb.linlin(-40, 0, 0, 1);
		~meter.peakLevel = msg[4].ampdb.linlin(-40, 0, 0, 1);
    }.defer;
};

~audioResponder = OSCresponderNode(nil, \a2m_levels, ~meteringFunc).add;
~audioResponder.action = ~meteringFunc;
~audioMidiResponder = OSCresponderNode(nil, \a2m_midi, {}).add;
~audioMidiResponder.action_({|t, r, msg| 
    {   
        ~midiMeter.value = msg[3].ampdb.linlin(((-40).dbamp*a.audioMax).ampdb, ((0).dbamp*a.audioMax).ampdb, a.midiMin/128, (a.midiMax+1)/128);
    }.defer;
});
);
(
~controlsComp = CompositeView(w, 440@590);
~controlsComp.addFlowLayout;
// ~controlsComp.background_(Color.red);
~audioLabel = StaticText(~controlsComp, 430@30)
    .background_(Color.black)
    .stringColor_(Color.white)
    .string_("Audio Controls")
    .align_(\centered)
    .font_(Font(Font.defaultSansFace, 20));

~controlsComp.decorator.nextLine;
~controlsComp.decorator.nextLine;

~inputChannel = EZPopUpMenu(~controlsComp,
    160@22,
    "Audio Input Channel",
    (1..8).collect({ |item, i| item.asSymbol -> {}}),
    globalAction:{|menu| a.audioIn = menu.value;},
    labelWidth:112,
    gap:10@10
);

~controlsComp.decorator.nextLine;
~controlsComp.decorator.nextLine;
~attack = EZNumber(~controlsComp, 
    73@20,
    "Attack",
    ControlSpec(0, inf, \lin, 0.01, a.attack),
    {|ez| 
        ez.setColors(numStringColor:Color.black);
        a.attack_(ez.value);
    },
    initVal: a.attack,
    numberWidth:40,
    gap:10@10
);
~attack.numberView.keyDownAction_({
    ~attack.setColors(numStringColor:Color.red);
});

~controlsComp.decorator.left = (~controlsComp.bounds.width/3);
~release = EZNumber(~controlsComp, 
    100@20,
    "Release",
    ControlSpec(0, inf, \lin, 0.01, a.release),
    {|ez| 
        ez.setColors(numStringColor:Color.black);
        a.release_(ez.value);
    },
    a.release,
    numberWidth:40,
    gap:10@10
);
~release.numberView.keyDownAction_({
    ~release.setColors(numStringColor:Color.red);
});
~controlsComp.decorator.left = (~controlsComp.bounds.width*(2/3));
~smoothing = EZNumber(~controlsComp, 
    100@20,
    "Smoothing",
    ControlSpec(0, inf, \lin, 0.01, a.smoothing),
    {|ez| 
        ez.setColors(numStringColor:Color.black);
        a.smoothing_(ez.value);
    },
    initVal: a.smoothing,
    numberWidth:40,
    gap:10@10
);
~smoothing.numberView.keyDownAction_({
    ~smoothing.setColors(numStringColor:Color.red);
});
~controlsComp.decorator.nextLine;
~controlsComp.decorator.nextLine;
~path = "presets";

~basicData = ['Voice' -> [a.voiceAttack, a.voiceRelease, a.voiceLag], 'Percussion' -> [a.percAttack, a.percRelease, a.percLag]];
~basicDictionary = Dictionary();
~basicData.do { |item, i|
    ~basicDictionary.add(item);
};
~updatePresets = {
    if(File.exists(~path)) {
        ~presetData = Object.readArchive(~path);
        ~presetArray = Array.newClear(~presetData.size);
        ~presetData.keysValuesDo { |key, value, i|
            ~presetArray[i] = key -> value
        };
        ~data = ~basicData ++ ~presetArray;
        // ~data = Dictionary().putAll(~basicDictionary, ~presetData);
    } {
        ~data = ~basicData;
    };
    
    ~presets.items = ~data;
};

~presets = EZPopUpMenu(~controlsComp,
    430@22,
    "Input Presets",
    ~basicData,
    globalAction: {|menu|
        var data = menu.items[menu.value].value;
        ~attack.valueAction_(data[0]);
        ~release.valueAction_(data[1]);
        ~smoothing.valueAction_(data[2]);
    },
    labelWidth:72,
    gap:50@10
);
~updatePresets.();
~controlsComp.decorator.nextLine;
~controlsComp.decorator.nextLine;
~presetLabel = StaticText(~controlsComp, 120@22)
    .string_("Save as");
~presetTitle = TextField(~controlsComp, 305@22);
~controlsComp.decorator.nextLine;
~controlsComp.decorator.nextLine;

~presetSave = Button(~controlsComp, 120@22)
    .states_([
        ["Save preset", Color.black, Color.white]
    ])
    .action_({|butt|
        var title;
        if(File.exists(~path)) {
            ~loadedPresets = Object.readArchive(~path);
        };
        
        title = ~presetTitle.string;
        
        if(title.size > 0) {
            ~writeData = (~loadedPresets ? Dictionary()).add(title.asSymbol -> [a.attack, a.release, a.smoothing]);
            ~writeData.writeArchive(~path);
            ~updatePresets.();            
        };
    });
~controlsComp.decorator.left = (~controlsComp.bounds.width/3);
~deletePreset = Button(~controlsComp, 120@22)
    .states_([
        ["Delete preset", Color.black, Color.yellow],
    ]);
~controlsComp.decorator.left = ~controlsComp.bounds.width*(2/3);
~confirm = Button(~controlsComp, 60@22)
    .states_([
        ["OK", Color.white, Color.red]
    ])
    .visible_(false);
~controlsComp.decorator.left = 374;
~cancel = Button(~controlsComp, 60@22)
    .states_([
        ["Cancel", Color.black, Color.gray]
    ])
    .visible_(false);
~deletePreset.action_({|butt|
    if(~presets.value >= ~basicData.size) {
        ~confirm.visible = true;
        ~cancel.visible = true;    
    }
});
);
(
~confirm.action_({|butt|
    var complete;
    complete = Object.readArchive(~path);
    complete.removeAt(~presets.item);
    
    complete.writeArchive(~path);
    ~updatePresets.();
    ~confirm.visible = false;
    ~cancel.visible = false;
});

~cancel.action_({|butt|
    ~confirm.visible = false;
    ~cancel.visible = false;
});

~controlsComp.decorator.nextLine;
~controlsComp.decorator.nextLine;
~controlsComp.decorator.nextLine;
~controlsComp.decorator.nextLine;

~midiLabel = StaticText(~controlsComp, 430@30)
    .background_(Color.black)
    .stringColor_(Color.white)
    .string_("MIDI Controls")
    .align_(\centered)
    .font_(~titleFont);

~controlsComp.decorator.nextLine;
~controlsComp.decorator.nextLine;

~menu = EZPopUpMenu(~controlsComp, 
    430@22,
    "MIDI Output Device",
    MIDIClient.destinations.collect({|item, i| (item.device + "-" + item.name).asSymbol -> {}}),
    globalAction: {|menu| a.midiDevice_(menu.value)},
    labelWidth:105,
    gap:25@10
);
~controlsComp.decorator.nextLine;
~midiChannel = EZNumber(~controlsComp, 
    108@22, 
    "MIDI Channel",
    ControlSpec(1, 16, \lin, 1, 0, "Chan"),
    action: { |ez| a.midiChan = ez.value - 1 },
    initVal: 0,
    initAction: false,
    numberWidth: 33,
    gap:10@10
);
~controlsComp.decorator.left = (~controlsComp.bounds.width/2);
~midiControlNum = EZNumber(~controlsComp, 
    136@22, 
    "MIDI Control Value",
    ControlSpec(0, 127, step:1),
    action: { |ez| a.midiCtlNum = ez.value },
    initVal: a.midiCtlNum,
    initAction: false,
    numberWidth:33,
    gap:10@10
);

~controlsComp.decorator.nextLine;

~commonControls = EZPopUpMenu(~controlsComp, 
    430@22,
    "Useful Control Values",
    [
        '3 - Freely Assignable'                             -> {var val = 3;    ~midiControlNum.valueAction_(val); },
        '7 - Channel Volume'                                -> {var val = 7;    ~midiControlNum.valueAction_(val); },
        '10 - Pan'                                           -> {var val = 10;	~midiControlNum.valueAction_(val); },
        '1 - Modulation Wheel'                              -> {var val = 1;	~midiControlNum.valueAction_(val); },
        '11 - Expression Controller'                         -> {var val = 11;	~midiControlNum.valueAction_(val); },
        '2 - Breath Controller'                             -> {var val = 2;	~midiControlNum.valueAction_(val); },
        '4 - Foot Controller'                               -> {var val = 4;	~midiControlNum.valueAction_(val); },
        '5 - Portamento Time'                               -> {var val = 5;	~midiControlNum.valueAction_(val); },                                    
        '64 - Sustain Pedal - <=63:OFF >=64:ON'              -> {var val = 64;	~midiControlNum.valueAction_(val); },
        '65 - Portamento - <=63:OFF >=64:ON'                 -> {var val = 65;	~midiControlNum.valueAction_(val); },
        '66 - Sostenuto - <=63:OFF >=64:ON'                  -> {var val = 66;	~midiControlNum.valueAction_(val); },
        '67 - Soft Pedal - <=63:OFF >=64:ON'                 -> {var val = 67;	~midiControlNum.valueAction_(val); },
        '68 - Legato Footswitch - <=63:Normal >=64:Legato'   -> {var val = 68;	~midiControlNum.valueAction_(val); },
        '9 - Undefined 1'                                   -> {var val = 9;	~midiControlNum.valueAction_(val); },
        '14 - Undefined 2'                                   -> {var val = 14;	~midiControlNum.valueAction_(val); },
        '15 - Undefined 3'                                   -> {var val = 15;	~midiControlNum.valueAction_(val); },
        '20 - Undefined 4'                                   -> {var val = 20;	~midiControlNum.valueAction_(val); }
    ],
    initVal: 1,
    labelWidth:119,
    gap:10@10
);

~controlsComp.decorator.top = 540;
~promo = StaticText(~controlsComp, 430@22)
    .string_("www.arthurcarabott.com / arthur@arthurcarabott.com")
    .align_(\right);

w.onClose_({
    ~audioResponder.remove;
    ~audioMidiResponder.remove;
});
);



/*
        
    1.1
    TODO peak on midi gets fucked
    TODO Freeze/lock button
    TODO Multiple channels
    TODO Audio file playback?
    TODO Audio device select
    TODO Swap Lag for LagUD?
    TODO Multiple parameters
    TODO MIDI graph?
    TODO Different scaling methods for audio -> MIDI
*/


~audioDevice = EZPopUpMenu(w, 
    Rect(10, 10, 350, 22),
    "Audio Input Device",
    ServerOptions.inDevices.collect({|item, i| 
        var device = ServerOptions.inDevices[i];
        
        if(i == 0 || (i==1)) {
            device = nil;
        };
        
        item.tr($(, $ ).tr($), $ ).asSymbol -> {
            a.s.options.inDevice_(device);
            ~reboot.visible_(true);
        }
    }),
    labelWidth:105,
    gap:10@10
);

~reboot = Button(w, 80@22)
    .states_([
        ["Apply", Color.white, Color.red]
    ])
    .action_({|butt|
        {
            a.s.quit;
            // a.s.sync;
            a.s.boot;
        }.fork;
        butt.visible_(false);
    })
    .visible_(false);

a.s.options.inDevice = nil;
a.s.boot
a.s.quit
a.s.options.inDevice
s.quit
s.options.inDevice = nil
s.boot
s.options.class.openHelpFile
~reboot.states_([
        ["Apply", Color.white, Color.red]
    ])
w.refresh
~reboot.visible = true
s.options.numInputBusChannels

Server.default = Server.internal;
s.options.inDevice_(ServerOptions.inDevices[0]);
s.options.outDevice_(ServerOptions.outDevices[0]);
s

s.options.inDevice = nil;
s.options.outDevice = nil;
s.options.inDevice = ServerOptions.inDevices[0];

// ~midiGraph = UserView(w, 400@200);
// 
// ~midiGraph.background = Color.red
// 
// ~midiGraph.drawFunc_({
//     Pen.moveTo(0@50);
//     Pen.lineTo(10@50);
//     Pen.fillStroke;
    // Pen.fillOval(Rect(200, 200, sin(~midiGraph.frame*0.031)*200, sin(~midiGraph.frame*0.044)*200));
// })

// ~midiGraph.animate = true;
//         ~midiGraph.drawFunc_({
//             var graphMaxY = ~midiGraph.bounds.height;
//             var graphMaxX = ~midiGraph.bounds.width;
// 
//             var graphY = midiVal.linlin(0, 127, 0, graphMaxY);
//             
//             // graphY.postln;
//             // (~graphIndex%graphMaxX).postln;
//             ~graphData[~graphIndex%graphMaxX] = graphY;
//             
//             Pen.moveTo(0@0);
//             ~graphData.do { |item, i|
//                 // i@item.postln;
//                 // Pen.moveTo(i@graphY-(item+1));
//                 // Pen.lineTo((i+2)@graphY-(item+1));
//             };
//             Pen.fillStroke;
//             ~graphIndex = ~graphIndex + 1;
//             // Pen.moveTo(~graphIndex@midiVal.linlin(0, 127, graphMaxX, 0));
//             // Pen.lineTo(~graphIndex+10@midiVal.linlin(0, 127, graphMaxX, 0));
//             // Pen.fillStroke;
//             // Pen.moveTo(~graphIndex@midiVal.linlin(0, 127, 0, ~midiGraph.bounds.height));
//             // Pen.lineTo(50@midiVal.linlin(0, 127, 0, ~midiGraph.bounds.height));
//             // Pen.fillStroke;
//         });
