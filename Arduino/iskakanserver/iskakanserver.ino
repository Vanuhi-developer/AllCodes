#include <esp_now.h>
#include <WiFi.h>
#include <Wire.h>
#include <ESP32Servo.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// I2C LCD Address (Change to 0x3F if needed)
#define LCD_ADDR 0x27
#define LCD_BACKLIGHT 0x08
#define ENABLE 0b00000100
#define RS 0b00000001

// Pin Definitions
#define ENTRY_SENSOR_PIN 14
#define EXIT_SENSOR_PIN 34
#define SERVO_PIN 13

Servo gateServo;
int TOTAL_SLOTS = 4; // default value, in case API fails
int availableSlots = TOTAL_SLOTS;
bool entryActive = false;  // Prevents exit sensor from triggering while entry is active

unsigned long lastFetchTime = 0;  // Time of last API call
const unsigned long fetchInterval = 5000;  // 5 seconds interval for API calls

// --- LCD Functions ---
void sendToLCD(byte data, byte mode) {
    Wire.beginTransmission(LCD_ADDR);
    Wire.write(mode | (data & 0xF0) | LCD_BACKLIGHT);
    Wire.write(mode | (data & 0xF0) | LCD_BACKLIGHT | ENABLE);
    Wire.write(mode | (data & 0xF0) | LCD_BACKLIGHT);

    Wire.write(mode | ((data << 4) & 0xF0) | LCD_BACKLIGHT);
    Wire.write(mode | ((data << 4) & 0xF0) | LCD_BACKLIGHT | ENABLE);
    Wire.write(mode | ((data << 4) & 0xF0) | LCD_BACKLIGHT);
    Wire.endTransmission();
}

void lcdCommand(byte cmd) {
    sendToLCD(cmd, 0);
    delay(15);
}

void lcdPrintChar(byte character) {
    sendToLCD(character, RS);
}

void lcdPrint(const char *str) {
    while (*str) {
        lcdPrintChar(*str++);
    }
}

void lcdInit() {
    Wire.begin(26, 25);
    delay(50);

    sendToLCD(0x30, 0);
    delay(5);
    sendToLCD(0x30, 0);
    delay(1);
    sendToLCD(0x30, 0);
    delay(1);
    sendToLCD(0x20, 0);
    delay(1);

    lcdCommand(0x28);
    lcdCommand(0x0C);
    lcdCommand(0x06);
    lcdCommand(0x01);
    delay(5);
}

void lcdClear() {
    lcdCommand(0x01);
    delay(5);
}

void lcdSetCursor(int row, int col) {
    int row_offsets[] = {0x00, 0x40, 0x14, 0x54};
    lcdCommand(0x80 | (col + row_offsets[row]));
}

// --- Gate Functions ---
void openGate() {
    gateServo.write(90);
    delay(5000);  // Increase the delay to 5 seconds before closing the gate
    gateServo.write(0);
}

// --- ESP-NOW Message Handling ---
void onDataReceive(const esp_now_recv_info_t* recvInfo, const uint8_t* data, int len) {
    Serial.print("Received from: ");
    
    for (int i = 0; i < 6; i++) {
        Serial.printf("%02X", recvInfo->src_addr[i]);
        if (i < 5) Serial.print(":");
    }
    Serial.print(" | Data: ");

    char message[len + 1];
    memcpy(message, data, len);
    message[len] = '\0';  // Ensure null termination

    Serial.println(message);

    // Ensure all received characters are printable
    for (int i = 0; i < len; i++) {
        if (message[i] < 32 || message[i] > 126) {
            message[i] = ' ';
        }
    }

    // Split message using "|" as a delimiter
    char *message1 = strtok(message, "|");
    char *message2 = strtok(NULL, "|");

    lcdClear();
    lcdSetCursor(0, 0);
    if (message1) lcdPrint(message1);

    lcdSetCursor(1, 0);
    if (message2) lcdPrint(message2);

    Serial.print("LCD Line 1: ");
    Serial.println(message1 ? message1 : "NULL");
    delay(3000); 
    Serial.print("LCD Line 2: ");
    Serial.println(message2 ? message2 : "NULL");
}

// --- Fetch TOTAL_SLOTS from API ---
void fetchTotalSlotsFromAPI() {
    HTTPClient http;
    http.begin("http://192.168.2.106:8000/api/parking-slot/count");

    int httpCode = http.GET();
    if (httpCode == 200) {
        String payload = http.getString();
        Serial.println("API Response: " + payload);

        DynamicJsonDocument doc(1024);
        DeserializationError error = deserializeJson(doc, payload);
        
        if (error) {
            Serial.print("Failed to parse JSON: ");
            Serial.println(error.f_str());
        } else {
            availableSlots = doc["count_slot"];
            Serial.print("Total Slots: ");
            Serial.println(TOTAL_SLOTS);
        }
    } else {
        Serial.print("Failed to fetch slot count, HTTP code: ");
        Serial.println(httpCode);
    }

    http.end();
}

// --- Decrement API ---
void decrementCountSlot() {
    HTTPClient http;
    http.begin("http://192.168.2.106:8000/api/decrementtCountSlot");
    int httpCode = http.GET();
    if (httpCode == 200) {
        Serial.println("Slot count decremented successfully");
    } else {
        Serial.print("Failed to decrement slot count. HTTP code: ");
        Serial.println(httpCode);
    }
    http.end();
}

// --- Increment API ---
void incrementCountSlot() {
    HTTPClient http;
    http.begin("http://192.168.2.106:8000/api/incrementtCountSlot");
    int httpCode = http.GET();
    if (httpCode == 200) {
        Serial.println("Slot count incremented successfully");
    } else {
        Serial.print("Failed to increment slot count. HTTP code: ");
        Serial.println(httpCode);
    }
    http.end();
}

// --- Setup ---
void setup() {
    Serial.begin(115200);

    WiFi.begin("Tenda_1893E8", "093339396");

    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }

    Serial.println("WiFi connected");

    gateServo.attach(SERVO_PIN);
    gateServo.write(0);

    pinMode(ENTRY_SENSOR_PIN, INPUT);
    pinMode(EXIT_SENSOR_PIN, INPUT);

    lcdInit();
    lcdSetCursor(0, 0);
    lcdPrint("Connecting...");

    fetchTotalSlotsFromAPI();

    lcdClear();
    lcdSetCursor(0, 0);
    lcdPrint("Slots: ");
    lcdPrint(String(TOTAL_SLOTS).c_str());

    Serial.print("Server MAC Address: ");
    Serial.println(WiFi.macAddress());

    if (esp_now_init() != ESP_OK) {
        Serial.println("ESP-NOW Initialization Failed");
        lcdSetCursor(1, 0);
        lcdPrint("ESP-NOW Error!");
        return;
    }

    esp_now_register_recv_cb(onDataReceive);

    Serial.println("ESP-NOW Server Ready");
}

void loop() {
    if (millis() - lastFetchTime >= fetchInterval) {
        fetchTotalSlotsFromAPI();
        lastFetchTime = millis();
    }

    int entryState = digitalRead(ENTRY_SENSOR_PIN);
    int exitState = digitalRead(EXIT_SENSOR_PIN);

    if (entryState == LOW && !entryActive) {
        entryActive = true;
        if (availableSlots > 0) {
            Serial.println("Car detected at entry");
            openGate();
            availableSlots--;
            decrementCountSlot();
            Serial.print("Available Slots: ");
            Serial.println(availableSlots);
            lcdClear();
            lcdSetCursor(0, 0);
            lcdPrint("Slots Left: ");
            lcdPrint(String(availableSlots).c_str());
            delay(5000);
        } else {
            Serial.println("Parking Full! Entry Denied");
            lcdClear();
            lcdSetCursor(0, 0);
            lcdPrint("Parking Full!");
            lcdSetCursor(1, 0);
            lcdPrint("Entry Denied");
            delay(5000);  
        }
        delay(3000);
        entryActive = false;
    }

    if (exitState == LOW && availableSlots < TOTAL_SLOTS && !entryActive) {
        Serial.println("Car detected at exit");
        openGate();
        availableSlots++;
        incrementCountSlot();
        Serial.print("Available Slots: ");
        Serial.println(availableSlots);
        lcdClear();
        lcdSetCursor(0, 0);
        lcdPrint("Slots Left: ");
        lcdPrint(String(availableSlots).c_str());
        delay(5000);
    }
}
