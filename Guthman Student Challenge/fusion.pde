import processing.serial.*;
import oscP5.*;
import netP5.*;
import cc.arduino.*;
import cc.arduino.*;

Arduino arduino;

Serial myPort; 


final String serialPort = "/dev/tty.usbmodem1421";
final int pipelineMode = GRT.CLASSIFICATION_MODE;
final int numInputs = 3;
final int numOutputs = 1;

float [] q = new float [8];
//float [] q1 = new float [4];
float [] hq = null;
float [] Euler = new float [3]; // psi, theta, phi

int lf = 10; // 10 is '\n' in ASCII
byte[] inBuffer = new byte[22]; // this is the number of chars on each line from the Arduino (including /r/n)
OscP5 oscP5;
NetAddress myRemoteLocation;

final int VIEW_SIZE_X = 800, VIEW_SIZE_Y = 600;
GRT grt = new GRT( pipelineMode, numInputs, numOutputs, "127.0.0.1", 5000, 5001, true );

//Create some global variables to hold our data
float[] data = new float[ numInputs ];
float[] targetVector = new float[ numOutputs ];
PFont font;

void setup() 
{
  size(VIEW_SIZE_X, VIEW_SIZE_Y, P3D);
  oscP5 = new OscP5(this,1200);
  myPort = new Serial(this, serialPort, 57600);  
  arduino = new Arduino(this, "/dev/tty.usbmodem1411",57600);
  font = createFont("Courier", 32); 
  myRemoteLocation = new NetAddress("127.0.0.1",1200);
   for (int i = 0; i <= 13; i++)
    arduino.pinMode(i, Arduino.OUTPUT);
  delay(100);
  myPort.clear();
  myPort.write("1");
}

float decodeFloat(String inString) {
 byte [] inData = new byte[4];

  if (inString.length() == 8) {
    inData[0] = (byte) unhex(inString.substring(0, 2));
    inData[1] = (byte) unhex(inString.substring(2, 4));
    inData[2] = (byte) unhex(inString.substring(4, 6));
    inData[3] = (byte) unhex(inString.substring(6, 8));
  }

  int intbits = (inData[3] << 24) | ((inData[2] & 0xff) << 16) | ((inData[1] & 0xff) << 8) | (inData[0] & 0xff);
  return Float.intBitsToFloat(intbits);
}




void readQ() {
  if (myPort.available() >= 18) {
    String inputString = myPort.readStringUntil('\n');
    //print(inputString);
    if (inputString != null && inputString.length() > 0) {
      String [] inputStringArr = split(inputString, ",");
      if (inputStringArr.length >= 5) { // q1,q2,q3,q4,\r\n so we have 5 elements
        q[0] = decodeFloat(inputStringArr[0]);
        q[1] = decodeFloat(inputStringArr[1]);
        q[2] = decodeFloat(inputStringArr[2]);
        q[3] = decodeFloat(inputStringArr[3]);
        q[4] = int(inputStringArr[4]);
        q[5] = int(inputStringArr[5]);
        q[6] = int(inputStringArr[6]);
        q[7] = int(inputStringArr[7]);
      }
    }
  }
}

void buildBoxShape() {
  //box(60, 10, 40);
  noStroke();
  beginShape(QUADS);

  //Z+ (to the drawing area)
  fill(#00ff00);
  vertex(-30, -5, 20);
  vertex(30, -5, 20);
  vertex(30, 5, 20);
  vertex(-30, 5, 20);

  //Z-
  fill(#0000ff);
  vertex(-30, -5, -20);
  vertex(30, -5, -20);
  vertex(30, 5, -20);
  vertex(-30, 5, -20);

  //X-
  fill(#ff0000);
  vertex(-30, -5, -20);
  vertex(-30, -5, 20);
  vertex(-30, 5, 20);
  vertex(-30, 5, -20);

  //X+
  fill(#ffff00);
  vertex(30, -5, -20);
  vertex(30, -5, 20);
  vertex(30, 5, 20);
  vertex(30, 5, -20);

  //Y-
  fill(#ff00ff);
  vertex(-30, -5, -20);
  vertex(30, -5, -20);
  vertex(30, -5, 20);
  vertex(-30, -5, 20);

  //Y+
  fill(#00ffff);
  vertex(-30, 5, -20);
  vertex(30, 5, -20);
  vertex(30, 5, 20);
  vertex(-30, 5, 20);

  endShape();
}


void drawCube() {  
  pushMatrix();
  translate(VIEW_SIZE_X/2, VIEW_SIZE_Y/2 + 50, 0);
  scale(5, 5, 5);

  // a demonstration of the following is at 
  // http://www.varesano.net/blog/fabio/ahrs-sensor-fusion-orientation-filter-3d-graphical-rotating-cube
  rotateZ(-Euler[2]);
  rotateX(-Euler[1]);
  rotateY(-Euler[0]);

  buildBoxShape();

  popMatrix();
}

void draw() {
  background(#000000);
  fill(#ffffff);
  OscMessage myMessage = new OscMessage(" ");
  readQ();
  //readQuo();

  if (hq != null) { // use home quaternion
    quaternionToEuler(quatProd(hq, q), Euler);
    text("Disable home position by pressing \"n\"", 20, VIEW_SIZE_Y - 30);
  }
  else {
    quaternionToEuler(q, Euler);
    text("Point FreeIMU's X axis to your monitor then press \"h\"", 20, VIEW_SIZE_Y - 30);
  }
  textFont(font, 20);
  textAlign(LEFT, TOP);
  text("Q:\n" + q[0] + "\n" + q[1] + "\n" + q[2] + "\n" + q[3], 20, 20);
  text("Euler Angles:\nYaw (psi)  : " + degrees(Euler[0]) + "\nPitch (theta): " + degrees(Euler[1]) + "\nRoll (phi)  : " + degrees(Euler[2]), 200, 20);
  text("\n\n\n\nPredicted State: "+grt.getPredictedClassLabel(),200,20);
  text("\n\n\n\n\nPressure: "+q[4]+" "+q[5]+" "+q[6]+" "+q[7],200,20);
 ///*
  if (q[7]<100) {
    arduino.analogWrite(10,int((degrees(Euler[2])+60)*255/120)); 
    
  } else {
    arduino.analogWrite(10,int(pow((degrees(Euler[2])+60)*5.55/120,2.718))); 
    
  }

    
  arduino.analogWrite(5,int(q[5]/4));  
  arduino.analogWrite(6,int(q[6]/4));  
  
  if (q[4]>100)
  {
    arduino.digitalWrite(3,Arduino.HIGH);
  }
  else
  {
    arduino.digitalWrite(3,Arduino.LOW);
  }
  if (q[5]>100)
  {
    if (grt.getPredictedClassLabel()==1)
    {myMessage.add(1);}
    else
    {
    myMessage.add(4);
    }
    oscP5.send(myMessage, myRemoteLocation); }
  else if(q[6]>100)
  {  if (grt.getPredictedClassLabel()==1)
    {myMessage.add(2);}
    else
    {
    myMessage.add(5);
  }
    oscP5.send(myMessage, myRemoteLocation);}
 
  else
  { myMessage.add(0);
    oscP5.send(myMessage, myRemoteLocation);}
 // */  
  
  arduino.analogWrite(9,int((degrees(Euler[2])+60)*255/120)); 
  //arduino.analogWrite(5,100);  
  drawCube();
  data[0] = degrees(Euler[0]);
  data[1] = degrees(Euler[1]);
  data[2] = degrees(Euler[2]);
  grt.sendData( data );
}

void keyPressed(){
  
  switch( key ){
    case 'i':
      grt.init( pipelineMode, numInputs, numOutputs, "127.0.0.1", 5000, 5001, true );
      break;
    case '[':
      grt.decrementTrainingClassLabel();
      break;
    case ']':
      grt.incrementTrainingClassLabel();
      break;
    case 'r':
      if( grt.getRecordingStatus() ){
        grt.stopRecording();
      }else grt.startRecording();
      break;
    case 't':
      grt.startTraining();
      break;
    case 's':
      grt.saveTrainingDatasetToFile( "TrainingData.txt" );
      break;
    case 'l':
      grt.loadTrainingDatasetFromFile( "TrainingData.txt" );
      break;
    case 'c':
      grt.clearTrainingDataset();
    break;
    case '{': //Decrease the target vector value by 0.1 (only for REGRESSION_MODE)
      targetVector[0] -= 0.1;
      grt.sendTargetVector( targetVector );
    break;
    case '}': //Increase the target vector value by 0.1 (only for REGRESSION_MODE)
      targetVector[0] += 0.1;
      grt.sendTargetVector( targetVector );
    break;
    case '1': //Set the classifier as ANBC, enable scaling, enable null rejection, and set the null rejection coeff to 5.0
      grt.setClassifier( grt.ANBC, true, true, 5.0 );
    break;
    case '2'://Set the classifier as ADABOOST, enable scaling, disable null rejection, and set the null rejection coeff to 5.0
      grt.setClassifier( grt.ADABOOST, true, false, 5.0 );
    break;
    default:
      break;
  }
  if (key == 'h') {
    println("pressed h");

    // set hq the home quaternion as the quatnion conjugate coming from the sensor fusion
    hq = quatConjugate(q);
  }
  else if (key == 'n') {
    println("pressed n");
    hq = null;
  }
}
void quaternionToEuler(float [] q, float [] euler) {
  euler[0] = atan2(2 * q[1] * q[2] - 2 * q[0] * q[3], 2 * q[0]*q[0] + 2 * q[1] * q[1] - 1); // psi
  euler[1] = -asin(2 * q[1] * q[3] + 2 * q[0] * q[2]); // theta
  euler[2] = atan2(2 * q[2] * q[3] - 2 * q[0] * q[1], 2 * q[0] * q[0] + 2 * q[3] * q[3] - 1); // phi
}

float [] quatProd(float [] a, float [] b) {
  float [] q = new float[4];

  q[0] = a[0] * b[0] - a[1] * b[1] - a[2] * b[2] - a[3] * b[3];
  q[1] = a[0] * b[1] + a[1] * b[0] + a[2] * b[3] - a[3] * b[2];
  q[2] = a[0] * b[2] - a[1] * b[3] + a[2] * b[0] + a[3] * b[1];
  q[3] = a[0] * b[3] + a[1] * b[2] - a[2] * b[1] + a[3] * b[0];

  return q;
}

// returns a quaternion from an axis angle representation
float [] quatAxisAngle(float [] axis, float angle) {
  float [] q = new float[4];

  float halfAngle = angle / 2.0;
  float sinHalfAngle = sin(halfAngle);
  q[0] = cos(halfAngle);
  q[1] = -axis[0] * sinHalfAngle;
  q[2] = -axis[1] * sinHalfAngle;
  q[3] = -axis[2] * sinHalfAngle;

  return q;
}

// return the quaternion conjugate of quat
float [] quatConjugate(float [] quat) {
  float [] conj = new float[4];

  conj[0] = quat[0];
  conj[1] = -quat[1];
  conj[2] = -quat[2];
  conj[3] = -quat[3];

  return conj;
}

