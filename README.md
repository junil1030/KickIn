# KickIn

부동산 매물 탐색 및 거래를 위한 iOS 애플리케이션

## 개요

KickIn은 SwiftUI 기반의 iOS 애플리케이션으로, 사용자가 부동산 매물을 탐색하고, 관심 매물을 관리하며, 판매자와 실시간 채팅을 할 수 있는 플랫폼입니다.

## 스크린샷

| | | | |
|:-:|:-:|:-:|:-:|
| 로그인 | 홈 | 관심 매물 | 매물 상세 |
| <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-02 at 08 44 38" src="https://github.com/user-attachments/assets/86482de5-3614-413b-9fe3-4cb3e2eb8f53" /> | <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-02 at 08 47 06" src="https://github.com/user-attachments/assets/46d2c584-f0b6-4e62-992b-c6c9397ff5d8" /> | <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-02 at 08 47 17" src="https://github.com/user-attachments/assets/047042b4-b142-4698-a818-16bc5280085a" /> | <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-02 at 08 49 46" src="https://github.com/user-attachments/assets/cc709e38-4ea0-405b-bdee-281a55627fa0" />
| 지도 - 단일 마커 | 지도 - 그리드 클러스터링 | 지도 - DBSCAN 클러스터링 | 지도 - 필터 |
| <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-02 at 08 50 58" src="https://github.com/user-attachments/assets/26cb121b-b441-446f-b137-ae5fa78e1e04" /> | <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-02 at 08 48 01" src="https://github.com/user-attachments/assets/e43c672f-3d0c-47d4-b803-9ee649661833" /> | <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-02 at 08 58 59" src="https://github.com/user-attachments/assets/cfd6f0b0-5bc9-4a20-ab26-b406d6b023db" /> | <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-02 at 09 00 34" src="https://github.com/user-attachments/assets/5d102c1b-947c-46cf-b328-01bc0624a1e0" />
| 채팅 목록 | 1:1 채팅 - 링크 프리뷰 | 1:1 채팅 - 사진 | 채팅 - 톡서랍 |
| <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-02 at 08 48 35" src="https://github.com/user-attachments/assets/8758a694-7720-4d54-87c1-e7dd93f57498" /> | <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-02 at 08 48 42" src="https://github.com/user-attachments/assets/8f5d5aca-7b9f-4cf6-8d5e-2cf77cfa26e8" /> | <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-02 at 19 52 22" src="https://github.com/user-attachments/assets/1174e553-1b0b-49b2-b751-b3e599cf30cb" /> | <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-02 at 08 50 30" src="https://github.com/user-attachments/assets/71ed0267-9953-408b-837f-b6a8844b1fff" />
| 배너 | 웹뷰 출석체크 | 스트리밍 1 | 스트리밍 2 |
| <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-01-30 at 09 53 54" src="https://github.com/user-attachments/assets/dc1447e0-d956-42fb-9944-37df92c064f4" /> | <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-01-30 at 09 54 03" src="https://github.com/user-attachments/assets/c39c5fe7-fae9-466b-abbe-df244c1332fc" /> | <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-01-30 at 09 51 17" src="https://github.com/user-attachments/assets/81196f71-b01a-43d5-a705-f3703ed0f1fa" /> | <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-01-30 at 09 51 43" src="https://github.com/user-attachments/assets/abcca522-f941-4929-8859-58f974c9eb9f" />
| 게시판 목록 | 게시판 상세 | 상대방 프로필 | 내 프로필 |
| <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-02 at 08 50 04" src="https://github.com/user-attachments/assets/6b0cddbd-123b-472d-8200-0ddf61bade36" /> | <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-02 at 08 50 19" src="https://github.com/user-attachments/assets/727ad262-efe3-4f34-bbaa-6aff6cbf2b79" /> | <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-02 at 09 08 39" src="https://github.com/user-attachments/assets/cd8102b1-37a8-4ced-beea-fcaabef7d01a" /> | <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-02 at 08 50 35" src="https://github.com/user-attachments/assets/ca790b83-f404-4b19-9a6a-815ee9e12408" />
<table>
  <tr>
    <th align="center" colspan="2">아이패드 CTA</th>
    <th align="center" colspan="2">아이패드 CTA2</th>
  </tr>
  <tr>
    <td align="center" colspan="2">
      <img src="https://github.com/user-attachments/assets/4ac3c622-5cca-4e92-9f1c-b20b25ed1516" width="100%" />
    </td>
    <td align="center" colspan="2">
      <img src="https://github.com/user-attachments/assets/5d84f6a1-b2a8-430c-a448-6235aa46bd49" width="100%" />
    </td>
  </tr>
</table>

## 주요 기능

- **매물 탐색**: 지도 기반 부동산 매물 검색 및 탐색
- **관심 목록**: 관심 있는 매물 저장 및 관리
- **실시간 채팅**: 판매자와 1:1 채팅 및 미디어 공유
- **톡서랍**: 채팅 방 내에 미디어 파일 모아보기
- **게시판**: 매물에 대한 글 작성(이미지, 비디오, PDF 업로드)
- **비디오 플레이어**: 매물 영상 시청
- **PDF 뷰어**: 부동산 관련 문서 확인
- **결제**: 앱 내 결제 기능
- **로그인**: email, Apple, Kakao 로그인
- **프로필 관리**: 사용자 프로필 및 설정

## 개발 환경

### 필수 요구사항
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

## 기술 스택

### 아키텍처
- **UI Framework**: SwiftUI
- **Architecture**: MVVM
- **네트워크**: Protocol-driven Router Pattern
- **데이터베이스**: RealmSwift (로컬 영구 저장)

### 주요 라이브러리
- **Alamofire**: HTTP 네트워킹
- **RealmSwift**: 채팅 메시지 로컬 저장 및 실시간 동기화
- **KakaoSDK**: 카카오 로그인
- **AVFoundation**: HLS 비디오 스트리밍 및 커스텀 플레이어
- **MapKit**: 지도 기반 UI
- **CachingKit**: 이미지 및 데이터 캐싱

### 의존성 관리
- Swift Package Manager (SPM)

## 주요 기술 구현

### 1. 지도 클러스터링
고성능 매물 마커 클러스터링을 위한 알고리즘 구현

- **Grid 클러스터링**: 빠른 그리드 기반 클러스터링 제공
- **DBSCAN 알고리즘**: 밀도 기반 공간 클러스터링
  - QuadTree 자료구조 활용으로 O(n log n) 시간 복잡도 달성
  - 백그라운드 스레드에서 비동기 처리로 UI 블로킹 방지
- **Strategy Pattern**: 클러스터링 전략을 동적으로 교체 가능한 설계
- **마커 캐싱**: `MarkerImageCache`로 클러스터 마커 이미지 재사용 최적화

**구현 위치**: `Features/Map/Services/ClusteringService.swift:14`

### 2. 실시간 채팅 시스템
Realm 기반 로컬-서버 동기화 채팅 시스템

- **Realm 로컬 데이터베이스**
  - `ChatMessageObject`, `ChatRoomObject`, `UserObject` 관계형 스키마
  - Repository 패턴으로 데이터 접근 추상화
- **실시간 동기화**
  - `ChatLifecycleManager`: 앱 라이프사이클에 따른 동기화 관리
  - `MessageSyncCoordinator`: 서버-로컬 간 메시지 동기화 조율
  - 백그라운드 진입 시 동기화 중단, 포어그라운드 복귀 시 재개
- **미디어 서랍 (톡서랍)**
  - 채팅방 내 공유된 이미지/비디오/PDF 필터링 및 그리드 뷰
  - 날짜별 섹션 헤더로 미디어 그룹화
  - 썸네일 캐싱으로 성능 최적화
- **링크 프리뷰**
  - URL 자동 감지 및 메타데이터 추출
  - Open Graph 프로토콜 지원
  - 비동기 로딩 및 캐싱

**구현 위치**:
- Realm 모델: `Core/Database/Models/Chat/ChatMessageObject.swift:11`
- 동기화: `Core/Services/Chat/ChatLifecycleManager.swift`

### 3. HLS 비디오 스트리밍
AVFoundation 기반 적응형 비트레이트 스트리밍

- **HLS 프로토콜 처리**
  - `HLSPlaylistProcessor`: 마스터 플레이리스트 전처리
  - 자막 트랙 제거 및 URL 정규화로 재생 안정성 향상
  - Data URL 변환으로 동적 플레이리스트 제공
- **커스텀 비디오 플레이어**
  - 제스처 기반 컨트롤 (탭: 재생/일시정지, 스와이프: 탐색)
  - 배속 조절 (0.5x ~ 2.0x)
  - 화질 선택 (다중 비트레이트 지원)
  - 자막 표시 (VTT/SRT 파싱)
- **비디오 압축 및 업로드**
  - `VideoCompressor`: H.264 코덱 기반 압축
  - 진행률 추적 및 에러 핸들링
  - 백그라운드 업로드 지원

**구현 위치**:
- HLS 처리: `Features/Video/Services/HLSPlaylistProcessor.swift:11`
- 압축: `Core/Services/Video/VideoCompressor.swift`

### 4. 네트워크 아키텍처
확장 가능한 프로토콜 주도 설계

- **RouterProtocol**: 모든 API 엔드포인트의 공통 인터페이스
  - `HTTPMethod`, `path`, `parameters`, `headers` 표준화
  - 각 기능별 독립적인 Router 구현 (예: `ChatRouter`, `VideoRouter`)
- **DTO 레이어**: Request/Response 명확한 분리
- **에러 핸들링**: 타입 세이프한 에러 처리
- **Interceptor**: 인증 토큰 자동 갱신

**구현 위치**: `Core/Network/RouterProtocol.swift:11`

## 프로젝트 구조

```
KickIn/
├── App/                      # 앱 진입점 및 라이프사이클
│   ├── KickInApp.swift
│   ├── AppDelegate.swift
│   └── ContentView.swift
├── Core/                     # 핵심 비즈니스 로직
│   ├── Network/             # Protocol 기반 네트워크 레이어
│   │   └── {Feature}/
│   │       ├── Routers/
│   │       ├── RequestDTO/
│   │       └── ResponseDTO/
│   ├── Database/            # 로컬 데이터 저장
│   ├── Services/            # 공통 서비스
│   ├── UI/                  # 재사용 가능한 UI 컴포넌트
│   └── Utils/               # 유틸리티 함수
├── Features/                # 기능별 모듈
│   ├── Home/               # 홈 화면
│   ├── Map/                # 지도 기반 매물 탐색
│   ├── Chat/               # 실시간 채팅
│   ├── EstateDetail/       # 매물 상세 정보
│   ├── EstatePost/         # 매물 등록
│   ├── Interest/           # 관심 목록
│   ├── Video/              # 비디오 플레이어
│   ├── PDF/                # PDF 뷰어
│   ├── Payments/           # 결제
│   ├── Login/              # 로그인
│   ├── SignUp/             # 회원가입
│   ├── Profile/            # 프로필
│   └── UserProfile/        # 사용자 프로필
├── Shared/                  # 공유 리소스
├── Resources/               # 에셋 및 폰트
│   ├── Assets.xcassets/
│   └── Fonts/
└── Configs/                 # 설정 파일
    └── Secrets.xcconfig
```

## 개발자

Created by 서준일 (Seojun-il)
