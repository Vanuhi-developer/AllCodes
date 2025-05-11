#include <WiFi.h>
#include <HTTPClient.h>
#include <Keypad.h>

const char* ssid = "Xiaomi_9076";
const char* password = "robotronlab";

const byte ROWS = 4;
const byte COLS = 4;

char keys[ROWS][COLS] = {
  {'D', 'C', 'B', 'A'},
  {'#', '9', '6', '3'},
  {'0', '8', '5', '2'},
  {'*', '7', '4', '1'}
};

byte rowPins[ROWS] = {13, 12, 14, 27}; // R1 to R4
byte colPins[COLS] = {26, 25, 33, 32}; // C1 to C4

Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);

String enteredNumber = "";
bool isNewInput = true;

void setup() {
  Serial.begin(115200);

  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected!");
}

void loop() {
  char key = keypad.getKey();

  if (key) {
    if (key == 'D') {
      if (enteredNumber.length() == 6) {
        Serial.print("\nՄուտքագրված թիվը՝ ");
        Serial.println(enteredNumber);
        sendCodeToAPI(enteredNumber); // Send to API
      } else {
        Serial.println("\nԽնդրում եմ մուտքագրել 6 նիշից բաղկացած թիվ:");
      }
      enteredNumber = "";
      isNewInput = true;
    } else if (key >= '0' && key <= '9') {
      if (enteredNumber.length() < 6) {
        enteredNumber += key;
        if (isNewInput) {
          Serial.print("Մուտքագրածը՝ ");
          isNewInput = false;
        }
        Serial.print(key);
      }
    }
  }
}

void sendCodeToAPI(String code) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin("http://192.168.2.105:8000/api/check-booking-code");
    http.addHeader("Content-Type", "application/json");

    String jsonBody = "{\"random_code\": \"" + code + "\"}";

    int httpResponseCode = http.POST(jsonBody);

    if (httpResponseCode > 0) {
      String response = http.getString();
      Serial.println("\nՍերվերի պատասխանը՝");
      Serial.println(response);
    } else {
      Serial.print("POST խնդրի պատասխան չկա, կոդ՝ ");
      Serial.println(httpResponseCode);
    }

    http.end();
  } else {
    Serial.println("WiFi միացված չէ։");
  }
}
