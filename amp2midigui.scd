s.waitForBoot {
    a = Amp2MIDI.new
};



a.display = true
a.stop
a.start

w = Window("Amplitude To MIDI", Rect(0,0,900,600)).front;
w.addFlowLayout;

~menu = EZPopUpMenu(w, 
    Rect(10, 10, 350, 22),
    "MIDI Output Device",
    MIDIClient.destinations.collect({|item, i| (item.device + "-" + item.name).asSymbol -> {|a| "set MIDI Device"}}),
    labelWidth:105,
    gap:10@10
);

~displayButton.remove;
~displayButton = Button(w, 120@22)
        .states_([
            ["Enable Metering", Color.black, Color.white],
            ["Disable Metering", Color.white, Color.black]
        ])
        .action_({|butt|
            // a.display = false;
            butt.states[butt.value].postln;
        });
        
~meter = SCLevelIndicator(w, 80@400)
    .warning_(0.7)
    .critical_(0.95)
    .numTicks_(11)
    .numMajorTicks_(3)
    .drawsPeak_(true);

~audioMin = NumberBox(w, 40@40)

RangeSlider