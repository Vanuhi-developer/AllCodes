#include <esp_now.h>
#include <WiFi.h>
#include <HTTPClient.h>  // Include HTTPClient for making HTTP requests

// MAC address of the server ESP32 (replace with actual MAC address of the server)
uint8_t serverMAC[] = {0x0C, 0xB8, 0x15, 0x59, 0x53, 0x88};

#define TRIG1 2
#define ECHO1 15
#define TRIG2 12
#define ECHO2 13

#define RED_LED1 35
#define GREEN_LED1 32
#define RED_LED2 19
#define GREEN_LED2 18

const int threshold = 10; // Distance threshold in cm
bool peerAdded = false;

const String BASE_URL = "http://192.168.2.106:8000/api/updateSlot/"; // Global API URL

void sendData(const char *message1) {
    if (!peerAdded) {
        esp_now_peer_info_t peerInfo;
        memset(&peerInfo, 0, sizeof(peerInfo));
        memcpy(peerInfo.peer_addr, serverMAC, 6);
        peerInfo.channel = 0;
        peerInfo.encrypt = false;
        peerInfo.ifidx = WIFI_IF_STA;

        esp_err_t addPeerResult = esp_now_add_peer(&peerInfo);
        if (addPeerResult != ESP_OK) {
            Serial.println("Failed to add peer");
            return;
        }
        peerAdded = true;
        Serial.println("Peer added successfully");
    }

    esp_err_t result = esp_now_send(serverMAC, (const uint8_t *)message1, strlen(message1));
    if (result == ESP_OK) {
        Serial.println("message1 sent successfully");
    } else {
        Serial.println("Error sending message1");
    }
}

void updateSlotStatus(int slotNumber, const String &status) {
    if (WiFi.status() == WL_CONNECTED) {
        HTTPClient http;
        
        // Concatenate the base URL with the slot number
        String url = BASE_URL + String(slotNumber);
        
        http.begin(url);  // Initiate the HTTP request
        http.addHeader("Content-Type", "application/json"); // Add header for JSON
        String payload = "{\"status\":\"" + status + "\"}"; // Create JSON payload

        // Send a PATCH request
        int httpCode = http.PATCH(payload);
        
        if (httpCode > 0) {
            Serial.print("HTTP PATCH Status Code: ");
            Serial.println(httpCode);
            String payloadResponse = http.getString(); // Get the response payload
            Serial.println("Server Response:");
            Serial.println(payloadResponse);  // Print the response body for debugging
        } else {
            Serial.print("Error on sending PATCH request: ");
            Serial.println(httpCode);
        }
        
        http.end(); // Close the HTTP connection
    } else {
        Serial.println("WiFi not connected");
    }
}

void setup() {
    Serial.begin(115200);
    WiFi.mode(WIFI_STA);
    WiFi.disconnect();

    if (esp_now_init() != ESP_OK) {
        Serial.println("ESP-NOW Initialization Failed");
        return;
    }
    Serial.println("ESP-NOW Initialized");

    pinMode(TRIG1, OUTPUT);
    pinMode(ECHO1, INPUT);
    pinMode(TRIG2, OUTPUT);
    pinMode(ECHO2, INPUT);
    pinMode(RED_LED1, OUTPUT);
    pinMode(GREEN_LED1, OUTPUT);
    pinMode(RED_LED2, OUTPUT);
    pinMode(GREEN_LED2, OUTPUT);

    // Connect to WiFi
    Serial.print("Connecting to WiFi...");
    WiFi.begin("Tenda_1893E8", "093339396");
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("WiFi connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
}

int getDistance(int trigPin, int echoPin) {
    digitalWrite(trigPin, LOW);
    delayMicroseconds(2);
    digitalWrite(trigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPin, LOW);

    long duration = pulseIn(echoPin, HIGH);
    int distance = duration * 0.034 / 2;
    return distance;
}

void loop() {
    int distance1 = getDistance(TRIG1, ECHO1);
    int distance2 = getDistance(TRIG2, ECHO2);

    Serial.print("Sensor 1: ");
    Serial.print(distance1);
    Serial.print(" cm  |  Sensor 2: ");
    Serial.print(distance2);
    Serial.println(" cm");

    char message1[50];
    if (distance1 <= threshold) {
        digitalWrite(RED_LED1, HIGH);
        digitalWrite(GREEN_LED1, LOW);
        sprintf(message1, "Slot 1: BUSY, ");
        updateSlotStatus(1, "busy"); // Update the API with Slot 1 status as BUSY
    } else {
        digitalWrite(RED_LED1, LOW);
        digitalWrite(GREEN_LED1, HIGH);
        sprintf(message1, "Slot 1: FREE, ");
        updateSlotStatus(1, "free"); // Update the API with Slot 1 status as FREE
    }

    if (distance2 <= threshold) {
        digitalWrite(RED_LED2, HIGH);
        digitalWrite(GREEN_LED2, LOW);
        strcat(message1, "Slot 2: BUSY");
        updateSlotStatus(2, "busy"); // Update the API with Slot 2 status as BUSY
    } else {
        digitalWrite(RED_LED2, LOW);
        digitalWrite(GREEN_LED2, HIGH);
        strcat(message1, "Slot 2: FREE");
        updateSlotStatus(2, "free"); // Update the API with Slot 2 status as FREE
    }

    Serial.println(message1);
    sendData(message1);
    
    Serial.println("--------------------");
    delay(2000);
}
