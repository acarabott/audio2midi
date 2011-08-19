s.waitForBoot {
    a = Amp2MIDI.new
};
a.voicePreset
a.start
a.midiCtlNum = 7
a.percPreset
(
w = Window("Amplitude To MIDI", Rect(0,0,900,600)).front;
w.addFlowLayout;

~menu = EZPopUpMenu(w, 
    Rect(10, 10, 350, 22),
    "MIDI Output Device",
    MIDIClient.destinations.collect({|item, i| (item.device + "-" + item.name).asSymbol -> {|a| "set MIDI Device".postln;}}),
    labelWidth:105,
    gap:10@10
);

~displayButton = Button(w, 120@22)
        .states_([
            ["Disable Metering", Color.white, Color.black],
            ["Enable Metering", Color.black, Color.white]
        ]) 
        .action_({|butt|
            // a.display = false;
			butt.value.postln;
            butt.states[butt.value].postln;
			if(butt.value == 0) {
				~audioResponder.action = ~meteringFunc;
			} {
				~audioResponder.action = {};
				~meter.value = 0;
			};
        });

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
    .value_(a.audioMax)
    .step_(0.01)
    .clipLo_(0)
    .clipHi_(1.0)
    .scroll_(false);
    
~audioRange = RangeSlider(~audioComp, 80@400)
    .hi_(a.audioMax)
    .lo_(a.audioMin)
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
    .value_(a.audioMin)
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
	
~meteringFunc = {|t, r, msg|
	{
		~meter.value = msg[3].ampdb.linlin(-40, 0, 0, 1);
		~meter.peakLevel = msg[4].ampdb.linlin(-40, 0, 0, 1);
		~midiLevel.string_(msg[3].linlin(a.audioMin, a.audioMax, a.midiMin, a.midiMax).asInteger.asString);
	}.defer;
};

~audioResponder = OSCresponderNode(s.addr, \a2m_levels, ~meteringFunc).add;
~audioResponder.action = ~meteringFunc;
w.onClose_({
    ~audioResponder.remove;
})
);

/*
    TODO Decay on meter seems a bit funny. Seems to increase displayed volume and keeps meter red.
*/
