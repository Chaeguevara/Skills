---
name: design-feedback-checkpoint
description: When the user proposes a UI/UX/design change AND asks for input ("어때?", "어떻게 생각해?", "너의 생각을 먼저"), state your opinion first — including concerns, trade-offs, and 1-2 alternatives — and wait for confirmation before implementing. Triggers when a visual/UX change request is paired with any signal of asking for opinion.
disable-model-invocation: false
---

# 디자인 피드백 체크포인트

UI/UX 결정은 user-facing 이라 trade-off 가 비-자명함. 사용자가 첫 제안 그대로 즉시 구현하면, 의도와 안 맞을 때 작업 폐기됨.

## 트리거

다음 중 하나라도 매칭되면 즉시 구현 금지, 의견 먼저:

- 명시적 input 요청: **"어때?"**, **"어떻게 생각해?"**, **"너의 생각을 먼저 생각해보고 얘기해줘"**, **"의견 줘봐"**
- 망설임 표현 + 디자인 변경: **"...하면 될 거 같다는 얘기"**, **"이렇게 해야 될 거 같음"**, **"~~하는 편이 나을듯"**
- 미적 불만: **"별로네"**, **"이상하네"**, **"거슬려"**, **"안 보여"** + 어떻게 고칠지 사용자가 옵션을 던질 때

## 행동 패턴

1. **사용자가 본 것 인정** (1줄): "폴리라인 noise 큰 것 동의."
2. **방향 직답** (1줄): 동의/부분동의/우려.
3. **trade-off 명시** (1-3 bullet): 사용자 제안 그대로 했을 때 어떤 비용 / 어떤 가치.
4. **대안 1-2개** 제시 (필요한 경우): "A: ... / B: ..."
5. **확인 요청**: "이 방향 OK? / 색상 톤 muted vs vivid 중 선호?" — 진행 신호 받고 시작

## 하지 말 것

- 사용자가 "어때?" 라고 명시했는데 "OK 진행" 하고 바로 코드
- 변종 N개를 한꺼번에 만들어 "골라봐" 식 (시간 낭비)
- 의견 냈는데 사용자 동의 후 다시 한 번 confirm 질문 (이미 동의했음)
- 너무 길게 (의견은 200단어 이내, bullet 위주)

## 사용자 동의 신호

명시적: "그렇게 해", "굿", "OK", "진행"
암시적: 구체 후속 디테일 제시 ("색상은 muted 톤으로"), 다른 작업 전환

## 예시 (실제 케이스)

User: "폴리라인 별로네. 우측에 레전드 띄우고 색상으로 작가 구분 + mini relation graph 어때?"

올바른 응답: "폴리라인 제거 동의. 단 architect 20명 색깔은 인지 한계 (색 차별 ~6-7개) 라 lineage 6색 권고. 우측 패널 + mini graph 좋음. trade-off: 무채색 컨셉 일부 양보 / 모바일은 우측 패널 못 띄움. → muted vs vivid? OK 면 lineage 색 + 데스크탑 280px 우측 + 모바일은 토글로 진행."

잘못된 응답: 즉시 폴리라인 제거 + architect 20색 적용 + 우측 패널 작성 시작 (사용자 의도 일부 어긋날 수 있음, 작업 폐기 위험).
