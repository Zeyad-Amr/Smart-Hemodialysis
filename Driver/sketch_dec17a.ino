#include <OneWire.h>
#include <DallasTemperature.h>
#include <math.h>

// Define Thermistor pin
#define ONE_WIRE_BUS 6
#define MINIMUM_TEMP 20
#define MAXIMUM_TEMP 42

// Define dialysate Ultrasonic pins
#define DIALYSATE_ECHO 2
#define DIALYSATE_TRIGGER 3
#define DIALYSATE_CONTAINER_HEATER_LEVEL 4
#define DIALYSATE_CONTAINER_PUMP_LEVEL 12

// Define blood Ultrasonic pins
#define BLOOD_ECHO 9
#define BLOOD_TRIGGER 10

// Define dialysate pump pin
#define DIALYSATE_PUMP 4

// Define blood pumps pins
#define FIRST_BLOOD_PUMP  8
#define SECOND_BLOOD_PUMP 7

// Define Heater pin
#define HEATER_PIN 5

// Define Water Level Sensor pin
#define DRAIN_PIN A0
#define DRAIN_MAXIMUM_LEVEL 80

// Flow Measurements
//-------- Dialysate --------//
#define DIALYSATE_CONTAINER_AREA 22*12
#define DIALYSATE_MINIMUM_FLOW 500
#define DIALYSATE_MAXIMAUM_FLOW 800
//-------- Blood --------//
#define BLOOD_CONTAINER_AREA 125
#define BLOOD_MINIMUM_FLOW 200
#define BLOOD_MAXIMAUM_FLOW 450

// Variables
float distance = 0;
double temp = 0;
bool Temp_flag = 0;
bool isOnForHeater = 0;
bool isOnForPump = 0;
float Celcius = 0;

// for DallasTemperature
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

void setup() {
  // For Serial
  Serial.begin(9600);

  // DallasTemperature begin
  sensors.begin(); 

  // Set BLOOD ULTRASONIC SENSOR
  pinMode(BLOOD_TRIGGER, OUTPUT);
  pinMode(BLOOD_ECHO, INPUT);

  // Set DIALYSATE ULTRASONIC SENSOR
  pinMode(DIALYSATE_TRIGGER, OUTPUT);
  pinMode(DIALYSATE_ECHO, INPUT);
  
  // Set Dialysate PUMP RELAY
  pinMode(DIALYSATE_PUMP, OUTPUT);
  digitalWrite(DIALYSATE_PUMP, HIGH);

  // Set first BLOOD PUMP RELAY
  pinMode(FIRST_BLOOD_PUMP, OUTPUT);
  digitalWrite(FIRST_BLOOD_PUMP, LOW);

  // Set Second BLOOD PUMP RELAY
  pinMode(SECOND_BLOOD_PUMP, OUTPUT);
  digitalWrite(SECOND_BLOOD_PUMP, LOW);

  // Set Heater Relay as outputs
  pinMode(HEATER_PIN, OUTPUT);
  digitalWrite(HEATER_PIN, HIGH);

}

void loop() {
  delay(3000);
  isOnForHeater = DIALYSATE_checkContainerLevel_forHeater();

  // For temperature measurement
  temp = getTemp();

  Serial.print("temp =");
  Serial.println(temp);

  while (temp < MINIMUM_TEMP){
    Serial.println("Heater is ON");
    HEATER_on();
    temp = getTemp();
    Serial.print("temp =");
    Serial.println(temp);
  }

  Serial.println("Heater is OFF");
  HEATER_off();

  PUMP_on(FIRST_BLOOD_PUMP);
  FLOW_Measurement(BLOOD_CONTAINER_AREA, BLOOD_MINIMUM_FLOW, BLOOD_MAXIMAUM_FLOW, BLOOD_ECHO, BLOOD_TRIGGER);
  PUMP_off(FIRST_BLOOD_PUMP);
  delay(1000);

  PUMP_on(DIALYSATE_PUMP);
  FLOW_Measurement(DIALYSATE_CONTAINER_AREA, DIALYSATE_MINIMUM_FLOW, DIALYSATE_MAXIMAUM_FLOW, DIALYSATE_ECHO, DIALYSATE_TRIGGER);
  PUMP_off(DIALYSATE_PUMP);
  delay(1000);

  PUMP_on(DIALYSATE_PUMP);
  PUMP_on(FIRST_BLOOD_PUMP);
  delay(5000);
  PUMP_on(SECOND_BLOOD_PUMP);

  isOnForPump = DIALYSATE_checkContainerLevel_drainLevel();
  PUMP_off(DIALYSATE_PUMP);
  
  delay(1000);
}



/////////////////////////// Temp Measuerment ///////////////////////////
double getTemp()
{
  sensors.requestTemperatures(); 
  Celcius=sensors.getTempCByIndex(0);
  return Celcius;
}

float calcDistance(int echo, int trig)
{
  float duration;
  float dis;
  digitalWrite(trig, LOW);
  delayMicroseconds(2);
  digitalWrite(trig, HIGH);
  delayMicroseconds(10);
  digitalWrite(trig, LOW);
  duration = pulseIn(echo, HIGH);

  distance = (duration / 2) * 0.0343;
  return distance;
}

void HEATER_on(){
    digitalWrite(HEATER_PIN, LOW); // Reversed polarity
}

void HEATER_off(){
    digitalWrite(HEATER_PIN, HIGH); // Reversed polarity
}

void PUMP_on(int pump){
  if (pump == DIALYSATE_PUMP){
    digitalWrite(pump, LOW); 
  }
  else{
    digitalWrite(pump, HIGH);  
  }
}

void PUMP_off(int pump){
  if (pump == DIALYSATE_PUMP){
    digitalWrite(pump, HIGH);
  }
  else{
    digitalWrite(pump, LOW);
  }
}

bool DIALYSATE_checkContainerLevel_forHeater(){
    float distance_forHeater = calcDistance(DIALYSATE_ECHO, DIALYSATE_TRIGGER);

    Serial.print("distance_forHeater =");
    Serial.println(distance_forHeater);

    while (distance_forHeater > DIALYSATE_CONTAINER_HEATER_LEVEL){
      Serial.print("distance_forHeater =");
      Serial.println(distance_forHeater);
      distance_forHeater = calcDistance(DIALYSATE_ECHO, DIALYSATE_TRIGGER);
    }
    return true;
}


float FLOW_Measurement(float area, int minimum_flow, int maximum_flow, int echo, int trig){
  float flow = FLOW_calculations(area, echo, trig);
  while( !(flow > minimum_flow && flow < maximum_flow) ){    
    flow = FLOW_calculations(area, echo, trig);
  }

  return flow;
}

float FLOW_calculations(float area, int echo, int trig){

    float time = 7000;

    float first_distance = calcDistance(echo, trig);
    delay(time);
    float second_distance = calcDistance(echo, trig);

    float delta_distance = first_distance - second_distance;
    time = (time/1000)/60;

    float flow = (area * delta_distance) / time;

    Serial.print("Flow = ");
    Serial.println(flow);

    delay(500);

    return flow;
}

int DRAIN_levelCalculations(){
  int value = analogRead(DRAIN_PIN);
  int percentage = (value/10)+35;

  if(percentage>50){
    return percentage; 
  }
  else{
  return 0;
  }

}

bool DIALYSATE_checkContainerLevel_drainLevel(){
    float distance_forPump = calcDistance(DIALYSATE_ECHO, DIALYSATE_TRIGGER);

    Serial.print("distance_forPump =");
    Serial.println(distance_forPump);
    int drainLevel = DRAIN_levelCalculations();    

    while(distance_forPump <= DIALYSATE_CONTAINER_PUMP_LEVEL && drainLevel <= DRAIN_MAXIMUM_LEVEL){
      Serial.print("distance_forPump =");
      Serial.println(distance_forPump);
      Serial.print("distance_DRAIN =");
      Serial.println(drainLevel);
      distance_forPump = calcDistance(DIALYSATE_ECHO, DIALYSATE_TRIGGER);
      drainLevel = DRAIN_levelCalculations();
      delay(500);
    }

    return true;
}