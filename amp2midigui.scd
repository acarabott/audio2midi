
s.waitForBoot {
    a = Amp2MIDI.new;    
}
a.s.sync

(
w = Window("Amplitude To MIDI", Rect(0,0,900,600)).front;
w.addFlowLayout;

~menu = EZPopUpMenu(w, 
    Rect(10, 10, 350, 22),
    "MIDI Output Device",
    MIDIClient.destinations.collect({|item, i| (item.device + "-" + item.name).asSymbol -> {}}),
    globalAction: {|menu| a.midiDevice_(menu.value)},
    labelWidth:105,
    gap:10@10
);

~meterComp = CompositeView(w, 80@460);
~meterComp.addFlowLayout;
~meterSpacer = StaticText(~meterComp, 80@20);
~meter = SCLevelIndicator(~meterComp, 80@400)
    .warning_(0.7)
    .critical_(0.95)
    .numTicks_(11)
    .numMajorTicks_(3)
    .drawsPeak_(true);

~audioComp = CompositeView(w, 80@460);
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
    .string_("Input Range")
    .align_(\center);

~midiLevel = StaticText(w, 80@20)
	.string_("120");

// ~graphIndex = 0;
// ~graphData = Array.newClear(~midiGraph.bounds.width);

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
    var midiVal = msg[3].linlin(a.audioMin, a.audioMax, a.midiMin, a.midiMax).asInteger;
    {
        ~midiLevel.string_(midiVal.asString);        
    }.defer;

});

~midiChannel = EZNumber(w, 
    110@22, 
    "MIDI Channel",
    ControlSpec(1, 16, \lin, 1, 0, "Chan"),
    { |ez| a.midiChan = ez.value - 1 },
    0,
    false,
    80,
    30
);

~midiControlNum = EZNumber(w, 
    140@22, 
    "MIDI Control Value",
    ControlSpec(0, 127, step:1),
    { |ez| a.midiCtlNum = ez.value },
    7,
    false,
    110,
    30
);
~commonControls = EZPopUpMenu(w, 
    450@22,
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
    labelWidth:120,
    gap:10@10
);

~attack = EZNumber(w, 
    160@20,
    "Attack: ",
    ControlSpec(0, inf, \lin, 0.01, a.attack),
    action: {|ez| a.attack_(ez.value)},
    initVal: a.attack
);

~release = EZNumber(w, 
    100@20,
    "Release: ",
    ControlSpec(0, inf, \lin, 0.01, a.release),
    {|ez| a.release_(ez.value)},
    a.release
);

~inputChannel = EZPopUpMenu(w,
    160@22,
    "Audio Input Channel",
    (1..8).collect({ |item, i| item.asSymbol -> {}}),
    globalAction:{|menu| a.audioIn = menu.value;},
    labelWidth:120
);

~startStop = Button(w, 60@60)
    .states_([
        ["Off", Color.white, Color.black],
        ["On", Color.black, Color.green]
    ])
    .action_({|butt|
        if(butt.value == 1) {
            a.start;
        } {
            a.stop;
        };
    });

w.onClose_({
    ~audioResponder.remove;
})
);


/*
    1.0
    TODO Lag/Smoothing control
    TODO Swap Lag for LagUD?
    TODO Audio device select
    TODO Audio file playback?
    TODO Clean up GUI
    TODO Logic 'learn' routine necessary?
    TODO Start/Stop button
    
    1.1
    TODO Multiple parameters
    TODO MIDI graph?
*/

a.stop

~audioDevice = EZPopUpMenu(w, 
    Rect(10, 10, 350, 22),
    "Audio Input Device",
    ServerOptions.inDevices.collect({|item, i| 
        var device = ServerOptions.inDevices[i];
        
        if(i == 0 || (i==1)) {
            device = nil;
        };
        "device: ".post; (device).postln;
        
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

Server.killAll

s.quit
s.boot
ServerOptions.devices
~midiGraph = UserView(w, 400@200);

~midiGraph.background = Color.red

~midiGraph.drawFunc_({
    Pen.moveTo(0@50);
    Pen.lineTo(10@50);
    Pen.fillStroke;
    // Pen.fillOval(Rect(200, 200, sin(~midiGraph.frame*0.031)*200, sin(~midiGraph.frame*0.044)*200));
})

~midiGraph.animate = true;
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
