# ALREADY11 Security Dashboard — 접속 가이드

## 접속 URL

| 서비스 | 주소 |
|--------|------|
| **대시보드 (UI)** | https://downloaded-beneath-pushed-provides.trycloudflare.com |
| API (내부용) | https://audio-have-spokesman-pens.trycloudflare.com/api/v1 |

---

## 로그인 계정

| 구분 | 이메일 | 비밀번호 |
|------|--------|----------|
| 관리자 | dev@prowler.com | Prowler1234! |

---

## 주요 화면

| 메뉴 | 설명 |
|------|------|
| **개요** | 파이프라인 최신 현황 + 위협 점수 + 점검 결과 |
| **컴플라이언스** | CIS / ISMS-P 규정 준수 현황 |
| **취약점 결과** | 스캔 FAIL 항목 목록 |
| **스캔 시작** | AWS 스캔 → GitHub Actions 파이프라인 자동 실행 |

---

## 파이프라인 흐름

```
스캔 시작 (UI 버튼)
  └→ GitHub Actions: Security Pipeline - 01 Scan Baseline
       └→ Prowler CLI로 AWS 스캔 (ap-northeast-2)
            └→ 결과 Prowler DB 저장
            └→ 파이프라인 요약 API로 전송
                 └→ 개요 대시보드 자동 업데이트
  └→ GitHub Actions: Security Pipeline - 02 Generate Remediation PRs
       └→ 자동 수정 PR 생성
  └→ (PR Merge 후) Security Pipeline - 04 Verify FAIL Reduction
       └→ 재스캔으로 개선 효과 확인
```

---

## 주의사항 (trycloudflare 무료 터널)

- **PC를 재시작하거나 cloudflared 프로세스가 종료되면 URL이 바뀝니다**
- URL이 바뀌면 아래 두 곳을 갱신해야 합니다:
  1. `.env` → `DJANGO_ALLOWED_HOSTS`
  2. GitHub Secret → `PROWLER_APP_API_URL`
- 고정 URL이 필요하다면 Cloudflare 계정 등록 후 Named Tunnel 사용 권장

---

## 로컬 재시작 방법 (URL 갱신 시)

```powershell
# 1. API 터널 재시작
cloudflared tunnel --url http://localhost:8080 --logfile cloudflared-api.log --no-autoupdate &

# 2. UI 터널 재시작
cloudflared tunnel --url http://localhost:3000 --logfile cloudflared-ui.log --no-autoupdate &

# 3. 로그에서 새 URL 확인
Get-Content cloudflared-api.log | Select-String "trycloudflare"
Get-Content cloudflared-ui.log  | Select-String "trycloudflare"

# 4. .env DJANGO_ALLOWED_HOSTS 새 API URL로 수정
# 5. GitHub Secret PROWLER_APP_API_URL 새 API URL로 수정
# 6. API 컨테이너 재시작
docker compose -f docker-compose-dev.yml up -d api-dev worker-dev worker-beat
```
