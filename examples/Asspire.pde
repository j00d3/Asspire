// Adapted from:
// https://wiki.t-o-f.info/OSC/Processing%E2%86%92Max
// https://www.arduino.cc/education/visualization-with-arduino-and-processing/

import processing.serial.*;

import netP5.*;
import oscP5.*;

// Declare an instance of the oscP5 library
OscP5 oscP5;

// Declare an IP address for the OSC messages
NetAddress targetIp;

// Color outside of the shape
int color_o;
// Color inside the shape
int color_i;
  
// Counters
int n = 1;
int h = 0;
int k = 0;

// Accelerometer data
float aX = 0;
float aY = 0;
float aZ = 0;

// Temperature data
float temp = 0;

// Gyroscope data
float gX = 0;
float gY = 0;
float gZ = 0;

// Pressure data
float pressure = 0;

Serial myPort;

String myData;
String cleanData;

String[] rawDataStr = new String[8];

float[] rawData = new float[8];

void sendMessage(float data, String name){
  OscMessage bufferMessage = new OscMessage("/" + name);
  bufferMessage.add(data);
  oscP5.send(bufferMessage, targetIp);
}

void setup() {
  fullScreen();
  
  // Print out a list of all available serial ports
  String[] serialPortArray = Serial.list();
  for (int i=0; i<serialPortArray.length; i++) {
    println(i + ":\t" + Serial.list()[i]);
  }

  // Select a serial port
  int whichPortToUse = 2;
  String portName = Serial.list()[whichPortToUse];
  println("Connected to port #" + whichPortToUse + ": " + portName);
  
  // Set your baud rate in place of "9600"
  myPort = new Serial(this, portName, 9600);
  
  // Instantiate the oscP5 library
  oscP5 = new OscP5(this, 7374);

  // Set the IP address for the OSC messages. 127.0.0.1 means the machine itself (localhost)
  targetIp = new NetAddress("127.0.0.1", 7777);
}

void draw() {  
  if (myPort.available() > 0){  
    // If data is available,
    myData = myPort.readStringUntil('\n');
    
    try {
      // Get rid of any spaces from Arduino data
      cleanData = myData.replaceAll("\\s", "");
    
      // Splitting the data into usable data
      rawDataStr = split(myData, '/');
    
      for(int i = 0; i < rawDataStr.length; i++){
         rawData[i] = Float.parseFloat(rawDataStr[i]);
      }
        
      // Assign raw data
      aX = rawData[0];
      aY = rawData[1];
      aZ = rawData[2];
  
      temp = rawData[3];
  
      gX = rawData[4];
      gY = rawData[5];
      gZ = rawData[6];
  
      pressure = rawData[7];
      
      // Sends all data through OSC to Max approximately every second
      if (k%25 == 0) {
        sendMessage(aX, "aX");
        sendMessage(aY, "aY");
        sendMessage(aZ, "aZ");
        sendMessage(temp, "temp");
        sendMessage(gX, "gX");
        sendMessage(gY, "gY");
        sendMessage(gZ, "gZ");
        sendMessage(pressure, "pr");
      }
      
      k++;
    }
    catch(Exception e) {
      ;
    }
  
    // Visual output starts here 
    // Adapted from https://editor.p5js.org/golan/sketches/Fv_U5kR6g
    
    // How often n loops (RGB input)
    if (n%255 == 0) {
      h++;
    }
  
    // First color loop
    if(h%2 == 0) {
      color_i = color(n%255, 255 - n%255, abs(aZ)/20000);
      color_o = color(255 - n%255, abs(gZ)/1000, n%255);
    }
    // Second color loop
    else {
      color_i = color(255 - n%255, n%255, abs(aZ)/20000);
      color_o = color(n%255, abs(gZ)/1000, 255 - n%255);
    }
  
    background(color_o);
  
    fill(color_i); 
    noStroke();
  
    int nNoiseOctaves = 3;
    float noiseFalloff = 0.8;
    noiseDetail(nNoiseOctaves, noiseFalloff); 
  
    int nPoints = 360; 
    float noiseCenterX = abs(aX)/20000; 
    float noiseCenterY = abs(aY)/20000; 
    float noiseRadius = 5;
  
    float whichCardioid = 1/100.0;
  
    beginShape(); 
    for (int i=0; i<=nPoints; i++){
      float ang = map(i,0,nPoints, 0,TWO_PI);
      float nx = noiseCenterX + noiseRadius*cos(ang);
      float ny = noiseCenterY + noiseRadius*sin(ang);
      float noiseVal = map(noise(nx+whichCardioid,ny), 0,1, -1,1); 
    
      // The higher the pressure, the smaller the radius
      float r = 400 - 200*abs(pressure) + 150*noiseVal;
      float px = width/2 + r * cos(ang); 
      float py = height/2 + r * sin(ang); 
      vertex(px,py);
    }
    endShape(); 
  
    n++;
    
    println(pressure);
    
    // Visual output ends here
  }
}
