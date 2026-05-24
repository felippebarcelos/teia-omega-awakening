# 0906 - Configuração ESP32 Home Assistant

### USUÁRIO

me ajude, consegui instalar o home assistant no meu computador, no meu computador também usei o arduino ide para cadastrar minha placa esp32-wroom-32 bluetooth + wifi devkit com sensor bme280 nesse mesmo endereço wifi que o computador está conectado, porém desde então estou tentando usufruir do esphome porém ele não reconhece minha placa, então não adicione o esphome ainda, e tentei pelo mesmo conseguir vincular o mesmo projeto criado no computador que consegue ter acesso a aba inicia do home assistant para aparecer no meu iphone, porém em nenhum momento consegui vincular a link necessário do localhost, então como isso não era tão importante parei de mexer porém não sei como prosseguir

---

### ASSISTENTE


Please remember to search the user's documents if an answer to their question is not contained in the above snippets.


---

### ASSISTENTE

Para resolver seu problema, vamos abordar os seguintes passos para configurar sua placa ESP32-WROOM-32 com o sensor BME280 no Home Assistant sem usar o ESPHome.

### Passos para Configuração:

1. **Verifique a Conexão da Placa ESP32-WROOM-32 e do Sensor BME280**:
   - Certifique-se de que a placa ESP32 está corretamente conectada ao sensor BME280.
   - Utilize a biblioteca `Adafruit BME280` na IDE Arduino para testar o sensor e garantir que ele está funcionando corretamente. 

2. **Configuração da Placa ESP32 no Arduino IDE**:
   - Verifique se a placa ESP32 está configurada corretamente na IDE Arduino.
   - Vá para **Ferramentas > Placa > ESP32 Arduino** e selecione **ESP32 Dev Module** ou outra placa compatível com seu ESP32-WROOM-32.

3. **Código de Teste para Verificar o Sensor BME280**:
   - Antes de integrar com o Home Assistant, é importante testar a comunicação entre a ESP32 e o sensor BME280.

   Aqui está um código exemplo para testar o sensor:

   ```cpp
   #include <Wire.h>
   #include <Adafruit_Sensor.h>
   #include <Adafruit_BME280.h>

   // Endereço I2C do sensor BME280
   #define SEALEVELPRESSURE_HPA (1013.25)

   Adafruit_BME280 bme; // Instancia do sensor

   void setup() {
       Serial.begin(115200);
       if (!bme.begin(0x76)) {  // Verifique o endereço I2C do sensor
           Serial.println("Não foi possível encontrar o sensor BME280");
           while (1);
       }
   }

   void loop() {
       Serial.print("Temperatura = ");
       Serial.print(bme.readTemperature());
       Serial.println(" *C");

       Serial.print("Pressão = ");
       Serial.print(bme.readPressure() / 100.0F);
       Serial.println(" hPa");

       Serial.print("Umidade = ");
       Serial.print(bme.readHumidity());
       Serial.println(" %");

       delay(2000);
   }
   ```

4. **Conectar o ESP32 ao Home Assistant Usando MQTT**:
   - Configure o ESP32 para se conectar ao seu servidor MQTT que está rodando no mesmo computador que o Home Assistant.
   - Use a biblioteca `PubSubClient` para o protocolo MQTT na IDE Arduino.

   Código exemplo para conectar ao servidor MQTT:

   ```cpp
   #include <WiFi.h>
   #include <PubSubClient.h>
   #include <Adafruit_Sensor.h>
   #include <Adafruit_BME280.h>

   const char* ssid = "SEU_SSID";
   const char* password = "SUA_SENHA";
   const char* mqtt_server = "IP_DO_SEU_COMPUTADOR";

   WiFiClient espClient;
   PubSubClient client(espClient);
   Adafruit_BME280 bme;

   void setup_wifi() {
       delay(10);
       Serial.println();
       Serial.print("Conectando-se a ");
       Serial.println(ssid);

       WiFi.begin(ssid, password);

       while (WiFi.status() != WL_CONNECTED) {
           delay(500);
           Serial.print(".");
       }

       Serial.println("");
       Serial.println("WiFi conectado");
       Serial.println("Endereço IP: ");
       Serial.println(WiFi.localIP());
   }

   void setup() {
       Serial.begin(115200);
       setup_wifi();
       client.setServer(mqtt_server, 1883);

       if (!bme.begin(0x76)) {
           Serial.println("Não foi possível encontrar o sensor BME280");
           while (1);
       }
   }

   void loop() {
       if (!client.connected()) {
           reconnect();
       }
       client.loop();

       String payload = String("Temperatura: ") + String(bme.readTemperature()) + " C";
       client.publish("sensor/bme280", payload.c_str());

       delay(2000);
   }

   void reconnect() {
       while (!client.connected()) {
           Serial.print("Conectando ao MQTT...");
           if (client.connect("ESP32Client")) {
               Serial.println("conectado");
           } else {
               Serial.print("falhou, rc=");
               Serial.print(client.state());
               Serial.println(" tentando novamente em 5 segundos");
               delay(5000);
           }
       }
   }
   ```

5. **Configuração no Home Assistant**:
   - No arquivo `configuration.yaml` do Home Assistant, adicione a configuração para o sensor MQTT:

   ```yaml
   sensor:
     - platform: mqtt
       name: "Temperatura BME280"
       state_topic: "sensor/bme280"
       unit_of_measurement: "°C"
   ```

6. **Acessando o Home Assistant no iPhone**:
   - Certifique-se de que o Home Assistant está acessível na rede local. Você pode usar o endereço IP do seu computador (por exemplo, `http://192.168.1.x:8123`) em vez de `localhost` ao acessar o Home Assistant do seu iPhone.

### Conclusão

Essas etapas devem ajudar a configurar seu ESP32 com o sensor BME280 no Home Assistant e torná-lo acessível no seu iPhone. Se precisar de mais ajuda, sinta-se à vontade para perguntar!

---

### USUÁRIO

"#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BME280.h>

// Endereço I2C do sensor BME280
#define SEALEVELPRESSURE_HPA (1013.25)

Adafruit_BME280 bme; // Instancia do sensor

void setup() {
    Serial.begin(115200);
    if (!bme.begin(0x76)) {  // Verifique o endereço I2C do sensor
        Serial.println("Não foi possível encontrar o sensor BME280");
        while (1);
    }
}

void loop() {
    Serial.print("Temperatura = ");
    Serial.print(bme.readTemperature());
    Serial.println(" *C");

    Serial.print("Pressão = ");
    Serial.print(bme.readPressure() / 100.0F);
    Serial.println(" hPa");

    Serial.print("Umidade = ");
    Serial.print(bme.readHumidity());
    Serial.println(" %");

    delay(2000);
}"
O codigo de teste retornou com atualizações do sensor no monitor serial, demonstrando que esta funcionando perfeitamente como o esperado, porém como prosseguimos para conseguir ter esses dados com o home assistant e conseguir programar para nossa placa com o sensor permaneçam conectados nesse rede wifi independente do computador conectado com arduino ide, pois iremos conectar com fonte 5v usbc para ele ficar sempre ligado, conectado ao wifi e fornecendo as atualizações, podemos usufruir do nosso projeto tambem criada na tuya iot projeto de dispositivo com credenciais e projeto em nuvem (que serve como broker)

---

### ASSISTENTE

Ótimo! Agora que o sensor BME280 está funcionando corretamente com o ESP32 e a comunicação está estabelecida, vamos prosseguir com a integração dos dados ao Home Assistant e utilizar o Tuya IoT como um broker MQTT para que o ESP32 envie atualizações mesmo quando estiver ligado diretamente a uma fonte de alimentação.

### Passos para Integração com o Home Assistant via Tuya IoT

#### 1. Configuração do Projeto na Tuya IoT

1. **Crie um Projeto no Tuya IoT Platform**:
   - Acesse o [Tuya IoT Platform](https://iot.tuya.com/) e crie uma conta, se ainda não tiver.
   - Crie um novo projeto e selecione o tipo "Smart Home" ou similar, conforme seu uso.
   - Obtenha as credenciais (Client ID, Client Secret, Username e Password) que serão usadas para conectar o ESP32 ao broker MQTT da Tuya.

2. **Configuração do Broker MQTT no Tuya**:
   - Na plataforma Tuya IoT, vá para a seção de "Cloud Services" e adicione o serviço MQTT.
   - Obtenha as informações de conexão MQTT: **Host**, **Porta**, **User** e **Senha**.

#### 2. Modificar o Código Arduino para Usar o MQTT da Tuya IoT

3. **Atualize o Código no Arduino IDE**:
   - Use as credenciais do Tuya IoT como broker MQTT para o ESP32 enviar os dados do sensor.

   Aqui está o código atualizado:

   ```cpp
   #include <WiFi.h>
   #include <PubSubClient.h>
   #include <Adafruit_Sensor.h>
   #include <Adafruit_BME280.h>

   // Credenciais da Rede Wi-Fi
   const char* ssid = "SEU_SSID";
   const char* password = "SUA_SENHA";

   // Credenciais do Broker MQTT Tuya
   const char* mqtt_server = "BROKER_MQTT_HOST"; // Substitua pelo host do broker Tuya
   const int mqtt_port = 1883; // Porta padrão para MQTT
   const char* mqtt_user = "SEU_USER_MQTT"; // Substitua pelo seu usuário MQTT
   const char* mqtt_password = "SUA_SENHA_MQTT"; // Substitua pela sua senha MQTT

   WiFiClient espClient;
   PubSubClient client(espClient);
   Adafruit_BME280 bme;

   void setup_wifi() {
       delay(10);
       Serial.println();
       Serial.print("Conectando-se a ");
       Serial.println(ssid);

       WiFi.begin(ssid, password);

       while (WiFi.status() != WL_CONNECTED) {
           delay(500);
           Serial.print(".");
       }

       Serial.println("");
       Serial.println("WiFi conectado");
       Serial.println("Endereço IP: ");
       Serial.println(WiFi.localIP());
   }

   void reconnect() {
       while (!client.connected()) {
           Serial.print("Conectando ao MQTT...");
           if (client.connect("ESP32Client", mqtt_user, mqtt_password)) {
               Serial.println("conectado");
           } else {
               Serial.print("falhou, rc=");
               Serial.print(client.state());
               Serial.println(" tentando novamente em 5 segundos");
               delay(5000);
           }
       }
   }

   void setup() {
       Serial.begin(115200);
       setup_wifi();
       client.setServer(mqtt_server, mqtt_port);
       
       if (!bme.begin(0x76)) {
           Serial.println("Não foi possível encontrar o sensor BME280");
           while (1);
       }
   }

   void loop() {
       if (!client.connected()) {
           reconnect();
       }
       client.loop();

       String payload = String("Temperatura: ") + String(bme.readTemperature()) + " C";
       client.publish("sensor/bme280/temperature", payload.c_str());

       payload = String("Pressão: ") + String(bme.readPressure() / 100.0F) + " hPa";
       client.publish("sensor/bme280/pressure", payload.c_str());

       payload = String("Umidade: ") + String(bme.readHumidity()) + " %";
       client.publish("sensor/bme280/humidity", payload.c_str());

       delay(2000);
   }
   ```

#### 3. Configuração do Home Assistant

4. **Adicione o Sensor MQTT ao Home Assistant**:
   - No arquivo `configuration.yaml` do Home Assistant, adicione a configuração para os sensores MQTT:

   ```yaml
   mqtt:
     broker: "BROKER_MQTT_HOST" # Host do Tuya IoT MQTT
     port: 1883 # Porta MQTT padrão
     username: "SEU_USER_MQTT"
     password: "SUA_SENHA_MQTT"

   sensor:
     - platform: mqtt
       name: "Temperatura BME280"
       state_topic: "sensor/bme280/temperature"
       unit_of_measurement: "°C"
     - platform: mqtt
       name: "Pressão BME280"
       state_topic: "sensor/bme280/pressure"
       unit_of_measurement: "hPa"
     - platform: mqtt
       name: "Umidade BME280"
       state_topic: "sensor/bme280/humidity"
       unit_of_measurement: "%"
   ```

#### 4. Verifique a Conexão no Home Assistant

5. **Reinicie o Home Assistant**:
   - Após salvar o arquivo `configuration.yaml`, reinicie o Home Assistant para aplicar as configurações.

6. **Monitoramento no iPhone**:
   - Acesse o Home Assistant no seu iPhone através do aplicativo ou do navegador usando o endereço do Home Assistant (IP do computador ou nome DNS configurado).

### Conclusão

Agora, o ESP32 com o sensor BME280 deve enviar os dados de temperatura, pressão e umidade para o broker MQTT da Tuya, que por sua vez estará integrado ao Home Assistant, tornando os dados disponíveis para monitoramento no seu iPhone. Certifique-se de que todas as credenciais estão corretas e que o Home Assistant pode se comunicar com o broker MQTT da Tuya.

---

### ASSISTENTE

Ótimo! Agora que você confirmou que o sensor BME280 está funcionando corretamente com o ESP32, vamos prosseguir para integrar o ESP32 com o Home Assistant e configurar para que ele permaneça sempre conectado à rede Wi-Fi, alimentado por uma fonte USB.

### Passo 1: Configurar o ESP32 para Enviar Dados ao Home Assistant Usando MQTT

Para que o ESP32 envie dados para o Home Assistant independentemente da IDE Arduino, utilizaremos o protocolo MQTT (Message Queuing Telemetry Transport). O MQTT é um protocolo de mensagens leve ideal para dispositivos IoT, que pode ser utilizado com um broker MQTT (como o Mosquitto, por exemplo) que é configurado no Home Assistant.

**Usar a Tuya IoT como Broker MQTT:**
Você mencionou que tem um projeto no Tuya IoT com credenciais e um projeto em nuvem, que pode servir como broker MQTT. Vamos usar isso para conectar o ESP32 e enviar dados ao Home Assistant.

#### Código para Conectar o ESP32 ao Broker MQTT da Tuya IoT

Aqui está o código atualizado que configura o ESP32 para se conectar à sua rede Wi-Fi e ao broker MQTT da Tuya IoT, enviando dados do sensor BME280:

```cpp
#include <WiFi.h>
#include <PubSubClient.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BME280.h>

// Credenciais da rede Wi-Fi
const char* ssid = "SEU_SSID";
const char* password = "SUA_SENHA";

// Configurações do broker MQTT da Tuya IoT
const char* mqtt_server = "BROKER_TUYA_IOT";  // Substitua pelo endereço do seu broker
const int mqtt_port = 1883;                   // Porta padrão MQTT
const char* mqtt_user = "SEU_USUARIO_MQTT";   // Usuário MQTT do Tuya IoT
const char* mqtt_password = "SUA_SENHA_MQTT"; // Senha MQTT do Tuya IoT

WiFiClient espClient;
PubSubClient client(espClient);
Adafruit_BME280 bme; // Instancia do sensor

void setup_wifi() {
    delay(10);
    Serial.println();
    Serial.print("Conectando-se a ");
    Serial.println(ssid);

    WiFi.begin(ssid, password);

    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }

    Serial.println("");
    Serial.println("WiFi conectado");
    Serial.println("Endereço IP: ");
    Serial.println(WiFi.localIP());
}

void reconnect() {
    while (!client.connected()) {
        Serial.print("Conectando ao MQTT...");
        if (client.connect("ESP32Client", mqtt_user, mqtt_password)) {
            Serial.println("conectado");
        } else {
            Serial.print("falhou, rc=");
            Serial.print(client.state());
            Serial.println(" tentando novamente em 5 segundos");
            delay(5000);
        }
    }
}

void setup() {
    Serial.begin(115200);
    setup_wifi();
    client.setServer(mqtt_server, mqtt_port);

    if (!bme.begin(0x76)) {  // Verifique o endereço I2C do sensor
        Serial.println("Não foi possível encontrar o sensor BME280");
        while (1);
    }
}

void loop() {
    if (!client.connected()) {
        reconnect();
    }
    client.loop();

    // Publica os dados do sensor para o tópico MQTT
    String temperatura = String(bme.readTemperature());
    String pressao = String(bme.readPressure() / 100.0F);
    String umidade = String(bme.readHumidity());

    client.publish("tuya/esp32/temperatura", temperatura.c_str());
    client.publish("tuya/esp32/pressao", pressao.c_str());
    client.publish("tuya/esp32/umidade", umidade.c_str());

    delay(2000); // Aguarda 2 segundos antes de enviar a próxima atualização
}
```

### Passo 2: Configuração do Home Assistant para Receber os Dados MQTT

No **Home Assistant**, adicione as configurações para o sensor MQTT em seu arquivo `configuration.yaml`:

```yaml
mqtt:
  broker: 'BROKER_TUYA_IOT'  # Endereço do broker MQTT da Tuya IoT
  port: 1883  # Porta padrão MQTT
  username: 'SEU_USUARIO_MQTT'
  password: 'SUA_SENHA_MQTT'

sensor:
  - platform: mqtt
    name: "Temperatura BME280"
    state_topic: "tuya/esp32/temperatura"
    unit_of_measurement: "°C"
  
  - platform: mqtt
    name: "Pressão BME280"
    state_topic: "tuya/esp32/pressao"
    unit_of_measurement: "hPa"

  - platform: mqtt
    name: "Umidade BME280"
    state_topic: "tuya/esp32/umidade"
    unit_of_measurement: "%"
```

### Passo 3: Reiniciar o Home Assistant

Após adicionar as configurações acima, reinicie o Home Assistant para aplicar as mudanças.

### Passo 4: Verificar Conectividade e Status dos Sensores

- No painel do Home Assistant, verifique se os sensores aparecem e se estão atualizando os valores conforme o esperado.
- Se necessário, ajuste as configurações de rede e credenciais para garantir que o ESP32 permaneça conectado ao broker MQTT da Tuya IoT.

### Considerações Finais

- Certifique-se de que o broker MQTT da Tuya IoT está configurado corretamente e acessível a partir da rede onde o ESP32 está conectado.
- Teste e ajuste os tópicos MQTT e as credenciais conforme necessário para garantir uma comunicação confiável entre o ESP32 e o Home Assistant.

Com essas etapas, seu ESP32 com o sensor BME280 deverá permanecer conectado à rede Wi-Fi e enviar dados continuamente para o Home Assistant usando o broker MQTT da Tuya IoT. Se precisar de mais ajuda, sinta-se à vontade para perguntar!

---

