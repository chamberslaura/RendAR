
// CaptureController V9
// Button press > Motor Rotations
// Add PID position control
// Add BLE communication
// Add Mass reading
// Lastest try at synching camera and turntable - Monday morning
// Synchronization works!

#include <ArduinoBLE.h>
#include "HX711.h"
#include <PID_v1.h>

#define button A2
#define encoder_A 3
#define encoder_B 4
#define motor_pwm A4
#define motor_dir A6
#define DAT_1 5
#define CLK_1 6
#define DAT_2 11
#define CLK_2 12
#define DAT_3 7
#define CLK_3 8
#define standby 0
#define measuringMass 1
#define massMeasurementComplete 2
#define takePhoto 3
#define rotating 4
#define photoTaken 5
#define captureComplete 6
#define cameraReady 7
#define startPressed 8

#define calibrationFactor1 450
#define calibrationFactor2 435
#define calibrationFactor3 446
#define zeroFactor1 -1931
#define zeroFactor2 11372
#define zeroFactor3 3429

int referenceAngle[] = {90, 270, 320, 320, 360};
int numberOfRotations = sizeof(referenceAngle) / sizeof(referenceAngle[0]);
int PPR = 3800;
float PPD = float(PPR) / float(360); // pulses per degree
double input, output, setpoint;
double kp = 10 , ki = 1 , kd = 0.1;
int pulses = 0;
int counter = 0;
int buttonState = LOW;
volatile byte ACurrent = 0;
volatile byte APrevious = 0;
int diff = 1000;
int i = 0;
int j = 0;
byte state = standby;
bool start = false;
int mass = 0;
int turntableMass = 1137;

BLEService captureService("1101");
BLEUnsignedIntCharacteristic stateChar("2101", BLERead | BLEWrite | BLENotify);
BLEUnsignedIntCharacteristic massChar("4101", BLERead | BLENotify);

HX711 loadcell1;
HX711 loadcell2;
HX711 loadcell3;


PID myPID(&input, &output, &setpoint, kp, ki, kd, DIRECT);

void setup() {
  Serial.begin(9600);
  while (!Serial);

  if (!BLE.begin()) {
    Serial.println("starting BLE failed!");
    while (1);
  }

  BLE.setDeviceName("RendAR");
  BLE.setLocalName("RendAR");
  BLE.setAdvertisedService(captureService);
  captureService.addCharacteristic(stateChar);
  captureService.addCharacteristic(massChar);
  BLE.addService(captureService);
  BLE.advertise();
  Serial.println("RendAR BLE active, waiting for connections...");

  pinMode(button, INPUT_PULLUP);
  pinMode(motor_pwm, OUTPUT);
  pinMode(motor_dir, OUTPUT);

  pinMode(encoder_A, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(encoder_A), updateEncoder, CHANGE);
  pinMode(encoder_B, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(encoder_B), updateEncoder, CHANGE);

  digitalWrite(encoder_A, HIGH); //turn pullup resistor on
  digitalWrite(encoder_B, HIGH); //turn pullup resistor on

  APrevious = digitalRead(encoder_A);
  counter = 0;

  loadcell1.begin(DAT_1, CLK_1);
  loadcell2.begin(DAT_2, CLK_2);
  loadcell3.begin(DAT_3, CLK_3);

  loadcell1.set_scale(calibrationFactor1); //This value is obtained by using the SparkFun_HX711_Calibration sketch
  loadcell2.set_scale(calibrationFactor2); //This value is obtained by using the SparkFun_HX711_Calibration sketch
  loadcell3.set_scale(calibrationFactor3); //This value is obtained by using the SparkFun_HX711_Calibration sketch
  //loadcell1.tare();
  //loadcell2.tare(); //Assuming there is no weight on the scale at start up, reset the scale to 0
  //loadcell3.tare();

  loadcell1.set_offset(zeroFactor1);
  loadcell2.set_offset(zeroFactor2);
  loadcell3.set_offset(zeroFactor3);
  

  myPID.SetMode(AUTOMATIC);   //set PID in Auto mode
  myPID.SetSampleTime(1);  // refresh rate of PID controller
  myPID.SetOutputLimits(-125, 125);
}

void loop() {

  BLEDevice central = BLE.central();

  if (central) {
    Serial.print("Connected to central: ");
    Serial.println(central.address());

    while (central.connected()) {
      Serial.println("BLE connected");
      delay(200);

      startButtonPressed();
      
      if ((i == 0 && start && stateChar.written()) || (i != 0 && stateChar.written())) {

        state = measuringMass;
        mass = getMass();
        massChar.writeValue(mass);
        Serial.print("Mass value written: ");
        Serial.print(mass);
        Serial.println("g");
        state = massMeasurementComplete;

        byte value = 0;
        stateChar.readValue(value);
        Serial.println("**************************");
        Serial.print("Recieved state value: ");
        Serial.println(value);

        i++;
        Serial.print("Count: ");
        Serial.println(i);

        if (value == cameraReady) {

          state = cameraReady;
          Serial.println("State received: cameraReady");
          stateChar.writeValue(startPressed);
          Serial.println("State written: startPressed");

        } else if (value == photoTaken) {

          Serial.println("State received: photoTaken");
          diff = 2000;
          state = rotating;
          Serial.println("State: Rotating");

          while (diff > 5 && state == rotating) {
            setpoint = (degreesToPulses(referenceAngle[j]));
            updateEncoder();
            input = counter;
            /*Serial.print("Rotation # ");
            Serial.println(j+1);
            Serial.print("Reference = ");
            Serial.print(referenceAngle[j]);
            Serial.println(" degrees");
            Serial.print("Setpoint = ");
            Serial.print(setpoint);
            Serial.println(" pulses");
            Serial.print("Input = ");
            Serial.println(input);
            Serial.println(" pulses");
            Serial.print("Error: ");
            Serial.println(diff);*/
            diff = abs(setpoint - input);

            if (myPID.Compute()) {
              rotate(output);
            }
          }
          j++;
          state = takePhoto;
          stateChar.writeValue(takePhoto);
          Serial.println("State written: takePhoto");

        } else if (value == captureComplete) {

          Serial.println("State received: captureComplete");
          state = captureComplete;
          delay(500);
          Serial.println("DELAY 500");
                    reset();
          Serial.println("RESET");
        }
        stop();
        Serial.println("STOP");
      }
    }
  }
  Serial.print("Disconnected from central: ");
  Serial.println(central.address());
}

//------------------------------------
// Helper Functions
// -----------------------------------

int degreesToPulses(int degrees) {
  int pulses = round(degrees * PPD);
  return pulses;
}

bool startButtonPressed() {
  buttonState = digitalRead(button);
  if (buttonState == HIGH) {
    Serial.println("Button pressed!");
    start = true;
    return true;
  } else {
    Serial.println("Waiting for button press...");
    return false;
  }
}

void reset() {
  state = standby;
  start = false;
  i = 0;
  j = 0;
  counter = 0;
  stop();
  return;
}

void updateEncoder() {
  ACurrent = digitalRead(encoder_A);
  if (ACurrent != APrevious) {
    // If the outputB state is different to the outputA state, that means the encoder is rotating clockwise
    if (digitalRead(encoder_B) != ACurrent) {
      counter ++;
    } else {
      counter --;
    }
  }
  APrevious = ACurrent;
}

void rotate(int out) {
  analogWrite(motor_pwm, abs(out));
  if (out > 0) {
    clockwise();
  }
  else {
    counterClockwise();
  }
}

void clockwise() {
  digitalWrite(motor_dir, LOW);
}

void counterClockwise() {
  digitalWrite(motor_dir, HIGH);
}

void stop() {
  analogWrite(motor_pwm, 0);
}

int getMass() {
  if (loadcell1.is_ready() && loadcell2.is_ready() && loadcell3.is_ready()) {
    float mass1 = loadcell1.get_units();
    float mass2 = loadcell2.get_units();
    float mass3 = loadcell3.get_units();
    float totalMass = mass1 + mass2 + mass3 - turntableMass;
    float sendMass = totalMass/5;
    return sendMass;
  } else {
    Serial.println("HX711 not found.");
    return -1;
  }
}
