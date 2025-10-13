# Verilog를 통한 FPGA 설계
## 목표
> Verilog를 사용하여 센서, 모터 or UART 통신 제어를 구현하고 FPGA 보드와 연동하여 보드를 제어합니다.

|항목|내용|
|----|----|
|사용 보드| AMD Artix™ 7 FPGA Trainer Board(Basys3)|
|언어| Verilog|
|환경| Vivado |
|센서| HC-SR04(초음파 거리 센서), DHT-11(온습도 센서)|
|통신| UART(속도: 9600bps)|

### 주요 기능1
#### - Four digit 7-segment display(FND)로 Watch/StopWatch 출력
<img width="153" height="60" alt="Image" src="https://github.com/user-attachments/assets/cc3101d8-3adc-4472-a115-1e1dc75d1167" /><br>
- 시계 모드와 스톱워치 모드를 독립적으로 구현, 스위치를 통해 출력하는 모드를 전환합니다.
    * 시계 모드
        - 시:분 출력 모드와 초:m초 출력 모드를 스위치를 통해 전환
        - 초기화시 12:00:00:00 부터 시작(시:분:초:밀리초)
        - 상/하/좌/우 버튼을 통해 각 시간을 변경
    * 스톱워치 모드
        - 시:분 출력 모드와 초:m초 출력 모드를 스위치를 통해 전환
        - 버튼을 통해 측정/정지/초기화 동작 구분

#### UART 통신을 통해 PC에서 Watch/StopWatch 모드 제어
 - UART 모듈을 구현하고 PC와 통신하면서 보드를 제어합니다.   

 - Watch 모드  
 U: 숫자 증가  
 D: 숫자 감소  
 R: 커서 우측 이동  
 L: 커서 좌측 이동   

 - StopWatch 모드  
 R: 측정 시작  
 S: 측정 중지  
 C: 초기화  

<img width="1106" height="475" alt="Image" src="https://github.com/user-attachments/assets/ac499941-1636-4747-9319-b93f9a2da8f9" /><br>

[결과 사진]
<br><img width="1198" height="663" alt="Image" src="https://github.com/user-attachments/assets/e685f2e6-2ae4-4dae-b706-58d7fb63f982" />

### 주요 기능2
#### HC-SR04 거리 측정 센서를 통한 거리 측정

[센서 timing diagram]  
<img width="543" height="229" alt="Image" src="https://github.com/user-attachments/assets/0458be53-423d-4662-b21c-9b99347633a3" /><br>
- 보드에서 센서로 10마이크로초의 Trigger 신호가 전달되면 센서 내부에서 40kHz의 초음파를 8 cycle동안 방출하게 됩니다.   
초음파 방출과 동시에 센서에서 Echo 신호를 High로 올리면서 보드로 전달됩니다.   
측정된 거리는 Echo신호의 High 구간 폭에 비례합니다.(uS / 58 = centimeters 또는 uS / 148 = inch)   

[결과 사진]   
![Image](https://github.com/user-attachments/assets/04d5032d-c3b1-4d63-9851-169941a7d3b7)<br>

### 주요 기능3
#### DHT-11 센서를 이용한 온습도 측정

[센서 timing diagram]   
<img width="1490" height="499" alt="Image" src="https://github.com/user-attachments/assets/3af808c4-df59-4a54-8266-4526975908fb" /><br>
- 데이터 단일 버스로 통신하며 유휴 상태는 High 입니다.   
보드에서 start 신호는 최소 18ms이상의 Low 상태를 센서로 보내게 됩니다. 이후 20-40uS동안 풀업한 상태로 센러의 응답을 기다립니다.   
이후 센서에서 80uS가량의 low신호를 보드로 보내어 보드에서 데이터를 받을 준비를 합니다. 그리고 다시 풀업 상태를 80uS동안 유지시킵니다.   
이후부터 들어오는 신호는 데이터로 인식하게 됩니다.

[데이터 0]
<br><img width="1020" height="626" alt="Image" src="https://github.com/user-attachments/assets/19cd1bf0-d756-439e-9bba-1486b216b59f" /><br>
- 데이터 전송에 앞서 low상태 50uS의 1bit 데이터 전송 start 신호를 보냅니다.   
이후 풀업상태를 26-28uS정도 유지합니다. 해당 신호는 데이터 0으로 인지합니다.   

[데이터 1]
<br><img width="1023" height="552" alt="Image" src="https://github.com/user-attachments/assets/ad7f0721-885b-4ff1-bfd1-61ca313805ee" /><br>
- 데이터 전송에 앞서 low상태 50uS의 1bit 데이터 전송 start 신호를 보냅니다.   
이후 풀업상태를 70uS정도 유지합니다. 해당 신호는 데이터 1로 인지합니다.

[결과 사진]   
![Image](https://github.com/user-attachments/assets/f625fc62-8e9d-4896-96f8-d4456ba7ed99)