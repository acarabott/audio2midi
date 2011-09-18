AmpToMIDIGUI {
    var atm;
    var win;
    var titleFont;
    var meterMasterComp;
    var meterComp;
    var audioComp;
    var meter;
    var audioLabel;
    var audioMax;
    var audioRange;
    var audioMin;
    var audioLabel;
    var midiComp;
    var midiMeter;
    var midiInputMeter;
    var midiSlideComp;
    var midiMax;
    var midiRange;
    var midiMin;
    var midiMeterLabel;
    var startStop;
    var meteringFunc;
    var audioResponder;
    var audioMidiResponder;
    var controlsComp;
    var audioLabel;
    var inputChannel;
    var attack;
    var release;
    var smoothing;
    var path;
    var basicData;
    var basicDictionary;
    var updatePresets;
    var presets;
    var presetLabel;
    var presetTitle;
    var presetSave;
    var deletePreset;
    var confirm;
    var cancel;
    var midiLabel;
    var menu;
    var midiChannel;
    var midiControlNum;
    var commonControls;
    var promo;
    
    *new { |a_atm|
        ^super.new.init(a_atm);
    }

    init { |a_atm|
        atm = a_atm;
        win = Window("Amplitude To MIDI", Rect(0,0,900,600)).front;
        win.addFlowLayout;
        titleFont = Font(Font.defaultSansFace, 20);
        meterMasterComp = CompositeView(win, 440@590);
        meterMasterComp.addFlowLayout;
        meterMasterComp.decorator.left = 28;
        meterComp = CompositeView(meterMasterComp, 80@460);
        meterComp.addFlowLayout;
        meterComp.decorator.top = 28;
        meter = LevelIndicator(meterComp, 80@400)
            .warning_(0.7)
            .critical_(0.95)
            .numTicks_(11)
            .numMajorTicks_(3)
            .drawsPeak_(true);
        meterComp.decorator.top = 56;
        audioLabel = SCStaticText(meterComp, 80@20)
            .string_("Audio Input")
            .align_(\center);

        audioComp = CompositeView(meterMasterComp, 80@460);
        audioComp.addFlowLayout;
        audioMax = NumberBox(audioComp, 80@20)
            .value_(atm.audioMax.ampdb.linlin(-40, 0, 0, 1))
            .step_(0.01)
            .clipLo_(0)
            .clipHi_(1.0)
            .scroll_(false);
        audioRange = SCRangeSlider(audioComp, 80@400)
            .hi_(atm.audioMax.ampdb.linlin(-40, 0, 0, 1))
            .lo_(atm.audioMin.ampdb.linlin(-40, 0, 0, 1))
            .step_(0.01)
        	.action_({|slider|
        		var hi = slider.hi.linlin(0, 1, -40, 0).dbamp;
        		var lo = slider.lo.linlin(0, 1, -40, 0).dbamp;
                audioMax.value_(slider.hi);
                audioMin.value_(slider.lo);
                atm.audioMax_(hi);
                atm.audioMin_(lo);		
            });
        audioMin = NumberBox(audioComp, 80@20)
            .value_(atm.audioMin.ampdb.linlin(-40, 0, 0, 1))
            .step_(0.01)
            .clipLo_(0)
            .clipHi_(1.0)
            .scroll_(false);
        audioMin.action_({|box| 
            atm.audioMin_(box.value.linlin(0, 1, -40, 0).dbamp);
            audioRange.lo_(box.value);
        });
        audioMax.action_({|box| 
            atm.audioMax_(box.value.linlin(0, 1, -40, 0).dbamp);
            audioRange.hi_(box.value);
        });

        audioLabel = SCStaticText(audioComp, 80@20)
            .string_("Audio Range")
            .align_(\center);

        meterMasterComp.decorator.left = 236;
        midiComp = CompositeView(meterMasterComp, 80@460);
        midiComp.addFlowLayout;
        midiComp.decorator.top = 28;
        midiMeter = LevelIndicator(midiComp, 80@400)
            .warning_(0.7)
            .critical_(0.95)
            .numTicks_(11)
            .numMajorTicks_(3)
            .drawsPeak_(true);

        midiComp.decorator.top = 56;
        midiInputMeter = SCStaticText(midiComp, 80@20)
            .string_("MIDI Output")
            .align_(\center);

        midiSlideComp = CompositeView(meterMasterComp, 80@460);
        midiSlideComp.addFlowLayout;

        midiMax = NumberBox(midiSlideComp, 80@20)
            .value_(atm.midiMax)
            .step_(1)
            .clipLo_(0)
            .clipHi_(127)
            .scroll_(false);

        midiRange = RangeSlider(midiSlideComp, 80@400)
            .hi_(atm.midiMax.linlin(0, 127, 0, 1))
            .lo_(atm.midiMin.linlin(0, 127, 0, 1))
            .step_(1/128)
        	.action_({|slider|
        	    var max = slider.hi.linlin(0, 1, 0, 127).asInteger;
        	    var min = slider.lo.linlin(0, 1, 0, 127).asInteger;
                midiMax.value_(max);
                midiMin.value_(min);
                atm.midiMax_(max);
                atm.midiMin_(min);		
            });
        midiMin = NumberBox(midiSlideComp, 80@20)
            .value_(atm.midiMin)
            .step_(1)
            .clipLo_(0)
            .clipHi_(127)
            .scroll_(false);
        midiMin.action_({|box| 
            atm.midiMin_(box.value);
            midiRange.lo_(box.value.linlin(0, 127, 0, 1));
        });
        midiMax.action_({|box| 
            atm.midiMax_(box.value);
            midiRange.hi_(box.value.linlin(0, 127, 0, 1));
        });
        midiMeterLabel = SCStaticText(midiSlideComp, 80@20)
            .string_("MIDI Range")
            .align_(\center);

        meterMasterComp.decorator.top = 25;
        startStop = Button(meterMasterComp, 430@100)
            .states_([
                ["OFF", Color.white, Color.black],
                ["ON", Color.black, Color.green]
            ])
            .action_({|butt|
                if(butt.value == 1) {
                    atm.start;
                } {
                    atm.stop;
                    {
                        meter.value = 0;
                        midiMeter.value = 0;
                    }.defer;
                };
            })
            .font_(titleFont);



        meteringFunc = {|t, r, msg|    
        	{
        		meter.value = msg[3].ampdb.linlin(-40, 0, 0, 1);
        		meter.peakLevel = msg[4].ampdb.linlin(-40, 0, 0, 1);
            }.defer;
        };
        audioResponder = OSCresponderNode(nil, \a2m_levels, meteringFunc).add;
        audioResponder.action = meteringFunc;
        audioMidiResponder = OSCresponderNode(nil, \a2m_midi, {}).add;
        audioMidiResponder.action_({|t, r, msg| 
            {   
                midiMeter.value = msg[3].ampdb.linlin(((-40).dbamp*atm.audioMax).ampdb, ((0).dbamp*atm.audioMax).ampdb, atm.midiMin/128, (atm.midiMax+1)/128);
            }.defer;
        });
        controlsComp = CompositeView(win, 440@590);
        controlsComp.addFlowLayout;
        // controlsComp.background_(Color.red);
        audioLabel = StaticText(controlsComp, 430@30)
            .background_(Color.black)
            .stringColor_(Color.white)
            .string_("Audio Controls")
            .align_(\centered)
            .font_(Font(Font.defaultSansFace, 20));

        controlsComp.decorator.nextLine;
        controlsComp.decorator.nextLine;

        inputChannel = EZPopUpMenu(controlsComp,
            160@22,
            "Audio Input Channel",
            (1..8).collect({ |item, i| item.asSymbol -> {}}),
            globalAction:{|menu| atm.audioIn = menu.value;},
            labelWidth:112,
            gap:10@10
        );

        controlsComp.decorator.nextLine;
        controlsComp.decorator.nextLine;
        attack = EZNumber(controlsComp, 
            73@20,
            "Attack",
            ControlSpec(0, inf, \lin, 0.01, atm.attack),
            {|ez| 
                ez.setColors(numStringColor:Color.black);
                atm.attack_(ez.value);
            },
            initVal: atm.attack,
            numberWidth:40,
            gap:10@10
        );
        attack.numberView.keyDownAction_({
            attack.setColors(numStringColor:Color.red);
        });

        controlsComp.decorator.left = (controlsComp.bounds.width/3);
        release = EZNumber(controlsComp, 
            100@20,
            "Release",
            ControlSpec(0, inf, \lin, 0.01, atm.release),
            {|ez| 
                ez.setColors(numStringColor:Color.black);
                atm.release_(ez.value);
            },
            atm.release,
            numberWidth:40,
            gap:10@10
        );
        release.numberView.keyDownAction_({
            release.setColors(numStringColor:Color.red);
        });
        controlsComp.decorator.left = (controlsComp.bounds.width*(2/3));
        smoothing = EZNumber(controlsComp, 
            100@20,
            "Smoothing",
            ControlSpec(0, inf, \lin, 0.01, atm.smoothing),
            {|ez| 
                ez.setColors(numStringColor:Color.black);
                atm.smoothing_(ez.value);
            },
            initVal: atm.smoothing,
            numberWidth:40,
            gap:10@10
        );
        smoothing.numberView.keyDownAction_({
            smoothing.setColors(numStringColor:Color.red);
        });
        controlsComp.decorator.nextLine;
        controlsComp.decorator.nextLine;
        path = "presets";

        basicData = ['Voice' -> [atm.voiceAttack, atm.voiceRelease, atm.voiceLag], 'Percussion' -> [atm.percAttack, atm.percRelease, atm.percLag]];
        basicDictionary = Dictionary();
        basicData.do { |item, i|
            basicDictionary.add(item);
        };

        presets = EZPopUpMenu(controlsComp,
            430@22,
            "Input Presets",
            basicData,
            globalAction: {|menu|
                var data = menu.items[menu.value].value;
                attack.valueAction_(data[0]);
                release.valueAction_(data[1]);
                smoothing.valueAction_(data[2]);
            },
            labelWidth:72,
            gap:50@10
        );
        this.updatePresets();
        controlsComp.decorator.nextLine;
        controlsComp.decorator.nextLine;
        presetLabel = StaticText(controlsComp, 120@22)
            .string_("Save as");
        presetTitle = TextField(controlsComp, 305@22);
        controlsComp.decorator.nextLine;
        controlsComp.decorator.nextLine;

        presetSave = Button(controlsComp, 120@22)
            .states_([
                ["Save preset", Color.black, Color.white]
            ])
            .action_({|butt|
                var title, loadedPresets, writeData;
                if(File.exists(path)) {
                    loadedPresets = Object.readArchive(path);
                };

                title = presetTitle.string;

                if(title.size > 0) {
                    writeData = (loadedPresets ? Dictionary()).add(title.asSymbol -> [atm.attack, atm.release, atm.smoothing]);
                    writeData.writeArchive(path);
                    this.updatePresets();            
                };
            });
        controlsComp.decorator.left = (controlsComp.bounds.width/3);
        deletePreset = Button(controlsComp, 120@22)
            .states_([
                ["Delete preset", Color.black, Color.yellow],
            ]);
        controlsComp.decorator.left = controlsComp.bounds.width*(2/3);
        confirm = Button(controlsComp, 60@22)
            .states_([
                ["OK", Color.white, Color.red]
            ])
            .visible_(false);
        controlsComp.decorator.left = 374;
        cancel = Button(controlsComp, 60@22)
            .states_([
                ["Cancel", Color.black, Color.gray]
            ])
            .visible_(false);
        deletePreset.action_({|butt|
            if(presets.value >= basicData.size) {
                confirm.visible = true;
                cancel.visible = true;    
            }
        });
        confirm.action_({|butt|
            var complete;
            complete = Object.readArchive(path);
            complete.removeAt(presets.item);

            complete.writeArchive(path);
            this.updatePresets();
            confirm.visible = false;
            cancel.visible = false;
        });

        cancel.action_({|butt|
            confirm.visible = false;
            cancel.visible = false;
        });

        controlsComp.decorator.nextLine;
        controlsComp.decorator.nextLine;
        controlsComp.decorator.nextLine;
        controlsComp.decorator.nextLine;

        midiLabel = StaticText(controlsComp, 430@30)
            .background_(Color.black)
            .stringColor_(Color.white)
            .string_("MIDI Controls")
            .align_(\centered)
            .font_(titleFont);

        controlsComp.decorator.nextLine;
        controlsComp.decorator.nextLine;

        menu = EZPopUpMenu(controlsComp, 
            430@22,
            "MIDI Output Device",
            MIDIClient.destinations.collect({|item, i| (item.device + "-" + item.name).asSymbol -> {}}),
            globalAction: {|menu| atm.midiDevice_(menu.value)},
            labelWidth:105,
            gap:25@10
        );
        controlsComp.decorator.nextLine;
        midiChannel = EZNumber(controlsComp, 
            108@22, 
            "MIDI Channel",
            ControlSpec(1, 16, \lin, 1, 0, "Chan"),
            action: { |ez| atm.midiChan = ez.value - 1 },
            initVal: 0,
            initAction: false,
            numberWidth: 33,
            gap:10@10
        );
        controlsComp.decorator.left = (controlsComp.bounds.width/2);
        midiControlNum = EZNumber(controlsComp, 
            136@22, 
            "MIDI Control Value",
            ControlSpec(0, 127, step:1),
            action: { |ez| atm.midiCtlNum = ez.value },
            initVal: atm.midiCtlNum,
            initAction: false,
            numberWidth:33,
            gap:10@10
        );

        controlsComp.decorator.nextLine;

        commonControls = EZPopUpMenu(controlsComp, 
            430@22,
            "Useful Control Values",
            [
                '3 - Freely Assignable'                             -> {var val = 3;    midiControlNum.valueAction_(val); },
                '7 - Channel Volume'                                -> {var val = 7;    midiControlNum.valueAction_(val); },
                '10 - Pan'                                           -> {var val = 10;	midiControlNum.valueAction_(val); },
                '1 - Modulation Wheel'                              -> {var val = 1;	midiControlNum.valueAction_(val); },
                '11 - Expression Controller'                         -> {var val = 11;	midiControlNum.valueAction_(val); },
                '2 - Breath Controller'                             -> {var val = 2;	midiControlNum.valueAction_(val); },
                '4 - Foot Controller'                               -> {var val = 4;	midiControlNum.valueAction_(val); },
                '5 - Portamento Time'                               -> {var val = 5;	midiControlNum.valueAction_(val); },                                    
                '64 - Sustain Pedal - <=63:OFF >=64:ON'              -> {var val = 64;	midiControlNum.valueAction_(val); },
                '65 - Portamento - <=63:OFF >=64:ON'                 -> {var val = 65;	midiControlNum.valueAction_(val); },
                '66 - Sostenuto - <=63:OFF >=64:ON'                  -> {var val = 66;	midiControlNum.valueAction_(val); },
                '67 - Soft Pedal - <=63:OFF >=64:ON'                 -> {var val = 67;	midiControlNum.valueAction_(val); },
                '68 - Legato Footswitch - <=63:Normal >=64:Legato'   -> {var val = 68;	midiControlNum.valueAction_(val); },
                '9 - Undefined 1'                                   -> {var val = 9;	midiControlNum.valueAction_(val); },
                '14 - Undefined 2'                                   -> {var val = 14;	midiControlNum.valueAction_(val); },
                '15 - Undefined 3'                                   -> {var val = 15;	midiControlNum.valueAction_(val); },
                '20 - Undefined 4'                                   -> {var val = 20;	midiControlNum.valueAction_(val); }
            ],
            initVal: 1,
            labelWidth:119,
            gap:10@10
        );

        controlsComp.decorator.top = 540;
        promo = StaticText(controlsComp, 430@22)
            .string_("www.arthurcarabott.com / arthur@arthurcarabott.com")
            .align_(\right);

        win.onClose_({
            audioResponder.remove;
            audioMidiResponder.remove;
        });        
    }
    
    updatePresets {
        var presetData, presetArray, data;
        if(File.exists(path)) {
            presetData = Object.readArchive(path);
            presetArray = Array.newClear(presetData.size);
            presetData.keysValuesDo { |key, value, i|
                presetArray[i] = key -> value
            };
            data = basicData ++ presetArray;
        } {
            data = basicData;
        };

        presets.items = data;
    }
    
}