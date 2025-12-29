아래는 Zero-Knowledge (ZK) 기술을 학습하고 이해하기 위한 체계적인 커리큘럼입니다. 가능한 한 GitHub 상의 오픈 소스 자료와 강의/실습 중심으로 구성했으며, 초보 → 중급 → 고급 단계로 나누었습니다. 또한 각 단계별 핵심 목표와 추천 리포지토리도 함께 제공합니다.

⸻

📘 Zero-Knowledge Proof (ZKP) 학습 커리큘럼

⸻

❗ 학습 목표
	1.	ZKP의 핵심 개념 이해
	2.	다양한 zk 증명 방식 (SNARK / STARK / R1CS) 개념 학습
	3.	실제 회로 설계 → 증명 생성 → 검증 실습 경험
	4.	블록체인/스마트 컨트랙트 적용 사례 학습
	5.	오픈소스 구현 소스 분석 능력 배양

⸻

⸻

🧠 1단계 — 기초 개념 이해 (Zero-Knowledge Proof Fundamentals)

🎯 목표
	•	ZKP의 핵심 개념 (Completeness, Soundness, Zero-Knowledge)을 이해
	•	Interactive vs Non-Interactive ZKP 차이 학습
	•	일반적인 적용 사례와 배경 샘플 익히기

📌 자료 & 리포지토리
	•	Awesome ZKP 리소스 전체 목록
👉 matter-labs/awesome-zero-knowledge-proofs — 개념, 라이브러리, 튜토리얼 링크 모음
https://github.com/matter-labs/awesome-zero-knowledge-proofs
	•	Zero-Knowledge Proof Learning Resources
👉 shanzson/Zero-Knowledge-Proofs-Learning-Resources — 입문부터 실습까지 링크 정리
https://github.com/shanzson/Zero-Knowledge-Proofs-Learning-Resources
	•	Zero-Knowledge Fundamentals Course (고수준 설명)
👉 Cyfrin/zero-knowledge-fundamentals-cu — ZKP 개념을 비수학적으로 설명
https://github.com/Cyfrin/zero-knowledge-fundamentals-cu

⸻

🧠 2단계 — 수학/암호화 기초

🎯 목표
	•	대수학/유한체(Fields), 다항식, Pairings 개념 학습
	•	R1CS (Rank-1 Constraint System) 기본 이해
	•	Groth16 / PLONK / FFLONK 등의 프로버 구조 이해

📌 추천 학습

실습 리포지토리에서 바로 실험하면서 아래 구조를 익힐 수 있습니다.
	•	snarkjs (JavaScript ZK Framework)
👉 iden3/snarkjs — JS 기반 zkSNARK 도구 모음
https://github.com/iden3/snarkjs
	•	Tarassh/zkSNARK-under-the-hood (교육용)
👉 Groth16 / Plonk 구현 예제 (Jupyter Notebook)
https://github.com/tarassh/zkSNARK-under-the-hood
	•	Hands-on Circom + snarkjs 튜토리얼
(공식 튜토리얼 커뮤니티/문서도 참고)

⸻

⚙️ 3단계 — 실전 회로 설계 및 증명 생성

🎯 목표
	•	실제 zk 회로 작성
	•	증명 생성 및 검증 파이프라인 구성
	•	스마트 컨트랙트와 증명 통합

📌 실습 자료

🧪 입문 실습
	•	zksnarks_example — zkSNARKs 기초 예제 코딩
https://github.com/jstoxrocky/zksnarks_example
	•	libsnark 튜토리얼 — C++ 기반 zkSNARK 프레임워크 실습
https://github.com/howardwu/libsnark-tutorial
https://github.com/coder5876/libsnark-tutorial

🧾 스마트 컨트랙트 통합
	•	Circom / snarkjs 기반 Solidity 증명 검증 실습 (커뮤니티 예제 및 해커눈 글 참고)

⸻

🧠 4단계 — 프로덕션 수준 ZK 시스템 적용

🎯 목표
	•	ZK-Rollup / ZK-Privacy / ZK-ML 같은 실제 프로젝트 살펴보기
	•	고성능 및 확장성 고려

📌 오픈소스 프로젝트 분석

아래는 실전 프로젝트 소스/라이브러리 예시입니다.
	•	zkSNARK 라이브러리 & 구현체 모음
👉 다양한 프로젝트 살펴보기 (gnark, bellman, jsnark 등)
	•	zk Workshops — 실습 중심 워크숍 자료 (EcoDev)
https://github.com/ethereum/zket-workshops
	•	Awesome Zero Knowledge (커리큘럼 링크 포함)
👉 odradev/awesome-zero-knowledge — 실전 예제를 포함한 커리큘럼형 정리
https://github.com/odradev/awesome-zero-knowledge

⸻

📚 5단계 — 심화 연구 & 최신 트렌드

🎯 목표
	•	zkSNARKs vs zkSTARKs 비교
	•	MPC / FHE 등 프로그래머블 크립토 확장 학습

📌 논문 & 심화 자료
	•	zkSNARKs vs zkSTARKs 실행 성능 비교 논문 (arXiv)
	•	ZK 관련 최신 survey, 다양한 ZKP 프레임워크 정리 논문

⸻

🗺️ 추천 학습 플로우 (타임라인)

Step 1: 0 ~ 1주 — 기초 개념/용어 정리
Step 2: 2 ~ 3주 — 수학/회로 이해 & 도구설정
Step 3: 4 ~ 6주 — 실습 중심 회로 설계 및 스냅샷 구현
Step 4: 2 ~ 4주 — 프로젝트 수준 zk 적용
Step 5: 계속 — 최신 리서치/응용 사례 학습


⸻

📌 추가 팁

🔹 Circuit DSL: Circom 같은 DSL 익히면 회로 설계가 빨라집니다.
🔹 Rust/ZK 라이브러리: arkworks, halo2, bellman 같은 Rust 기반 리포지토리는 실제 퍼포먼스 사례 분석에 좋습니다.
🔹 실전 프로젝트 분석: GitHub top projects 리스트를 통해 적용 사례 직접 분석하세요.

⸻

필요하면 단계별로 실습 예제 코드 + 환경 세팅 가이드까지 차근차근 제공해 드릴 수 있습니다.

