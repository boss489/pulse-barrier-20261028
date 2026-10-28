# 박동 장벽 — 아트 방향과 출처

## 시각 언어
밤의 신호실을 떠올리는 잉크 남색 배경과 청록 격자, 호박색 예고, 산호색 위험, 민트색 안전의 3박 색채. 색만으로 구분하지 않고 **01 예고 / 02 위험 / 03 안전** 숫자와 한글 표기, 관문의 선·점선·발광 상태를 함께 표시한다. 주인공은 박동 링, 보석은 마름모, 출구는 겹원으로 구별한다. 배경의 희미한 동심원·산발적인 신호 점, 상단 얇은 경계선, 반투명 판넬과 고정폭 격자 리듬은 `main.gd`에서 직접 그린다. 외부 이미지나 AI 생성 이미지 없음.

## 소리
`generate_audio.py`가 표준 라이브러리만으로 네 효과음(step, pulse, fail, win)을 22.05 kHz 모노 PCM으로 직접 합성한다. 시작·위상·실패·성공이 음고와 길이로 구별된다. M 키로 음소거 가능. 원본 저작물이며 별도의 외부 음원 없음.

## 글꼴
`assets/NanumGothic-Regular.ttf` — Google Fonts의 **Nanum Gothic**, SIL Open Font License 1.1. 원문은 `assets/OFL-NanumGothic.txt`에 동봉. 원본 출처: https://github.com/google/fonts/tree/main/ofl/nanumgothic . 게임 UI의 한국어는 폰트를 직접 preload하여 Web 패키지에도 포함된다.

## 실행 / 빌드
Godot 4.7.2에서 `godot --path .` 실행. `godot --headless --path . --editor --quit`으로 가져오기 후 `godot --headless --path . --export-release Web web/index.html`. HTTP 서버로 `web/index.html`을 제공해야 브라우저가 WASM/패키지를 불러온다(`python3 -m http.server 9877 --directory web`). `file://` 직접 열기는 지원하지 않는다. Web export는 단일 스레드, GL Compatibility로 설정했다.

## 플레이
방향키/WASD·화면 패드로 이동, 마우스/터치로 격자 자동 이동. 붉게 켜진 장벽에 닿으면 실패하며 아무 곳이나 누르거나 Enter로 재시작. 호박색 예고 또는 청록색 안전 시 한 칸 폭의 관문을 통과한다. 선택 보석은 정지 충전 한 번과 캠페인 누적 기록을 준다. Space/멈춤으로 60프레임 동안 움직임과 시계를 동결한다. 출구로 이동하면 다음 방이 열린다. R은 현재 방 재시작, 타이틀에서 처음부터 튜토리얼 시작 가능. `user://pulse_barrier.cfg`에 최고 도달 방·보석 수가 저장된다.

## 검증 한계
규칙 자동 테스트는 방의 정적 경로·위상·충돌과 한 장면의 실패/진행을 확인한다. 각 방의 실제 체감 난도, 저사양 모바일 성능, 전체 21방 수동 클리어는 별도 플레이테스트가 필요하다.
