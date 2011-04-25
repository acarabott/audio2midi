s.waitForBoot {
    a = Amp2MIDI.new
};

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
            ["Enable Metering", Color.black, Color.white],
            ["Disable Metering", Color.white, Color.black]
        ])
        .action_({|butt|
            // a.display = false;
            butt.states[butt.value].postln;
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
        var hi = slider.hi;
        var lo = slider.lo;
        
        ~audioMin.value_(lo);
        ~audioMax.value_(hi);
        a.audioMin_(lo);
        a.audioMax_(hi)
    });

~audioMin = NumberBox(~audioComp, 80@20)
    .value_(a.audioMin)
    .step_(0.01)
    .clipLo_(0)
    .clipHi_(1.0)
    .scroll_(false);

~audioMin.action_({|box| 
    a.audioMin_(box.value);
    ~audioRange.lo_(box.value);
});

~audioMax.action_({|box| 
    a.audioMax_(box.value);
    ~audioRange.hi_(box.value);
});

~audioLabel = SCStaticText(~audioComp, 80@20)
    .string_("Input Range")
    .align_(\center);
)
// ~audio = EZRanger(w, 80@400, " Audio Input Range ", ControlSpec(0, 1.0, \lin, 0.01, "amp"), {|v| v.postln}, [a.audioMin, a.audioMax], layout:\vert);