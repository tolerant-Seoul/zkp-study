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

📚 학습 문서

	•	[1.1 ZKP Core Concepts](./1.1-zkp-core-concepts.md)
		- Completeness, Soundness, Zero-Knowledge 3대 속성
		- Schnorr Protocol, Sigma Protocol 구현
		- Fiat-Shamir Transform을 통한 NIZK 변환

	•	[1.2 Interactive vs Non-Interactive ZKP](./1.2-interactive-vs-non-interactive-zkp.md)
		- Interactive ZKP의 라운드 기반 프로토콜
		- Non-Interactive ZKP와 Random Oracle Model
		- CRS(Common Reference String) 기반 시스템

	•	[1.3 ZKP Use Cases and Applications](./1.3-zkp-use-cases-and-applications.md)
		- 블록체인 확장성 (ZK-Rollups)
		- 프라이버시 보호 (Mixer, Private Transactions)
		- 신원 증명 및 자격 검증 시스템

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

📚 학습 문서

	•	[2.1 Finite Fields, Polynomials & Pairings](./2.1-finite-fields-polynomials-pairings.md)
		- 유한체 연산 (덧셈, 곱셈, 역원)
		- 다항식 산술 및 Lagrange Interpolation
		- Elliptic Curve Pairings (BN254, BLS12-381)

	•	[2.2 R1CS (Rank-1 Constraint System)](./2.2-r1cs-rank-1-constraint-system.md)
		- 산술 회로에서 R1CS로 변환
		- Witness 생성 및 제약조건 검증
		- QAP(Quadratic Arithmetic Program) 변환

	•	[2.3 Prover Systems: Groth16, PLONK, FFLONK](./2.3-prover-systems-groth16-plonk-fflonk.md)
		- Groth16: Trusted Setup, 증명 구조
		- PLONK: Universal Setup, Custom Gates
		- FFLONK: 단일 다항식 커밋먼트 최적화

	•	[2.4 Recursive Proofs](./2.4-recursive-proofs.md)
		- Proof Composition과 Accumulation
		- IVC (Incrementally Verifiable Computation)
		- Nova, SuperNova 폴딩 기반 재귀

	•	[2.5 Lookup Schemes](./2.5-lookup-schemes.md)
		- Plookup, LogUp, cq 알고리즘
		- 룩업 테이블 최적화 기법
		- Range Proof 및 비트 분해 응용

	•	[2.6 Folding Schemes](./2.6-folding-schemes.md)
		- Nova: R1CS 폴딩
		- Sangria: PLONK 폴딩
		- ProtoStar: 일반화된 폴딩

	•	[2.7 Practical Selection Guide](./2.7-practical-selection-guide.md)
		- 프로젝트별 증명 시스템 선택 기준
		- 성능/보안/개발 용이성 트레이드오프
		- 의사결정 플로우차트

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

📚 학습 문서

	•	[3.1 Circom Circuit Development](./3.1-circom-circuit-development.md)
		- Circom 문법 및 템플릿 시스템
		- 신호(Signal), 제약조건, 컴포넌트 설계
		- circomlib 활용 (Poseidon, MiMC, Merkle Tree)
		- 회로 테스팅 및 디버깅 기법

	•	[3.2 Proof Generation & Verification Pipeline](./3.2-proof-generation-verification-pipeline.md)
		- Powers of Tau Ceremony (Trusted Setup)
		- snarkjs 워크플로우: compile → setup → prove → verify
		- Witness 생성 및 최적화
		- 증명 직렬화 및 배포

	•	[3.3 Smart Contract Integration](./3.3-smart-contract-integration.md)
		- Solidity Verifier 생성 및 배포
		- Groth16/PLONK Verifier 컨트랙트 구조
		- 가스 최적화 기법
		- 프론트엔드 통합 (ethers.js + snarkjs)

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

📚 학습 문서

	•	[4.1 ZK-Rollup Deep Dive](./4.1-zk-rollup-deep-dive.md)
		- zkSync Era, StarkNet, Polygon zkEVM, Scroll 아키텍처 분석
		- 각 롤업의 증명 시스템 비교 (Boojum, STARK, FFLONK, Halo2)
		- SDK 활용 및 크로스 롤업 브릿지 구현

	•	[4.2 ZK-Privacy Applications](./4.2-zk-privacy-applications.md)
		- Tornado Cash 프로토콜 분석 (Circom 회로, Solidity 컨트랙트)
		- Zcash Sapling/Orchard 회로 구현 (Rust/Bellman)
		- Aztec Protocol과 Noir 언어 실습
		- 프라이버시 투표 시스템 구현

	•	[4.3 Production ZK Libraries](./4.3-production-zk-libraries.md)
		- gnark (Go): 회로 정의, Merkle Tree, PLONK, Solidity 검증자 내보내기
		- bellman (Rust): Groth16 구현
		- arkworks (Rust): R1CS, Marlin
		- halo2 (Rust): Chip 패턴, Lookup Tables

	•	[4.4 Performance Optimization & Scalability](./4.4-performance-optimization-scalability.md)
		- 회로 최적화 기법 (제약조건 최소화, 병렬화)
		- GPU 가속 (CUDA MSM, NTT 구현)
		- 분산 증명 시스템 (Kubernetes 클러스터)
		- 메모리 최적화 및 배치 검증

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

📚 학습 문서

	•	[5.1 zkSNARKs vs zkSTARKs](./5.1-zksnarks-vs-zkstarks.md)
		- 수학적 기초 비교 (Pairing vs Hash 기반)
		- Groth16과 STARK 증명 구조 분석
		- 성능 벤치마크 및 보안 분석 (양자 내성)
		- 프로젝트별 선택 기준 의사결정 트리

	•	[5.2 Multi-Party Computation (MPC)](./5.2-multi-party-computation.md)
		- Shamir Secret Sharing 구현
		- Beaver Triples를 활용한 안전한 곱셈
		- Garbled Circuits (Yao's Protocol)
		- Oblivious Transfer 및 MP-SPDZ/JIFF 프레임워크
		- MPC + ZK 결합 패턴 (Threshold ECDSA, PSI)

	•	[5.3 Fully Homomorphic Encryption (FHE)](./5.3-fully-homomorphic-encryption.md)
		- BFV/BGV/CKKS/TFHE 스킴 비교 및 구현
		- Microsoft SEAL, OpenFHE, Concrete 라이브러리
		- 프라이버시 보존 ML 추론
		- FHE + ZK 하이브리드 시스템

	•	[5.4 Latest ZK Research Trends](./5.4-latest-zk-research-trends.md)
		- zkVM (RISC Zero, SP1, zkWASM, Cairo VM)
		- zkML (EZKL을 활용한 모델 검증)
		- 최신 증명 시스템 (Plonky3, Binius, Circle STARKs)
		- zkTLS, Programmable Cryptography
		- Based Rollups, zkEVM 진화
		- 하드웨어 가속 및 2024-2025 생태계 전망

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

