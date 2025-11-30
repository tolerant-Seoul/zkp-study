# Privacy Payroll 시스템 아키텍처

> EVM L1 기반 StableCoin을 활용한 프라이버시 급여 지급 시스템

## 목차

1. [요구사항 분석](#1-요구사항-분석)
2. [아키텍처 옵션 비교](#2-아키텍처-옵션-비교)
3. [권장 아키텍처: Aztec 기반 Privacy L2](#3-권장-아키텍처-aztec-기반-privacy-l2)
4. [급여 지급 흐름](#4-급여-지급-흐름)
5. [기술 스택 상세](#5-기술-스택-상세)
6. [성능 분석](#6-성능-분석)
7. [규제 및 보안 고려사항](#7-규제-및-보안-고려사항)
8. [개발 로드맵](#8-개발-로드맵)

---

## 1. 요구사항 분석

### 1.1 현재 상황

```
┌─────────────────────────────────────────────────────────────────┐
│  기존 인프라                                                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────┐                    │
│  │          기존 EVM L1 체인               │                    │
│  │  - Native Coin = StableCoin             │                    │
│  │  - 결제/급여에 사용 중                   │                    │
│  │  - 모든 거래가 공개됨 (문제!)            │                    │
│  └─────────────────────────────────────────┘                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 요구사항

| 번호 | 요구사항 | 상세 |
|------|---------|------|
| 1 | 프라이버시 | 급여 지급 시 수신자/금액 숨김 |
| 2 | 확장성 | TPS 확보로 결제 처리 속도 보장 |
| 3 | 호환성 | 기존 L1 인프라 유지 |
| 4 | 규제 준수 | 필요시 선택적 공개 가능 |

### 1.3 프라이버시 요구사항 상세

```
┌─────────────────────────────────────────────────────────────────┐
│  숨겨야 하는 정보                                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  현재 (L1 공개):                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Transfer Event:                                        │    │
│  │    From: 0xCompany... (회사 주소 - 공개)                │    │
│  │    To: 0xEmployee... (직원 주소 - 공개)                 │    │
│  │    Amount: 5,000,000원 (급여 금액 - 공개)               │    │
│  │                                                         │    │
│  │  → 누구나 급여 내역 조회 가능!                          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  목표 (Privacy L2):                                              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  On-chain Data:                                         │    │
│  │    Nullifier: 0x7f3a... (의미 불명)                     │    │
│  │    Commitment: 0x2b8c... (암호화됨)                     │    │
│  │    ZK Proof: Valid ✓                                    │    │
│  │                                                         │    │
│  │  → 누가, 누구에게, 얼마를 보냈는지 알 수 없음!          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. 아키텍처 옵션 비교

### 2.1 Option 1: Aztec 기반 Privacy L2 (권장)

```
┌─────────────────────────────────────────────────────────────────┐
│  Option 1: Aztec 기반 Privacy L2                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  구조:                                                           │
│    기존 L1 ←── Bridge ──→ Aztec Privacy L2                      │
│                                                                  │
│  장점:                                                           │
│  ✓ 완전한 프라이버시 (송신자/수신자/금액 숨김)                   │
│  ✓ 높은 TPS (100-500+)                                          │
│  ✓ ZK Rollup으로 L1 보안 상속                                   │
│  ✓ 프로그래머블 프라이버시 (스마트 컨트랙트 가능)               │
│  ✓ 오픈소스, 활발한 개발                                        │
│                                                                  │
│  단점:                                                           │
│  ✗ Ethereum Mainnet용으로 설계됨 → 커스텀 L1에 포팅 필요        │
│  ✗ 개발 복잡도 높음                                             │
│  ✗ 클라이언트 측 증명 생성 시간 (5-15초)                        │
│                                                                  │
│  기술 스택:                                                      │
│  - Aztec Protocol (포크 & 수정)                                 │
│  - Noir (프라이버시 컨트랙트 언어)                              │
│  - Barretenberg (ZK 증명 라이브러리)                            │
│  - L1에 Rollup/Bridge 컨트랙트 배포                             │
│                                                                  │
│  예상 개발 기간: 6-12개월                                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Option 2: Custom Privacy Rollup

```
┌─────────────────────────────────────────────────────────────────┐
│  Option 2: Custom Privacy Rollup                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  구조:                                                           │
│    기존 L1 ←── Rollup Contract ──→ Custom ZK L2                 │
│                                                                  │
│  장점:                                                           │
│  ✓ 요구사항에 맞게 최적화 가능                                  │
│  ✓ 불필요한 기능 제외 → 더 빠른 증명 생성                       │
│  ✓ 기존 L1에 최적화된 통합                                      │
│                                                                  │
│  단점:                                                           │
│  ✗ 처음부터 개발 → 더 긴 개발 기간                              │
│  ✗ 보안 감사 비용 높음                                          │
│  ✗ ZK 전문가 필요                                               │
│                                                                  │
│  기술 스택:                                                      │
│  - Circom + SnarkJS (회로 작성)                                 │
│  - Groth16 또는 PLONK (증명 시스템)                             │
│  - Solidity (L1 컨트랙트)                                       │
│  - Node.js/Rust (Sequencer)                                     │
│                                                                  │
│  예상 개발 기간: 12-18개월                                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.3 Option 3: zkEVM + Privacy Layer

```
┌─────────────────────────────────────────────────────────────────┐
│  Option 3: zkEVM + Privacy Layer                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  구조:                                                           │
│    기존 L1 → Polygon zkEVM → Privacy Contract (Mixer)           │
│                                                                  │
│  장점:                                                           │
│  ✓ 검증된 솔루션 조합                                           │
│  ✓ 상대적으로 빠른 구축                                         │
│  ✓ EVM 호환 유지                                                │
│                                                                  │
│  단점:                                                           │
│  ✗ 완전한 프라이버시가 아님 (메타데이터 노출 가능)              │
│  ✗ Mixer 패턴의 한계 (고정 금액, 패턴 분석 가능)                │
│  ✗ 여러 레이어 → 복잡한 UX                                      │
│                                                                  │
│  예상 개발 기간: 3-6개월                                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.4 옵션 비교표

| 항목 | Aztec L2 | Custom Rollup | zkEVM + Mixer |
|------|----------|---------------|---------------|
| **프라이버시 수준** | 완전 | 완전 | 부분적 |
| **TPS** | 100-500+ | 100-500+ | 50-200 |
| **개발 기간** | 6-12개월 | 12-18개월 | 3-6개월 |
| **개발 복잡도** | 높음 | 매우 높음 | 중간 |
| **유지보수** | 커뮤니티 지원 | 자체 | 부분 지원 |
| **권장 상황** | 장기 운영 | 특수 요구 | 빠른 PoC |

**권장: Option 1 (Aztec 기반 Privacy L2)**

---

## 3. 권장 아키텍처: Aztec 기반 Privacy L2

### 3.1 전체 시스템 구조

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          전체 시스템 아키텍처                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ╔═══════════════════════════════════════════════════════════════════════╗  │
│  ║                         기존 L1 (EVM Chain)                            ║  │
│  ╠═══════════════════════════════════════════════════════════════════════╣  │
│  ║                                                                        ║  │
│  ║  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐     ║  │
│  ║  │  Native Stable   │  │  Bridge Contract │  │  Rollup Contract │     ║  │
│  ║  │  Coin (기존)     │  │  (입출금 처리)   │  │  (상태 검증)     │     ║  │
│  ║  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘     ║  │
│  ║           │                     │                     │               ║  │
│  ╚═══════════╪═════════════════════╪═════════════════════╪═══════════════╝  │
│              │                     │                     │                   │
│              │ 1. Deposit          │ 2. Bridge           │ 3. Verify Proof  │
│              │    (Lock)           │    Events           │                   │
│              ▼                     ▼                     ▲                   │
│  ╔═══════════════════════════════════════════════════════╪═══════════════╗  │
│  ║                    Privacy L2 (Aztec-based)           │               ║  │
│  ╠═══════════════════════════════════════════════════════╧═══════════════╣  │
│  ║                                                                        ║  │
│  ║  ┌────────────────────────────────────────────────────────────────┐   ║  │
│  ║  │                        Sequencer                                │   ║  │
│  ║  │  - 트랜잭션 수집 및 정렬                                        │   ║  │
│  ║  │  - ZK Proof 검증                                                │   ║  │
│  ║  │  - 블록 생성                                                    │   ║  │
│  ║  │  - L1에 Rollup Proof 제출                                       │   ║  │
│  ║  └────────────────────────────────────────────────────────────────┘   ║  │
│  ║                                 │                                      ║  │
│  ║                                 ▼                                      ║  │
│  ║  ┌────────────────────────────────────────────────────────────────┐   ║  │
│  ║  │                     State Trees                                 │   ║  │
│  ║  │  ┌─────────────────┐  ┌─────────────────┐  ┌────────────────┐  │   ║  │
│  ║  │  │  Note Hash Tree │  │  Nullifier Tree │  │  Public State  │  │   ║  │
│  ║  │  │  (암호화 잔액)  │  │  (소비된 노트)  │  │  (공개 데이터) │  │   ║  │
│  ║  │  └─────────────────┘  └─────────────────┘  └────────────────┘  │   ║  │
│  ║  └────────────────────────────────────────────────────────────────┘   ║  │
│  ║                                                                        ║  │
│  ║  ┌────────────────────────────────────────────────────────────────┐   ║  │
│  ║  │                  Private StableCoin Contract                    │   ║  │
│  ║  │  - mint(): L1에서 입금 시 Private Note 생성                     │   ║  │
│  ║  │  - transfer(): 프라이빗 전송 (급여 지급)                        │   ║  │
│  ║  │  - batch_transfer(): 배치 급여 지급                             │   ║  │
│  ║  │  - withdraw(): L1으로 출금                                      │   ║  │
│  ║  │  - get_balance(): 잔액 조회 (본인만 가능)                       │   ║  │
│  ║  └────────────────────────────────────────────────────────────────┘   ║  │
│  ║                                                                        ║  │
│  ╚════════════════════════════════════════════════════════════════════════╝  │
│                                 ▲                                            │
│                                 │                                            │
│  ╔══════════════════════════════╧════════════════════════════════════════╗  │
│  ║                        Client Side (PXE)                               ║  │
│  ╠════════════════════════════════════════════════════════════════════════╣  │
│  ║                                                                        ║  │
│  ║  ┌────────────────┐  ┌────────────────┐  ┌────────────────────────┐   ║  │
│  ║  │  기업 Wallet   │  │  직원 Wallet   │  │  급여 관리 시스템      │   ║  │
│  ║  │  (급여 지급자) │  │  (급여 수령자) │  │  (Batch 처리 지원)    │   ║  │
│  ║  └────────────────┘  └────────────────┘  └────────────────────────┘   ║  │
│  ║                                                                        ║  │
│  ╚════════════════════════════════════════════════════════════════════════╝  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 컴포넌트 상세

#### L1 컨트랙트

| 컨트랙트 | 역할 | 핵심 기능 |
|---------|------|----------|
| Bridge Contract | L1↔L2 자산 이동 | deposit(), withdraw() |
| Rollup Contract | L2 상태 검증 | submitBlock(), verifyProof() |

#### Privacy L2

| 컴포넌트 | 역할 | 핵심 기능 |
|---------|------|----------|
| Sequencer | 블록 생성 | 트랜잭션 수집, 정렬, 블록 생성 |
| Note Hash Tree | 잔액 저장 | 암호화된 Note Commitment 저장 |
| Nullifier Tree | 이중지불 방지 | 소비된 Note 추적 |
| Private StableCoin | 프라이버시 토큰 | 민트, 전송, 출금 |

#### Client Side

| 컴포넌트 | 사용자 | 기능 |
|---------|-------|------|
| 기업 Wallet | 기업 (급여 지급자) | 배치 급여 지급, 잔액 관리 |
| 직원 Wallet | 직원 (급여 수령자) | 잔액 확인, 출금 |
| 급여 관리 시스템 | 기업 HR | 급여 데이터 연동, 자동화 |

---

## 4. 급여 지급 흐름

### 4.1 Phase 1: 기업 자금 예치

```
┌─────────────────────────────────────────────────────────────────┐
│  기업이 L2에 자금 예치                                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  기업                  L1 Bridge              Privacy L2         │
│    │                      │                      │               │
│    │ 1. deposit(1억원)   │                      │               │
│    │─────────────────────>│                      │               │
│    │                      │                      │               │
│    │                      │ 2. Lock 1억원        │               │
│    │                      │ 3. Emit DepositEvent│               │
│    │                      │─────────────────────>│               │
│    │                      │                      │               │
│    │                      │                      │ 4. mint       │
│    │                      │                      │  Private Note │
│    │                      │                      │  (1억원)      │
│    │                      │                      │               │
│    │<─────────────────────────────────────────────               │
│    │         5. 기업 PXE에 Note 동기화                           │
│    │                                                             │
│  결과: 기업의 Private 잔액 = 1억원 (암호화됨)                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Phase 2: 급여 지급

```
┌─────────────────────────────────────────────────────────────────┐
│  기업이 직원들에게 급여 지급                                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  기업 PXE                  Privacy L2              직원 PXE      │
│    │                          │                        │         │
│    │ 1. 급여 데이터 준비     │                        │         │
│    │    - 직원A: 500만원     │                        │         │
│    │    - 직원B: 600만원     │                        │         │
│    │    - 직원C: 450만원     │                        │         │
│    │                          │                        │         │
│    │ 2. 각 직원별 Note 생성  │                        │         │
│    │    (암호화됨)           │                        │         │
│    │                          │                        │         │
│    │ 3. ZK Proof 생성        │                        │         │
│    │    - 잔액 충분 증명     │                        │         │
│    │    - 금액 보존 증명     │                        │         │
│    │                          │                        │         │
│    │ 4. Batch Transfer TX    │                        │         │
│    │────────────────────────>│                        │         │
│    │  - nullifiers           │ 5. Verify Proof       │         │
│    │  - commitments          │ 6. Update Trees       │         │
│    │  - encrypted_notes      │                        │         │
│    │  - proof                │                        │         │
│    │                          │                        │         │
│    │                          │ 7. Broadcast Block    │         │
│    │                          │───────────────────────>│         │
│    │                          │                        │         │
│    │                          │              8. 각 직원 PXE가    │
│    │                          │                 자기 Note 복호화 │
│    │                          │                        │         │
│                                                                  │
│  온체인 기록:                                                    │
│    - Nullifier 1개 추가 (기업 Note 소비)                        │
│    - Commitment 4개 추가 (기업 거스름돈 + 직원 3명)             │
│    - 누가 누구에게 얼마 보냈는지? → 알 수 없음!                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.3 Phase 3: 직원 출금 (선택)

```
┌─────────────────────────────────────────────────────────────────┐
│  직원이 L1으로 출금                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  직원A PXE               Privacy L2               L1 Bridge      │
│    │                          │                      │           │
│    │ 1. withdraw(300만원)    │                      │           │
│    │────────────────────────>│                      │           │
│    │  - Note 소비 (500만)   │                      │           │
│    │  - 출금 요청 (300만)   │                      │           │
│    │  - 거스름돈 (200만)    │                      │           │
│    │                          │                      │           │
│    │                          │ 2. Include in       │           │
│    │                          │    Rollup Proof     │           │
│    │                          │─────────────────────>│           │
│    │                          │                      │           │
│    │                          │           3. Verify Rollup Proof │
│    │                          │           4. Release 300만원     │
│    │                          │              to 직원A            │
│    │                          │                      │           │
│    │<───────────────────────────────────────────────│           │
│    │           5. L1에서 300만원 수령                            │
│    │                                                             │
│  주의: 출금 시에는 L1에 기록되므로 금액이 공개됨                 │
│  → 프라이버시 유지하려면 L2 내에서만 사용 권장                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.4 트랜잭션 데이터 구조

```
┌─────────────────────────────────────────────────────────────────┐
│  급여 지급 트랜잭션 구조                                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  PayrollTransaction = {                                         │
│                                                                  │
│    // 공개 데이터 (관찰 가능)                                    │
│    public: {                                                    │
│      contract: "PrivateStableCoin",                            │
│      function: "batch_transfer",                               │
│      nullifiers: ["0xaaa..."],      // 의미 불명                │
│      commitments: [                  // 의미 불명                │
│        "0xbbb...",  // 직원A Note                              │
│        "0xccc...",  // 직원B Note                              │
│        "0xddd...",  // 직원C Note                              │
│        "0xeee..."   // 기업 거스름돈                            │
│      ],                                                        │
│      proof: "0x..."                  // ZK Proof (32KB)         │
│    },                                                          │
│                                                                  │
│    // 비공개 데이터 (기업만 알고 있음)                           │
│    private: {                                                   │
│      input_note: {                                             │
│        amount: 100000000,            // 1억원                   │
│        owner: "기업 주소"                                      │
│      },                                                        │
│      output_notes: [                                           │
│        { amount: 5000000, owner: "직원A" },   // 500만원       │
│        { amount: 6000000, owner: "직원B" },   // 600만원       │
│        { amount: 4500000, owner: "직원C" },   // 450만원       │
│        { amount: 84500000, owner: "기업" }    // 8450만원 거스름│
│      ]                                                         │
│    }                                                           │
│                                                                  │
│  }                                                               │
│                                                                  │
│  외부 관찰자 시점:                                               │
│  "누군가가 batch_transfer를 호출함"                             │
│  "1개 Note 소비, 4개 Note 생성"                                 │
│  "Proof 유효함"                                                 │
│  → 누가 얼마를 받았는지 전혀 알 수 없음!                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. 기술 스택 상세

### 5.1 L1 컨트랙트 (Solidity)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Bridge Contract - L1에 배포
contract PrivacyBridge {
    IERC20 public stableCoin;
    address public rollupContract;

    event Deposit(
        address indexed sender,
        uint256 amount,
        bytes32 l2Recipient
    );

    event Withdrawal(
        address indexed recipient,
        uint256 amount
    );

    // L2로 입금
    function deposit(uint256 amount, bytes32 l2Recipient) external {
        stableCoin.transferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount, l2Recipient);
    }

    // L2에서 출금 (Rollup Proof 검증 후)
    function withdraw(
        address recipient,
        uint256 amount,
        bytes calldata proof,
        bytes32 nullifier
    ) external {
        require(
            IRollup(rollupContract).verifyWithdrawal(proof, nullifier, amount),
            "Invalid proof"
        );
        stableCoin.transfer(recipient, amount);
        emit Withdrawal(recipient, amount);
    }
}

// Rollup Contract - L1에 배포
contract PrivacyRollup {
    bytes32 public noteHashTreeRoot;
    bytes32 public nullifierTreeRoot;
    uint256 public lastBlockNumber;

    IVerifier public verifier;

    event BlockSubmitted(
        uint256 indexed blockNumber,
        bytes32 noteHashRoot,
        bytes32 nullifierRoot
    );

    // L2 블록 제출
    function submitBlock(
        bytes32 newNoteHashRoot,
        bytes32 newNullifierRoot,
        bytes calldata proof,
        bytes calldata publicInputs
    ) external {
        require(
            verifier.verify(proof, publicInputs),
            "Invalid rollup proof"
        );

        noteHashTreeRoot = newNoteHashRoot;
        nullifierTreeRoot = newNullifierRoot;
        lastBlockNumber++;

        emit BlockSubmitted(lastBlockNumber, newNoteHashRoot, newNullifierRoot);
    }

    // 출금 검증
    function verifyWithdrawal(
        bytes calldata proof,
        bytes32 nullifier,
        uint256 amount
    ) external view returns (bool) {
        // 출금 증명 검증 로직
        return verifier.verifyWithdrawal(proof, nullifier, amount, nullifierTreeRoot);
    }
}
```

### 5.2 Privacy L2 컨트랙트 (Noir)

```rust
// Private StableCoin Contract
#[aztec]
contract PrivateStableCoin {
    use dep::aztec::prelude::*;
    use dep::easy_private_state::EasyPrivateUint;

    #[storage]
    struct Storage<Context> {
        balances: Map<AztecAddress, EasyPrivateUint<Context>, Context>,
        total_supply: PublicMutable<Field, Context>,
    }

    // L1에서 입금 시 호출 (Portal Contract 통해)
    #[private]
    fn mint_from_l1(amount: u64, recipient: AztecAddress) {
        // Portal Contract에서만 호출 가능하도록 검증
        let portal = context.get_portal_address();
        assert(context.msg_sender() == portal, "Only portal can mint");

        storage.balances.at(recipient).add(amount, recipient);
    }

    // 프라이빗 전송 (급여 지급)
    #[private]
    fn transfer(amount: u64, recipient: AztecAddress) {
        let sender = context.msg_sender();
        storage.balances.at(sender).sub(amount, sender);
        storage.balances.at(recipient).add(amount, recipient);
    }

    // 배치 전송 (여러 직원에게 한번에)
    #[private]
    fn batch_transfer(
        amounts: [u64; 10],
        recipients: [AztecAddress; 10],
        count: u8
    ) {
        let sender = context.msg_sender();
        let mut total: u64 = 0;

        // 각 수신자에게 Note 생성
        for i in 0..10 {
            if i < count as u32 {
                storage.balances.at(recipients[i]).add(amounts[i], recipients[i]);
                total += amounts[i];
            }
        }

        // 송신자 잔액 차감
        storage.balances.at(sender).sub(total, sender);
    }

    // L1으로 출금
    #[private]
    fn withdraw(amount: u64, l1_recipient: EthAddress) {
        let sender = context.msg_sender();
        storage.balances.at(sender).sub(amount, sender);

        // L1으로 메시지 전송
        context.message_to_l1(
            content: withdraw_content(amount, l1_recipient)
        );
    }

    // 잔액 조회 (본인만 가능)
    #[utility]
    unconstrained fn get_balance(owner: AztecAddress) -> Field {
        storage.balances.at(owner).get_value()
    }
}
```

### 5.3 기업 급여 시스템 (TypeScript)

```typescript
import { Contract, PXE, Wallet } from '@aztec/aztec.js';

interface PayrollEntry {
    employeeAddress: string;
    amount: bigint;
    employeeName: string;  // 내부 참조용
}

class PayrollSystem {
    private pxe: PXE;
    private wallet: Wallet;
    private contract: Contract;

    constructor(pxe: PXE, wallet: Wallet, contractAddress: string) {
        this.pxe = pxe;
        this.wallet = wallet;
    }

    // 급여 배치 지급
    async processPayroll(payments: PayrollEntry[]): Promise<string[]> {
        const txHashes: string[] = [];

        // 1. 잔액 확인
        const balance = await this.getBalance();
        const total = payments.reduce((sum, p) => sum + p.amount, 0n);

        if (balance < total) {
            throw new Error(`Insufficient balance: ${balance} < ${total}`);
        }

        console.log(`Processing payroll for ${payments.length} employees`);
        console.log(`Total amount: ${total}`);

        // 2. 배치 처리 (10명씩)
        const BATCH_SIZE = 10;

        for (let i = 0; i < payments.length; i += BATCH_SIZE) {
            const batch = payments.slice(i, i + BATCH_SIZE);

            // 배열 준비 (고정 크기)
            const amounts = new Array(10).fill(0n);
            const recipients = new Array(10).fill(this.wallet.getAddress());

            batch.forEach((payment, idx) => {
                amounts[idx] = payment.amount;
                recipients[idx] = payment.employeeAddress;
            });

            // 3. Private 트랜잭션 전송
            console.log(`Sending batch ${Math.floor(i/BATCH_SIZE) + 1}...`);

            const tx = await this.contract.methods
                .batch_transfer(amounts, recipients, batch.length)
                .send()
                .wait();

            txHashes.push(tx.txHash.toString());
            console.log(`Batch ${Math.floor(i/BATCH_SIZE) + 1} complete: ${tx.txHash}`);
        }

        console.log("Payroll complete!");
        return txHashes;
    }

    // 잔액 조회
    async getBalance(): Promise<bigint> {
        const balance = await this.contract.methods
            .get_balance(this.wallet.getAddress())
            .simulate();
        return BigInt(balance.toString());
    }

    // L1에서 입금
    async depositFromL1(amount: bigint): Promise<void> {
        // Bridge 컨트랙트 호출 로직
    }

    // L1으로 출금
    async withdrawToL1(amount: bigint, l1Address: string): Promise<void> {
        await this.contract.methods
            .withdraw(amount, l1Address)
            .send()
            .wait();
    }
}

// 사용 예시
async function runPayroll() {
    const payroll = new PayrollSystem(pxe, companyWallet, contractAddress);

    const employees: PayrollEntry[] = [
        { employeeName: "김철수", employeeAddress: "0x...", amount: 5000000n },
        { employeeName: "이영희", employeeAddress: "0x...", amount: 6000000n },
        { employeeName: "박민수", employeeAddress: "0x...", amount: 4500000n },
        // ... 더 많은 직원
    ];

    await payroll.processPayroll(employees);
}
```

---

## 6. 성능 분석

### 6.1 TPS 비교

```
┌─────────────────────────────────────────────────────────────────┐
│                        성능 비교                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────┬─────────────┬──────────────────────────┐   │
│  │ 메트릭          │ L1 직접     │ Privacy L2               │   │
│  ├─────────────────┼─────────────┼──────────────────────────┤   │
│  │ TPS             │ 15-50       │ 100-500+                 │   │
│  │ 블록 시간       │ 2-15초      │ 1-2초                    │   │
│  │ 트랜잭션 비용   │ $0.5-5      │ $0.01-0.10               │   │
│  │ Finality        │ 블록 확정시 │ L2즉시 + L1 주기적       │   │
│  │ 프라이버시      │ 없음        │ 완전한 프라이버시        │   │
│  └─────────────────┴─────────────┴──────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 급여 지급 시나리오 성능

```
┌─────────────────────────────────────────────────────────────────┐
│  시나리오: 직원 1,000명 급여 지급                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  조건:                                                           │
│  - 직원 수: 1,000명                                             │
│  - 배치 크기: 10명/트랜잭션                                     │
│  - 필요 트랜잭션: 100개                                         │
│                                                                  │
│  L1 직접 처리:                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  소요 시간: 100 × 12초 = 20분                            │    │
│  │  비용: 100 × $1 = $100                                   │    │
│  │  프라이버시: 모든 급여 내역 공개!                        │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  Privacy L2:                                                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  소요 시간: 100 × 2초 = ~3분                             │    │
│  │  비용: 100 × $0.05 = $5                                  │    │
│  │  프라이버시: 모든 급여 내역 숨김!                        │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  개선 효과:                                                      │
│  - 시간: 7배 빠름                                               │
│  - 비용: 20배 저렴                                              │
│  - 프라이버시: 무한대 개선 (0 → 100%)                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 6.3 증명 생성 시간

```
┌─────────────────────────────────────────────────────────────────┐
│  클라이언트 측 증명 생성 시간                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  작업                        예상 시간       비고               │
│  ─────────────────────────────────────────────────────────────  │
│  단일 전송                   5-10초          개인 전송          │
│  배치 전송 (10명)            10-15초         급여 지급          │
│  입금 (L1→L2)                3-5초           초기 설정          │
│  출금 (L2→L1)                5-10초          현금화             │
│                                                                  │
│  최적화 방안:                                                    │
│  - GPU 가속 (2-3배 개선)                                        │
│  - 서버 사이드 증명 (기업용)                                    │
│  - 증명 병렬 처리                                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. 규제 및 보안 고려사항

### 7.1 선택적 공개 (View Key)

```
┌─────────────────────────────────────────────────────────────────┐
│  View Key를 통한 선택적 공개                                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  목적: 완전한 익명성으로 인한 규제 이슈 해결                     │
│                                                                  │
│  메커니즘:                                                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                         │    │
│  │  사용자 키 구조:                                        │    │
│  │    - Spending Key: 자산 전송 권한                       │    │
│  │    - View Key: 거래 내역 열람 권한 (읽기 전용)          │    │
│  │                                                         │    │
│  │  View Key 공유 시나리오:                                │    │
│  │    - 세무 감사: 기업이 View Key 제공                    │    │
│  │    - 소득 증명: 직원이 본인 View Key 제공               │    │
│  │    - 법적 조사: 법원 명령 시 View Key 제출              │    │
│  │                                                         │    │
│  │  특징:                                                  │    │
│  │    - View Key로는 자산 이동 불가                        │    │
│  │    - 해당 계정의 거래만 열람 가능                       │    │
│  │    - 다른 참여자의 프라이버시 유지                      │    │
│  │                                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 7.2 기업 키 관리

```
┌─────────────────────────────────────────────────────────────────┐
│  기업용 키 관리 전략                                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  보안 수준별 옵션:                                               │
│                                                                  │
│  Level 1: 기본                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  - 소프트웨어 지갑                                      │    │
│  │  - 시드 문구 백업                                       │    │
│  │  - 암호화된 키 저장                                     │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  Level 2: 권장                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  - HSM (Hardware Security Module)                       │    │
│  │  - Multi-sig (2-of-3)                                   │    │
│  │  - 권한 분리 (재무/IT)                                  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  Level 3: 고보안                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  - 에어갭 서명 장치                                     │    │
│  │  - Multi-sig (3-of-5)                                   │    │
│  │  - 지리적 분산                                          │    │
│  │  - 타임락 (대량 출금 시)                                │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 7.3 직원 키 복구

```
┌─────────────────────────────────────────────────────────────────┐
│  직원 키 복구 옵션                                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Option 1: 자체 관리                                            │
│  - 시드 문구 본인 보관                                          │
│  - 책임도 본인에게                                              │
│                                                                  │
│  Option 2: 사회적 복구                                          │
│  - 신뢰할 수 있는 연락처 3-5명 지정                             │
│  - 3-of-5 복구 가능                                             │
│                                                                  │
│  Option 3: 기업 지원 복구 (옵트인)                              │
│  - 기업이 복구 키 조각 보관                                     │
│  - 직원 요청 시 복구 지원                                       │
│  - 기업은 자산 접근 불가 (복구 키만으로 불충분)                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. 개발 로드맵

### 8.1 Phase 1: PoC (2-3개월)

```
┌─────────────────────────────────────────────────────────────────┐
│  Phase 1: Proof of Concept                                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  목표: 기술 검증 및 타당성 확인                                  │
│                                                                  │
│  Tasks:                                                          │
│  □ Aztec Sandbox 환경 구축                                      │
│  □ Private StableCoin 컨트랙트 개발                             │
│  □ 단일 전송 테스트                                             │
│  □ 배치 전송 테스트                                             │
│  □ 성능 벤치마크                                                │
│  □ 기존 L1과의 브릿지 설계 문서화                               │
│                                                                  │
│  산출물:                                                         │
│  - 동작하는 PoC                                                 │
│  - 성능 측정 결과                                               │
│  - 기술 문서                                                    │
│                                                                  │
│  팀 구성:                                                        │
│  - 블록체인 개발자 2명                                          │
│  - ZK 전문가 1명 (컨설팅)                                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 Phase 2: L1 통합 (2-3개월)

```
┌─────────────────────────────────────────────────────────────────┐
│  Phase 2: L1 통합                                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  목표: 기존 L1과의 완전한 통합                                   │
│                                                                  │
│  Tasks:                                                          │
│  □ Bridge Contract 개발                                         │
│  □ Rollup Contract 개발                                         │
│  □ L1 ↔ L2 입출금 테스트                                       │
│  □ Sequencer 개발 및 배포                                       │
│  □ 통합 테스트                                                  │
│                                                                  │
│  산출물:                                                         │
│  - L1에 배포된 Bridge/Rollup 컨트랙트                          │
│  - 운영 가능한 Sequencer                                        │
│  - 통합 테스트 결과                                             │
│                                                                  │
│  팀 구성:                                                        │
│  - 블록체인 개발자 3명                                          │
│  - 인프라 엔지니어 1명                                          │
│  - QA 1명                                                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 8.3 Phase 3: 기능 완성 (2-3개월)

```
┌─────────────────────────────────────────────────────────────────┐
│  Phase 3: 기능 완성                                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  목표: 실제 사용 가능한 제품                                     │
│                                                                  │
│  Tasks:                                                          │
│  □ 배치 전송 최적화                                             │
│  □ 기업용 관리 대시보드 개발                                    │
│  □ 직원용 모바일/웹 앱 개발                                     │
│  □ HR 시스템 연동 API                                           │
│  □ View Key 기반 감사 기능                                      │
│  □ 키 복구 메커니즘                                             │
│                                                                  │
│  산출물:                                                         │
│  - 기업용 대시보드                                              │
│  - 직원용 앱                                                    │
│  - API 문서                                                     │
│  - 운영 매뉴얼                                                  │
│                                                                  │
│  팀 구성:                                                        │
│  - 블록체인 개발자 2명                                          │
│  - 프론트엔드 개발자 2명                                        │
│  - 백엔드 개발자 1명                                            │
│  - UX 디자이너 1명                                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 8.4 Phase 4: 보안 및 런칭 (2-3개월)

```
┌─────────────────────────────────────────────────────────────────┐
│  Phase 4: 보안 및 런칭                                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  목표: 프로덕션 배포                                             │
│                                                                  │
│  Tasks:                                                          │
│  □ 외부 보안 감사                                               │
│  □ 버그 바운티 프로그램                                         │
│  □ 스테이징 환경 테스트                                         │
│  □ 모니터링/알림 시스템                                         │
│  □ 문서화 완성                                                  │
│  □ 메인넷 런칭                                                  │
│  □ 사용자 교육                                                  │
│                                                                  │
│  산출물:                                                         │
│  - 보안 감사 리포트                                             │
│  - 운영 대시보드                                                │
│  - 사용자 가이드                                                │
│  - 프로덕션 시스템                                              │
│                                                                  │
│  팀 구성:                                                        │
│  - 기존 팀 유지                                                 │
│  - 보안 감사 업체                                               │
│  - DevOps 1명                                                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 8.5 전체 일정

```
┌─────────────────────────────────────────────────────────────────┐
│                         전체 로드맵                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Month:  1   2   3   4   5   6   7   8   9  10  11  12          │
│         ─────────────────────────────────────────────────        │
│                                                                  │
│  Phase 1: PoC                                                   │
│         [███████████]                                           │
│                                                                  │
│  Phase 2: L1 통합                                               │
│                     [███████████]                               │
│                                                                  │
│  Phase 3: 기능 완성                                             │
│                                 [███████████]                   │
│                                                                  │
│  Phase 4: 보안/런칭                                             │
│                                             [███████████]       │
│                                                                  │
│  마일스톤:                                                       │
│  ◆ Month 3: PoC 완료                                            │
│  ◆ Month 6: L1 통합 완료                                        │
│  ◆ Month 9: 베타 버전                                           │
│  ◆ Month 12: 메인넷 런칭                                        │
│                                                                  │
│  총 예상 기간: 10-12개월                                         │
│  총 예상 팀: 6-8명 (피크 시)                                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 9. 결론

### 9.1 기술적 타당성

| 요구사항 | 해결책 | 가능 여부 |
|---------|--------|----------|
| 급여 금액/수신자 숨김 | ZK 기반 Privacy L2 | ✓ 가능 |
| TPS 확보 (100+) | L2 Rollup | ✓ 가능 |
| 기존 L1 인프라 유지 | Bridge + Rollup | ✓ 가능 |
| 규제 준수 | View Key 메커니즘 | ✓ 가능 |

### 9.2 권장 접근법

1. **Aztec Protocol 기반** Privacy L2 구축
2. 기존 L1에 **Bridge/Rollup 컨트랙트** 배포
3. **8-12개월** 개발 기간 예상
4. **6-8명** 팀 필요 (ZK 전문가 포함)

### 9.3 다음 단계

1. PoC 시작: Aztec Sandbox에서 급여 지급 시나리오 테스트
2. 기존 L1과의 통합 설계 상세화
3. 개발팀 구성 및 예산 확보
4. 보안 감사 업체 선정

---

## 부록: 참고 자료

- [Aztec Protocol Documentation](https://docs.aztec.network/)
- [Noir Language Guide](https://noir-lang.org/)
- [ZK Rollup 개요](https://ethereum.org/en/developers/docs/scaling/zk-rollups/)
- [UTXO vs Account Model](https://www.horizen.io/academy/utxo-vs-account-model/)
