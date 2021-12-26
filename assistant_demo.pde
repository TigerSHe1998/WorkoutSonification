// !!!! IMPORTANT: PLEASE INSTALL THE TTSLIB/Beads/ControlP5 LIBRARY IN PROCESSING BEFORE RUNNING THE SKETCH !!!! //
// !!!! IMPORTANT: PLEASE INSTALL THE TTSLIB/Beads/ControlP5 LIBRARY IN PROCESSING BEFORE RUNNING THE SKETCH !!!! //

// ------- imports (other imports exist in other classes) -------
import controlP5.*;
import beads.*;
import org.jaudiolibs.beads.*;

// ------- global variables -------
// UI
ControlP5 p5; 

// tts
TextToSpeechMaker ttsMaker;
SamplePlayer tts;

// notification server for real time JSON events
NotificationServer notificationServer;
ArrayList<Notification> notifications;
MyNotificationListener myNotificationListener;

// application state
int currentMode = 0; // mode 0-pushup 1-situp 2-squat 3-counting

// counting mode audio vars
SamplePlayer count5, badMove;
Glide c5glide;

// feedback mode audio vars
WavePlayer wave;
Glide waveGlide, waveGainGlide;
Gain waveGain;
BiquadFilter filter;

// pushup mode logic vars
float waistOffset = 0.0;
boolean newPush = true;
boolean finishPush = false;
float previousPosition = 100.0;
boolean playedBadMove = false;
boolean playedBadWaist = false;

// situp mode logic vars
boolean newSit = true;
boolean finishSit = false;
float previousPositionSit = 0.0;
boolean playedBadMoveSit = false;
boolean playedBadWaistSit = false;

// squat mode logic vars
boolean newSq = true;
boolean finishSq = false;
float previousPositionSq = 100.0;
boolean playedBadMoveSq = false;

// master gain
Gain masterGain;
Glide gainGlide; // glide for smoothing volume control

// UI globals for easy hide / show
Slider pu1, pu2, sq1, su1;
Knob pu3, pu4, su2, sq2, sq3;
Textlabel pu5, su3, sq4, c1, c2, c3, c4;
Button pu6, pu7, pu8, pu9, pu10, su4, su5, su6, su7, su8, sq5, sq6, sq7, sq8, sq9, c7, c8, c9;
DropdownList c5;
Textfield c6;



// ------- application setup -------
void setup() { // setup runs once when the sketch starts
  
  // -------------- UI initiation -------------- //
  size(600, 300); // application window size (dont change this or ui might go crazy) 
  p5 = new ControlP5(this);
  
  // -------------- Set up JSON notification server -------------- //
  notificationServer = new NotificationServer();
  myNotificationListener = new MyNotificationListener();
  notificationServer.addListener(myNotificationListener);

  // -------------- Audio generating and wiring -------------- //
  // instantiate audio out
  ac = new AudioContext();

  // samples for tts generation
  // use tts("sentence") at any point to play text to speech
  ttsMaker = new TextToSpeechMaker();
  ttsMaker.cleanTTSDirectory(); // cleans previous generated tts wavs
  tts = getSamplePlayer("music.wav"); // instantiate sample player here so i can use masterGain
  tts.pause(true);
  //tts("This tts sounds like garbage but it's funny anyway I will make this sentence very long so I can test the volumes bruh bruh bruh bruh bruh bruh bruh");

  // samples for counting mode
  count5 = getSamplePlayer("cnt_5actions.wav");
  count5.pause(true);
  c5glide = new Glide(ac, 1.05, 0); // pitch change glide
  count5.setPitch(c5glide);
  badMove = getSamplePlayer("badmove.wav");
  badMove.pause(true);

  // samples for feedback mode
  waveGlide = new Glide(ac, 440.0, 50);
  waveGainGlide = new Glide(ac, 0, 50);
  waveGain = new Gain(ac, 1, waveGainGlide);
  wave = new WavePlayer(ac, waveGlide, Buffer.SINE);
  waveGain.addInput(wave);
  filter = new BiquadFilter(ac, BiquadFilter.LP, 7500.0, 0.5);
  filter.addInput(wave);
  //wave.pause(true);

  // master gain + gain glide
  gainGlide = new Glide(ac, 1.0, 200); // glide smoothes gain change, 200 is time in ms
  masterGain = new Gain(ac, 1, gainGlide);

  // adding all sound into output
  masterGain.addInput(tts);
  masterGain.addInput(count5);
  masterGain.addInput(badMove);
  masterGain.addInput(waveGain);
  ac.out.addInput(masterGain);
  ac.start();

  // -------------- UI -------------- //
  // ------- persistent elements -------
  // top title
  p5.addTextlabel("label8").setText("HOME WORKOUT ASSISTANT DEMO").setPosition(width/2 - 80,5);
  // left top instruction
  p5.addTextlabel("label2").setText("These modes have speech feedback to").setPosition(1,5).setColorValue(0xffffff00);
  p5.addTextlabel("label3").setText("help correct your workout forms.").setPosition(1,15).setColorValue(0xffffff00);
  // left top section name
  p5.addTextlabel("label1").setText("FORM FEEDBACK MODE").setPosition(1,27);
  // pushup button
  p5.addButton("Pushup").setPosition(3,40).setSize(100, 25).setLabel("PUSH-UP").activateBy((ControlP5.RELEASE));
  // situp button
  p5.addButton("Situp").setPosition(3,70).setSize(100, 25).setLabel("SIT-UP").activateBy((ControlP5.RELEASE));
  // sqaut button
  p5.addButton("Squat").setPosition(3,100).setSize(100, 25).setLabel("Squat").activateBy((ControlP5.RELEASE));
  // left bottom instructions
  p5.addTextlabel("label4").setText("Once you are familiar with the forms,").setPosition(1,height-135).setColorValue(0xffffff00);
  p5.addTextlabel("label5").setText("use the background counting mode.").setPosition(1,height-125).setColorValue(0xffffff00);
  p5.addTextlabel("label7").setText("This mode disables speech feedback.").setPosition(1,height-115).setColorValue(0xffffff00);
  // left bottom section name
  p5.addTextlabel("label6").setText("BACKGROUND COUNTING MODE").setPosition(1,height-103);
  // background counting button
  p5.addButton("CountingMode").setPosition(3, height-90).setSize(100, 25).setLabel("COUNTING MODE").activateBy((ControlP5.RELEASE));
  // gain slider
  p5.addSlider("GainSlider").setPosition(3,height-30).setSize(120,25).setRange(0,100).setValue(50).setLabel("Volume");

  // ------- push-up sub menu -------
  // chest slider
  pu1 = p5.addSlider("Pushup_chestSlider").setPosition(200,40).setSize(30,180).setRange(0,100).setValue(100).setLabel("Chest Height");
  // waist slider
  pu2 = p5.addSlider("Pushup_waistSlider").setPosition(270,40).setSize(30,180).setRange(0,100).setValue(70).setLabel("Waist Height");
  // left elbow knob
  pu3 = p5.addKnob("Pushup_leknob").setRange(0,180).setValue(180).setPosition(340,40).setRadius(35).setDragDirection(Knob.VERTICAL).setLabel("Left Elbow");
  // right elbow knob
  pu4 = p5.addKnob("Pushup_reknob").setRange(0,180).setValue(180).setPosition(340,150).setRadius(35).setDragDirection(Knob.VERTICAL).setLabel("Right Elbow");
  // event controls
  pu5 = p5.addTextlabel("Pushup_evntLabel").setText("Event Player").setPosition(438,40);
  pu6 = p5.addButton("Pushup_good").setPosition(440, 55).setSize(150, 20).setLabel("Do a good push-up").activateBy((ControlP5.RELEASE));
  pu7 = p5.addButton("Pushup_bad").setPosition(440, 80).setSize(150, 20).setLabel("Do a bad push-up").activateBy((ControlP5.RELEASE));
  pu8 = p5.addButton("Pushup_play").setPosition(440, 105).setSize(150, 20).setLabel("Play example scenario").activateBy((ControlP5.RELEASE));
  pu9 = p5.addButton("Pushup_pause").setPosition(440, 130).setSize(150, 20).setLabel("Pause scenario").activateBy((ControlP5.RELEASE));
  pu10 = p5.addButton("Pushup_stop").setPosition(440, 155).setSize(150, 20).setLabel("Stop/Reset scenario").activateBy((ControlP5.RELEASE));

  // ------- sit-up sub menu -------
  // chest slider
  su1 = p5.addSlider("Situp_chestSlider").setPosition(200,40).setSize(30,180).setRange(0,100).setValue(0).setLabel("Chest Height");
  // waist knob
  su2 = p5.addKnob("Situp_wknob").setRange(0,180).setValue(180).setPosition(340,40).setRadius(35).setDragDirection(Knob.VERTICAL).setLabel("Waist Angle");
  // event controls
  su3 = p5.addTextlabel("Situp_evntLabel").setText("Event Player").setPosition(438,40);
  su4 = p5.addButton("Situp_good").setPosition(440, 55).setSize(150, 20).setLabel("Do a good sit-up").activateBy((ControlP5.RELEASE));
  su5 = p5.addButton("Situp_bad").setPosition(440, 80).setSize(150, 20).setLabel("Do a bad sit-up").activateBy((ControlP5.RELEASE));
  su6 = p5.addButton("Situp_play").setPosition(440, 105).setSize(150, 20).setLabel("Play example scenario").activateBy((ControlP5.RELEASE));
  su7 = p5.addButton("Situp_pause").setPosition(440, 130).setSize(150, 20).setLabel("Pause scenario").activateBy((ControlP5.RELEASE));
  su8 = p5.addButton("Situp_stop").setPosition(440, 155).setSize(150, 20).setLabel("Stop/Reset scenario").activateBy((ControlP5.RELEASE));

  // ------- squat sub menu -------
  // waist slider
  sq1 = p5.addSlider("Sqt_waistSlider").setPosition(200,40).setSize(30,180).setRange(0,100).setValue(100).setLabel("Waist Height");
  // left knee knob
  sq2 = p5.addKnob("Sqt_lkknob").setRange(0,180).setValue(180).setPosition(340,40).setRadius(35).setDragDirection(Knob.VERTICAL).setLabel("Left Knee");
  // right knee knob
  sq3 = p5.addKnob("Sqt_rkknob").setRange(0,180).setValue(180).setPosition(340,150).setRadius(35).setDragDirection(Knob.VERTICAL).setLabel("Right Knee");
  // event controls
  sq4 = p5.addTextlabel("Sqt_evntLabel").setText("Event Player").setPosition(438,40);
  sq5 = p5.addButton("Sqt_good").setPosition(440, 55).setSize(150, 20).setLabel("Do a good squat").activateBy((ControlP5.RELEASE));
  sq6 = p5.addButton("Sqt_bad").setPosition(440, 80).setSize(150, 20).setLabel("Do a bad squat").activateBy((ControlP5.RELEASE));
  sq7 = p5.addButton("Sqt_play").setPosition(440, 105).setSize(150, 20).setLabel("Play example scenario").activateBy((ControlP5.RELEASE));
  sq8 = p5.addButton("Sqt_pause").setPosition(440, 130).setSize(150, 20).setLabel("Pause scenario").activateBy((ControlP5.RELEASE));
  sq9 = p5.addButton("Sqt_stop").setPosition(440, 155).setSize(150, 20).setLabel("Stop/Reset scenario").activateBy((ControlP5.RELEASE));

  // ------- background counting menu -------
  c1 = p5.addTextlabel("c_workoutlbl").setText("Select a workout").setPosition(200,40);
  c2 = p5.addTextlabel("c_countlbl").setText("Enter a count").setPosition(200,110);
  c3 = p5.addTextlabel("c_aleftlabel").setText("Actions left").setPosition(400,40);
  c4 = p5.addTextlabel("c_number").setText("30").setPosition(400,50).setFont(createFont("Georgia",50));
  c5 = p5.addDropdownList("c_workoutlist").addItem("Pushup",0).addItem("Situp",0).addItem("Squat",0).setPosition(200,50).setLabel("--select--");
  c6 = p5.addTextfield("c_input").setPosition(203,120).setSize(95,20).setText("30").setInputFilter(1).setLabel("");
  c7 = p5.addButton("c_setcount").setPosition(202, 155).setSize(98, 20).setLabel("Set").activateBy((ControlP5.RELEASE));
  c8 = p5.addButton("c_good").setPosition(400, 120).setSize(150, 20).setLabel("Perform correct action").activateBy((ControlP5.RELEASE));
  c9 = p5.addButton("c_bad").setPosition(400, 145).setSize(150, 20).setLabel("Perform incorrect action").activateBy((ControlP5.RELEASE));

  // hide all ui elements except for pushups on start
  su1.hide();su2.hide();su3.hide();su4.hide();su5.hide();su6.hide();su7.hide();su8.hide();
  sq1.hide();sq2.hide();sq3.hide();sq4.hide();sq5.hide();sq6.hide();sq7.hide();sq8.hide();sq9.hide();
  //pu1.hide();pu2.hide();pu3.hide();pu4.hide();pu5.hide();pu6.hide();pu7.hide();pu8.hide();pu9.hide();pu10.hide();
  c1.hide();c2.hide();c3.hide();c4.hide();c5.hide();c6.hide();c7.hide();c8.hide();c9.hide();
}

void draw() {
  background(0);  //fills the canvas with black color each frame
  fill (0x55555500); // draws the right section background color
  rect (180, 0, 420, 300);
}



// ------- function for persistent elements -------
public void GainSlider(float value) {
  //println("Debug: Volume slider moved to", value);
  gainGlide.setValue(value/100.0);
}

public void Pushup() {
  if (currentMode != 0){
    currentMode = 0;
    su1.hide();su2.hide();su3.hide();su4.hide();su5.hide();su6.hide();su7.hide();su8.hide();
    sq1.hide();sq2.hide();sq3.hide();sq4.hide();sq5.hide();sq6.hide();sq7.hide();sq8.hide();sq9.hide();
    pu1.show();pu2.show();pu3.show();pu4.show();pu5.show();pu6.show();pu7.show();pu8.show();pu9.show();pu10.show();
    c1.hide();c2.hide();c3.hide();c4.hide();c5.hide();c6.hide();c7.hide();c8.hide();c9.hide();
  }
}

public void Situp() {
  if (currentMode != 1){
    currentMode = 1;
    su1.show();su2.show();su3.show();su4.show();su5.show();su6.show();su7.show();su8.show();
    sq1.hide();sq2.hide();sq3.hide();sq4.hide();sq5.hide();sq6.hide();sq7.hide();sq8.hide();sq9.hide();
    pu1.hide();pu2.hide();pu3.hide();pu4.hide();pu5.hide();pu6.hide();pu7.hide();pu8.hide();pu9.hide();pu10.hide();
    c1.hide();c2.hide();c3.hide();c4.hide();c5.hide();c6.hide();c7.hide();c8.hide();c9.hide();
  }
}

public void Squat() {
  if (currentMode != 2){
    currentMode = 2;
    su1.hide();su2.hide();su3.hide();su4.hide();su5.hide();su6.hide();su7.hide();su8.hide();
    sq1.show();sq2.show();sq3.show();sq4.show();sq5.show();sq6.show();sq7.show();sq8.show();sq9.show();
    pu1.hide();pu2.hide();pu3.hide();pu4.hide();pu5.hide();pu6.hide();pu7.hide();pu8.hide();pu9.hide();pu10.hide();
    c1.hide();c2.hide();c3.hide();c4.hide();c5.hide();c6.hide();c7.hide();c8.hide();c9.hide();
  }
}

public void CountingMode() {
  if (currentMode != 3){
    currentMode = 3;
    su1.hide();su2.hide();su3.hide();su4.hide();su5.hide();su6.hide();su7.hide();su8.hide();
    sq1.hide();sq2.hide();sq3.hide();sq4.hide();sq5.hide();sq6.hide();sq7.hide();sq8.hide();sq9.hide();
    pu1.hide();pu2.hide();pu3.hide();pu4.hide();pu5.hide();pu6.hide();pu7.hide();pu8.hide();pu9.hide();pu10.hide();
    c1.show();c2.show();c3.show();c4.show();c5.show();c6.show();c7.show();c8.show();c9.show();
  }
}



// ------- function for pushup mode -------
public void Pushup_chestSlider(float value){
  // play pitching wave sound
  if (value < 80 && value >20) {
    waveGainGlide.setValue(0.2);
    waveGlide.setValue((100-value)*8.8);
  } else {
    waveGainGlide.setValue(0);
  }
  
  // move waist height when chest moves
  // move elbow angles when chest moves
  try {
    pu2.setValue(0.7*value + waistOffset);
    pu3.setValue(1.125*value + 67.5);
    pu4.setValue(1.125*value + 67.5);
  } catch(Exception e) {
  }

  // detect correct / wrong push
  if (newPush) { // user is pushing down
    if (value - previousPosition > 0 && value < 80) {
      // wrong direction
      if (playedBadMove == false) {
        badMove.setToLoopStart();
        badMove.start();
        tts("Please keep pushing down until your elbows reach ninety degrees");
        playedBadMove = true;
      }
    }
    if (value <= 20) {
      // change state after successfully pushing down + play sfx
      newPush = false;
      finishPush = true;
      playedBadMove = false;
      c5glide.setValue(1.05);
      count5.setToLoopStart();
      count5.start();
    }
  } 
  if (finishPush) { // user is coming back up
    if (value - previousPosition < 0 && value > 20) {
      // wrong direction
      if (playedBadMove == false) {
        badMove.setToLoopStart();
        badMove.start();
        tts("Please properly reset your body before starting another push");
        playedBadMove = true;
      }
    }
    if (value >= 80) {
      // change state after successfully coming back up + play sfx
      newPush = true;
      finishPush = false;
      playedBadMove = false;
      c5glide.setValue(1.05);
      count5.setToLoopStart();
      count5.start();
    }
  }
  previousPosition = value;
}

public void Pushup_waistSlider(float value){
  waistOffset = value - pu1.getValue()*0.7;
  // detect bad waist height + play sfx
  if (value > pu1.getValue()*0.9 && value > 30) {
    if (playedBadWaist == false) {
      badMove.setToLoopStart();
      badMove.start();
      tts("Your waist is too high");
      playedBadWaist = true;
    }
  } else {
    playedBadWaist = false;
  }
}

public void Pushup_good() {
  notificationServer.loadEventStream("workout_pushup_good.json");
}

public void Pushup_bad() {
  notificationServer.loadEventStream("workout_pushup_bad.json");
}

public void Pushup_play() {
  notificationServer.loadEventStream("workout_pushup_scenario.json");
}

public void Pushup_pause() {
  notificationServer.pauseEventStream();
}

public void Pushup_stop() {
  pu1.setValue(100.0);
  pu2.setValue(70.0);
  newPush = true;
  finishPush = false;
  playedBadMove = false;
  playedBadWaist = false;
  notificationServer.stopEventStream();
}



// ------- function for situp mode -------
public void Situp_chestSlider(float value) {
  // play pitching wave sound
  if (value < 80 && value >20) {
    waveGainGlide.setValue(0.2);
    waveGlide.setValue((value)*8.8);
  } else {
    waveGainGlide.setValue(0);
  }
  
  // move waist angle when chest moves
  try {
    su2.setValue(-1*value + 180);
  } catch(Exception e) {
  }
  
  // detect correct / wrong sit up
  if (newSit) { // user is sitting up
    if (value - previousPositionSit < 0 && value > 20) {
      // wrong direction
      if (playedBadMoveSit == false) {
        badMove.setToLoopStart();
        badMove.start();
        tts("Please keep going up until your waist reach a hundred degrees");
        playedBadMoveSit = true;
      }
    }
    if (value >= 80) {
      // change state after successfully pushing down + play sfx
      newSit = false;
      finishSit = true;
      playedBadMoveSit = false;
      c5glide.setValue(1.05);
      count5.setToLoopStart();
      count5.start();
    }
  } 
  if (finishSit) { // user is going back down
    if (value - previousPositionSit > 0 && value < 80) {
      // wrong direction
      if (playedBadMoveSit == false) {
        badMove.setToLoopStart();
        badMove.start();
        tts("Please properly reset your body before starting another sit up");
        playedBadMoveSit = true;
      }
    }
    if (value <= 20) {
      // change state after successfully coming back up + play sfx
      newSit = true;
      finishSit = false;
      playedBadMoveSit = false;
      c5glide.setValue(1.05);
      count5.setToLoopStart();
      count5.start();
    }
  }
  previousPositionSit = value;
}

public void Situp_good() {
  notificationServer.loadEventStream("workout_situp_good.json");
}

public void Situp_bad() {
  notificationServer.loadEventStream("workout_situp_bad.json");
}

public void Situp_play() {
  notificationServer.loadEventStream("workout_situp_scenario.json");
}

public void Situp_pause() {
  notificationServer.pauseEventStream();
}

public void Situp_stop() {
  su1.setValue(0.0);
  newSit = true;
  finishSit = false;
  playedBadMoveSit = false;
  playedBadWaistSit = false;
  notificationServer.stopEventStream();
}



// ------- function for squat mode -------
public void Sqt_waistSlider(float value) {
  // play pitching wave sound
  if (value < 80 && value >20) {
    waveGainGlide.setValue(0.2);
    waveGlide.setValue((100-value)*8.8);
  } else {
    waveGainGlide.setValue(0);
  }
  
  // move elbow angles when chest moves
  try {
    sq2.setValue(1.125*value + 67.5);
    sq3.setValue(1.125*value + 67.5);
  } catch(Exception e) {
  }
  
  // detect correct / wrong push
  if (newSq) { // user is squating down
    if (value - previousPositionSq > 0 && value < 80) {
      // wrong direction
      if (playedBadMoveSq == false) {
        badMove.setToLoopStart();
        badMove.start();
        tts("Please keep lowering down until your knees reach ninety degrees");
        playedBadMoveSq = true;
      }
    }
    if (value <= 20) {
      // change state after successfully pushing down + play sfx
      newSq = false;
      finishSq = true;
      playedBadMoveSq = false;
      c5glide.setValue(1.05);
      count5.setToLoopStart();
      count5.start();
    }
  } 
  if (finishSq) { // user is coming back up
    if (value - previousPositionSq < 0 && value > 20) {
      // wrong direction
      if (playedBadMoveSq == false) {
        badMove.setToLoopStart();
        badMove.start();
        tts("Please properly reset your body before starting another squat");
        playedBadMoveSq = true;
      }
    }
    if (value >= 80) {
      // change state after successfully coming back up + play sfx
      newSq = true;
      finishSq = false;
      playedBadMoveSq = false;
      c5glide.setValue(1.05);
      count5.setToLoopStart();
      count5.start();
    }
  }
  previousPositionSq = value;
}

public void Sqt_good() {
  notificationServer.loadEventStream("workout_squat_good.json");
}

public void Sqt_bad() {
  notificationServer.loadEventStream("workout_squat_bad.json");
}

public void Sqt_play() {
  notificationServer.loadEventStream("workout_squat_scenario.json");
}

public void Sqt_pause() {
  notificationServer.pauseEventStream();
}

public void Sqt_stop() {
  sq1.setValue(100.0);
  newSq = true;
  finishSq = false;
  playedBadMoveSq = false;
  notificationServer.stopEventStream();
}



// ------- function for counting mode -------
public void c_setcount() {
  int count = Integer.parseInt(c6.getText());
  c4.setText(String.valueOf(count));
  c5glide.setValue(1.05);
}

public void c_good() {
  int currentCount = Integer.parseInt(c4.getStringValue());
  if (currentCount > 0) {
    currentCount -= 1;
    c4.setText(String.valueOf(currentCount));
    if (currentCount % 5 == 0 && currentCount >= 10) { // play count sound pitching down
      float pitch = c5glide.getCurrentValue();
      if (pitch - 0.05 > 0) {
        c5glide.setValue(pitch - 0.05);
      }
      count5.setToLoopStart();
      count5.start();
    }
    if (currentCount == 10) {
      tts("ten left");
    }
    if (currentCount == 5) {
      tts("five left");
    }
    if (currentCount == 3) {
      tts("three");
    }
    if (currentCount == 2) {
      tts("two");
    }
    if (currentCount == 1) {
      tts("one");
    }
  }
  if (currentCount == 0) {
    tts("workout complete");
  }
}

public void c_bad() {
  int currentCount = Integer.parseInt(c4.getStringValue());
  if (currentCount > 0) {
    badMove.setToLoopStart();
    badMove.start();
  }
}



// ------- TTS playback -------
// create TTS file using a string and play it back immediately
public void tts(String inputSpeech) {
  // createTTSWavFile makes a new WAV file of name ttsX.wav, where X is a unique integer
  // it returns the path relative to the sketch's data directory to the wav file
  String ttsFilePath = ttsMaker.createTTSWavFile(inputSpeech);
  println("TTS file created at " + ttsFilePath);

  tts.setSample(getSample(ttsFilePath));
  tts.setToLoopStart();
  tts.start();
}



// ------- Notification listener class for JSON read in -------
class MyNotificationListener implements NotificationListener {
  
  public MyNotificationListener() {}
  
  public void notificationReceived(Notification notification) { // calls when notification is received
    //println("<Time: " + notification.getTimestamp() + "ms> " + notification.toString());
    switch(currentMode) { // mode 0-pushup 1-situp 2-squat 3-counting
      case 0: 
        // push up
        String type = notification.getType().toString();
        if (type.equals("chestHeight")) {
          pu1.setValue(notification.getValue());
        } else if (type.equals("waistHeight")) {
          pu2.setValue(notification.getValue());
        } else if (type.equals("elbowL")) {
          pu3.setValue(notification.getValue());
        } else if (type.equals("elbowR")) {
          pu4.setValue(notification.getValue());
        }
        break;
      case 1: 
        // sit up
        String type1 = notification.getType().toString();
        if (type1.equals("chestHeight")) {
          su1.setValue(notification.getValue());
        } else if (type1.equals("waistAngle")) {
          su2.setValue(notification.getValue());
        } 
        break;
      case 2: 
        // squat
        String type2 = notification.getType().toString();
        if (type2.equals("waistHeight")) {
          sq1.setValue(notification.getValue());
        } else if (type2.equals("kneeL")) {
          sq2.setValue(notification.getValue());
        } else if (type2.equals("kneeR")) {
          sq3.setValue(notification.getValue());
        } 
        break;
    }
  }
}
