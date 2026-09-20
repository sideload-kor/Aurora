[![GitHub Release](https://img.shields.io/github/v/release/sideload-kor/Aurora?include_prereleases)](https://github.com/sideload-kor/Aurora/releases)
[![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/sideload-kor/Aurora/total)](https://github.com/sideload-kor/Aurora/releases)
<a href="https://github.com/sponsors/khcrysalis"><img src="https://img.shields.io/badge/Sponsor_Feather_Project-black?style=for-the-badge" alt="Sponsor Feather Project"></a>
<br>
<br>
<br>
<img alt="Aurora" src="https://github.com/sideload-kor/Aurora/blob/3beca2b7b406ec167c0f2323752d7dfa3fa789a2/icon.png" width="120" />
<br>

# Aurora

## 주요 기능 (Features)

- 직관적이고 깔끔한 사용자 인터페이스(UI) 제공
- 앱 서명(Sign) 및 직접 설치 지원
- [AltStore](https://faq.altstore.io/distribute-your-apps/make-a-source#apps) 소스(리포지토리) 호환
- 앱 및 사용자 인증서의 상세 정보 확인 가능
- 앱 모양 변경, 파일 앱 접근 허용 등 커스텀 서명 옵션 지원
  - 호환성 패치 및 Liquid Glass 패치 기능 포함
- [Ellekit](https://github.com/tealbathingsuit/ellekit) 기반의 주입 기능을 통한 고급 트윅(Tweak) 지원
  - `.deb` 및 `.dylib` 파일 주입 지원
- 지속적인 유지보수: 최신 앱들이 정상적으로 설치될 수 있도록 상시 관리
- 추적 및 애널리틱스가 없어 사용자의 개인정보를 안전하게 보호
- 완전 무료 및 오픈소스

## 다운로드 (Download)

[Releases](https://github.com/sideload-kor/Aurora/releases) 페이지에서 최신 버전의 `.ipa` 파일을 다운로드하세요.

<a href="https://github.com/sideload-kor/Aurora/releases/latest" target="_blank">
  <img src="https://github.com/CelloSerenity/altdirect/blob/main/assets/png/Download_Blue.png?raw=true" alt="Download .ipa" width="160">
</a>

## 기여 및 감사 (Acknowledgements)

- [SideLoad-Kor](https://github.com/sideload-kor) - 프로젝트 주관
- [Samara](https://github.com/declaration) - 개발자
- [idevice](https://github.com/jkcoxson/idevice) - `installd` 통신 및 빌드 백엔드 활용
- [*.backloop.dev](https://backloop.dev/) - 퍼블릭 CA 서명 SSL 인증서를 적용한 로컬호스트 환경
- [Vapor](https://github.com/vapor/vapor) - 서버 사이드 Swift HTTP 웹 프레임워크
- [Zsign](https://github.com/zhlynn/zsign) - iOS 등 다른 플랫폼에서도 동작하도록 재구현된 기기 내 서명 엔진
- [LiveContainer](https://github.com/LiveContainer/LiveContainer) - 버그 수정 및 도움
- [Nuke](https://github.com/kean/Nuke) - 이미지 캐싱 라이브러리
- [Asspp](https://github.com/Lakr233/Asspp) - HTTP 서버 설정 관련 코드 참조
- [plistserver](https://github.com/nekohaxx/plistserver) - https://api.palera.in 에 호스팅된 서버 코드

## 라이선스 (License)

본 프로젝트는 **GPL-3.0 라이선스** 하에 배포됩니다. 전체 라이선스 전문은 [LICENSE](https://github.com/sideload-kor/Aurora/blob/main/LICENSE) 파일에서 확인하실 수 있습니다. 

인증서 기반 사이드로딩 분야에서 사용자에게 투명하게 공개된 오픈소스 프로젝트가 부족했기에, 누구나 자유롭게 이용할 수 있도록 오픈소스로 공개하게 되었습니다.

본 프로젝트에 기여하는 모든 코드 또한 GPL-3.0 라이선스가 적용되며, 개발된 모든 작업물은 앞으로도 자유롭게 접근하고 사용할 수 있도록 유지됩니다.
