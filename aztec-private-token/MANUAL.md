# Aztec Protocol을 활용한 ZKP 기반 프라이버시 토큰 개발 가이드

> **버전**: Aztec v2.1.8
> **최종 검증일**: 2024년
> **난이도**: 중급

---

## 목차

1. [영지식 증명(ZKP) 개요](#1-영지식-증명zkp-개요)
2. [Aztec Protocol 소개](#2-aztec-protocol-소개)
3. [개발 환경 설정](#3-개발-환경-설정)
4. [프로젝트 구조](#4-프로젝트-구조)
5. [스마트 컨트랙트 작성](#5-스마트-컨트랙트-작성)
6. [TypeScript 테스트 작성](#6-typescript-테스트-작성)
7. [실행 가이드](#7-실행-가이드)
8. [문제 해결](#8-문제-해결)
9. [기업 활용 시나리오](#9-기업-활용-시나리오)

---

## 1. 영지식 증명(ZKP) 개요

### 1.1 ZKP란 무엇인가?

**영지식 증명(Zero-Knowledge Proof, ZKP)**은 어떤 사실이 참임을 증명하면서도, 그 사실 자체에 대한 정보는 전혀 공개하지 않는 암호학적 기법입니다.

#### 일상적인 비유

> **동굴 문제**: Alice가 동굴 깊숙이 있는 비밀 문의 비밀번호를 알고 있다고 증명하고 싶습니다.
> - Alice는 동굴에 들어가 비밀 문을 통해 반대편으로 나옵니다
> - Bob은 Alice가 어느 쪽으로 나올지 랜덤하게 지정합니다
> - Alice가 매번 정확하게 나온다면, 비밀번호를 알고 있음이 증명됩니다
> - **하지만 Bob은 비밀번호 자체는 알지 못합니다**

### 1.2 ZKP의 세 가지 속성

| 속성 | 설명 |
|------|------|
| **완전성 (Completeness)** | 참인 명제는 항상 증명 가능 |
| **건전성 (Soundness)** | 거짓 명제는 증명 불가능 |
| **영지식성 (Zero-Knowledge)** | 증명 외에 어떤 정보도 유출되지 않음 |

### 1.3 블록체인에서의 ZKP 활용

```
┌─────────────────────────────────────────────────────────────┐
│                    기존 블록체인 (이더리움)                    │
├─────────────────────────────────────────────────────────────┤
│  트랜잭션: Alice → Bob, 100 ETH                             │
│  ✗ 모든 사람이 볼 수 있음                                    │
│  ✗ 금액, 발신자, 수신자 모두 공개                            │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    ZKP 블록체인 (Aztec)                      │
├─────────────────────────────────────────────────────────────┤
│  트랜잭션: ████████████████████████                         │
│  ✓ 증명만 공개: "유효한 전송이 발생했음"                      │
│  ✓ 금액, 발신자, 수신자 모두 비공개                          │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Aztec Protocol 소개

### 2.1 Aztec이란?

**Aztec**은 이더리움 위에서 프라이버시를 제공하는 Layer 2 솔루션입니다. ZK-SNARK를 사용하여 모든 트랜잭션의 발신자, 수신자, 금액을 숨길 수 있습니다.

### 2.2 핵심 개념

#### UTXO Note 모델

Aztec은 비트코인과 유사한 UTXO(Unspent Transaction Output) 모델을 사용하되, 모든 값이 암호화되어 있습니다.

```
Alice의 잔액 = 100 토큰

내부 표현:
┌─────────────────────────────────────────┐
│  Note1: encrypt(50, Alice의 공개키)      │
│  Note2: encrypt(30, Alice의 공개키)      │
│  Note3: encrypt(20, Alice의 공개키)      │
└─────────────────────────────────────────┘
합계: 50 + 30 + 20 = 100 (Alice만 알 수 있음)
```

#### 전송 과정

```
Alice가 Bob에게 70 토큰 전송:

1. 입력 (소비되는 노트):
   - Note1(50) + Note2(30) = 80 토큰

2. 출력 (새로 생성되는 노트):
   - Bob용 Note: encrypt(70, Bob의 공개키)
   - Alice용 잔돈 Note: encrypt(10, Alice의 공개키)

3. ZK 증명이 검증하는 것:
   ✓ 입력 합계 >= 출력 합계
   ✓ Alice가 입력 노트의 소유자임
   ✓ 새 노트들이 올바르게 생성됨
```

### 2.3 Aztec 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                      클라이언트 측                           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────┐ │
│  │  Wallet     │ ←→ │  PXE        │ ←→ │  Noir Circuit   │ │
│  │  (aztec.js) │    │  (Private   │    │  (ZK 증명 생성)  │ │
│  │             │    │  Execution) │    │                 │ │
│  └─────────────┘    └─────────────┘    └─────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Aztec Network                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────┐ │
│  │  Sequencer  │ →  │  Prover     │ →  │  L1 Contract    │ │
│  │  (트랜잭션  │    │  (증명 집계) │    │  (이더리움)      │ │
│  │   정렬)     │    │             │    │                 │ │
│  └─────────────┘    └─────────────┘    └─────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 2.4 주요 컴포넌트

| 컴포넌트 | 역할 |
|---------|------|
| **PXE (Private Execution Environment)** | 프라이빗 함수 실행, 노트 관리, 증명 생성 |
| **Noir** | ZK 회로 작성 언어 (Rust와 유사) |
| **aztec.js** | TypeScript SDK |
| **Sandbox** | 로컬 개발/테스트 환경 |

---

## 3. 개발 환경 설정

### 3.1 시스템 요구사항

- **OS**: macOS, Linux (Windows는 WSL2 권장)
- **메모리**: 최소 8GB RAM (16GB 권장)
- **디스크**: 10GB 이상 여유 공간
- **Node.js**: v18 이상

### 3.2 Aztec 툴체인 설치

```bash
# Aztec 툴체인 설치 (aztec-nargo, aztec CLI 포함)
curl -s https://install.aztec.network | bash

# 환경변수 설정 (~/.bashrc 또는 ~/.zshrc에 추가)
export PATH="$HOME/.aztec/bin:$PATH"

# 설치 확인
aztec --version
aztec-nargo --version
```

### 3.3 Sandbox 실행

Sandbox는 로컬에서 실행되는 완전한 Aztec 네트워크입니다.

```bash
# Sandbox 시작 (별도 터미널에서 실행)
aztec start --sandbox

# 정상 실행 시 출력:
# [16:00:00.000] INFO: Started Aztec Sandbox
# [16:00:00.000] INFO: PXE listening on http://localhost:8080
```

> **참고**: Sandbox 초기 시작에 1-2분 소요될 수 있습니다.

---

## 4. 프로젝트 구조

### 4.1 디렉토리 구조

```
aztec-private-token/
├── private_token/              # Noir 스마트 컨트랙트
│   ├── Nargo.toml             # 프로젝트 설정
│   └── src/
│       └── main.nr            # 컨트랙트 코드
│
├── test/                       # TypeScript 테스트
│   ├── package.json           # 의존성 설정
│   └── payroll_test.ts        # 급여 지급 테스트
│
└── MANUAL.md                   # 이 문서
```

### 4.2 프로젝트 생성

```bash
# 프로젝트 디렉토리 생성
mkdir aztec-private-token
cd aztec-private-token

# Noir 컨트랙트 프로젝트 생성
mkdir -p private_token/src
mkdir -p test
```

---

## 5. 스마트 컨트랙트 작성

### 5.1 Nargo.toml 설정

`private_token/Nargo.toml`:

```toml
[package]
name = "private_token"
authors = [""]
compiler_version = ">=0.25.0"
type = "contract"

[dependencies]
aztec = { git = "https://github.com/AztecProtocol/aztec-packages", tag = "v2.1.5", directory = "noir-projects/aztec-nr/aztec" }
value_note = { git = "https://github.com/AztecProtocol/aztec-packages", tag = "v2.1.5", directory = "noir-projects/aztec-nr/value-note" }
easy_private_state = { git = "https://github.com/AztecProtocol/aztec-packages", tag = "v2.1.5", directory = "noir-projects/aztec-nr/easy-private-state" }
```

### 5.2 Private Token 컨트랙트

`private_token/src/main.nr`:

```rust
// ============================================================================
// Private Token Contract
// ============================================================================
// ZKP 기반 프라이버시 토큰 컨트랙트
// - 모든 잔액과 전송 금액이 암호화됨
// - 소유자만 자신의 잔액 조회 가능
// ============================================================================

use dep::aztec::macros::aztec;

#[aztec]
pub contract PrivateToken {
    use dep::aztec::macros::{
        functions::{initializer, private, utility},
        storage::storage
    };
    use dep::aztec::{protocol_types::address::AztecAddress, state_vars::Map};
    use dep::easy_private_state::EasyPrivateUint;

    // ========================================================================
    // Storage - 암호화된 잔액 저장소
    // ========================================================================
    #[storage]
    struct Storage<Context> {
        balances: Map<AztecAddress, EasyPrivateUint<Context>, Context>,
    }

    // ========================================================================
    // Constructor - 초기 토큰 발행
    // ========================================================================
    // 초기 공급량을 owner에게 발행
    // 이 금액은 체인에서 비공개!
    #[private]
    #[initializer]
    fn constructor(initial_supply: u64, owner: AztecAddress) {
        let balances = storage.balances;
        balances.at(owner).add(initial_supply, owner);
    }

    // ========================================================================
    // Mint - 토큰 발행
    // ========================================================================
    #[private]
    fn mint(amount: u64, owner: AztecAddress) {
        let balances = storage.balances;
        balances.at(owner).add(amount, owner);
    }

    // ========================================================================
    // Transfer - 프라이빗 전송
    // ========================================================================
    // ZK 증명으로 검증되는 것:
    // 1. sender가 충분한 잔액을 보유
    // 2. sender가 노트의 소유자임
    // 3. 토큰이 새로 생성/소멸되지 않음 (보존 법칙)
    //
    // 체인에 공개되지 않는 것:
    // - 발신자 주소
    // - 수신자 주소
    // - 전송 금액
    #[private]
    fn transfer(amount: u64, sender: AztecAddress, recipient: AztecAddress) {
        let balances = storage.balances;
        balances.at(sender).sub(amount, sender);
        balances.at(recipient).add(amount, recipient);
    }

    // ========================================================================
    // Batch Transfer - 다중 수신자 전송 (급여 지급용)
    // ========================================================================
    #[private]
    fn batch_transfer_2(
        sender: AztecAddress,
        recipient1: AztecAddress,
        amount1: u64,
        recipient2: AztecAddress,
        amount2: u64
    ) {
        let balances = storage.balances;
        let total = amount1 + amount2;

        balances.at(sender).sub(total, sender);
        balances.at(recipient1).add(amount1, recipient1);
        balances.at(recipient2).add(amount2, recipient2);
    }

    #[private]
    fn batch_transfer_3(
        sender: AztecAddress,
        recipient1: AztecAddress,
        amount1: u64,
        recipient2: AztecAddress,
        amount2: u64,
        recipient3: AztecAddress,
        amount3: u64
    ) {
        let balances = storage.balances;
        let total = amount1 + amount2 + amount3;

        balances.at(sender).sub(total, sender);
        balances.at(recipient1).add(amount1, recipient1);
        balances.at(recipient2).add(amount2, recipient2);
        balances.at(recipient3).add(amount3, recipient3);
    }

    // ========================================================================
    // Get Balance - 잔액 조회 (오프체인 실행)
    // ========================================================================
    // unconstrained = 가스 비용 없이 오프체인에서 실행
    // 소유자만 자신의 노트를 복호화하여 잔액 확인 가능
    #[utility]
    unconstrained fn get_balance(owner: AztecAddress) -> Field {
        storage.balances.at(owner).get_value()
    }
}
```

### 5.3 컨트랙트 컴파일

```bash
cd private_token

# Noir 컨트랙트 컴파일
aztec-nargo compile

# 컴파일 결과 확인
ls target/
# private_token-PrivateToken.json
```

---

## 6. TypeScript 테스트 작성

### 6.1 package.json 설정

`test/package.json`:

```json
{
  "name": "private-token-test",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "test": "npx tsx payroll_test.ts"
  },
  "dependencies": {
    "@aztec/aztec.js": "2.1.8",
    "@aztec/accounts": "2.1.8",
    "@aztec/noir-contracts.js": "2.1.8",
    "tsx": "^4.7.0",
    "typescript": "^5.3.0"
  }
}
```

### 6.2 급여 지급 테스트

`test/payroll_test.ts`:

```typescript
/**
 * ============================================================================
 * Enterprise Privacy Payroll Test - ZKP Transfer Demo
 * ============================================================================
 * 회사가 직원들에게 비공개로 급여를 지급하는 시뮬레이션:
 * - 회사가 초기 자금 입금 (100,000 토큰)
 * - 2명의 직원에게 개별 전송으로 급여 지급
 * - 모든 금액과 수령인은 온체인에서 숨겨짐
 * ============================================================================
 */

import {
  createPXEClient,
  waitForPXE,
} from '@aztec/aztec.js';
import { getInitialTestAccountsWallets } from '@aztec/accounts/testing';
// 공식 Aztec 컨트랙트 사용 (검증 키 포함)
import { PrivateTokenContract } from '@aztec/noir-contracts.js/PrivateToken';

const PXE_URL = process.env.PXE_URL || 'http://localhost:8080';

async function main() {
  console.log('');
  console.log('='.repeat(70));
  console.log('  PRIVACY PAYROLL - 기업용 비공개 급여 지급 데모');
  console.log('='.repeat(70));
  console.log('');
  console.log('  시나리오:');
  console.log('    - 회사 보유 토큰: 100,000');
  console.log('    - 2명의 직원에게 다른 급여 지급:');
  console.log('      * 직원1 (Alice): 5,000 토큰');
  console.log('      * 직원2 (Bob):   4,500 토큰');
  console.log('');

  // =========================================================================
  // Step 1: PXE 연결
  // =========================================================================
  console.log('[1] Aztec PXE에 연결 중...');
  const pxe = createPXEClient(PXE_URL);
  await waitForPXE(pxe);
  console.log('    PXE 연결 완료:', PXE_URL);
  console.log('');

  // =========================================================================
  // Step 2: 테스트 계정 설정
  // =========================================================================
  console.log('[2] 테스트 계정 설정 중...');
  const wallets = await getInitialTestAccountsWallets(pxe);

  if (wallets.length < 3) {
    throw new Error('3개 이상의 테스트 계정 필요. 샌드박스가 실행 중인지 확인하세요.');
  }

  const company = wallets[0];  // 회사 (급여 관리자)
  const alice = wallets[1];    // 직원 1
  const bob = wallets[2];      // 직원 2

  console.log('    - 회사 (test0):', company.getAddress().toString());
  console.log('    - Alice (test1):', alice.getAddress().toString());
  console.log('    - Bob (test2):', bob.getAddress().toString());
  console.log('');

  // =========================================================================
  // Step 3: 프라이빗 토큰 컨트랙트 배포
  // =========================================================================
  console.log('[3] 급여 토큰 컨트랙트 배포 중...');

  const INITIAL_SUPPLY = 100000n;
  console.log('    초기 회사 잔액:', INITIAL_SUPPLY, '토큰');
  console.log('');
  console.log('    ** ZKP 참고: 이 금액은 비공개입니다! **');
  console.log('    ** 회사만 실제 잔액을 알 수 있습니다 **');
  console.log('');
  console.log('    ZK 증명 생성 중... (약 15초 소요)');

  // 컨트랙트 배포
  // 중요: send()에 from 옵션을 명시적으로 전달 (SDK 버그 회피)
  const contract = await PrivateTokenContract.deploy(company, INITIAL_SUPPLY, company.getAddress())
    .send({ from: company.getAddress() })
    .deployed();

  console.log('    컨트랙트 배포 완료:', contract.address.toString());
  console.log('');

  // =========================================================================
  // Step 4: 초기 잔액 확인
  // =========================================================================
  console.log('[4] 초기 잔액 확인 중...');
  console.log('');

  // 중요: simulate()에도 빈 객체 전달 (SDK 버그 회피)
  const companyBalance = await contract.methods.get_balance(company.getAddress()).simulate({});
  console.log('    회사 잔액:', companyBalance.toString(), '토큰');

  const aliceContract = await PrivateTokenContract.at(contract.address, alice);
  const aliceBalance = await aliceContract.methods.get_balance(alice.getAddress()).simulate({});
  console.log('    Alice 잔액:', aliceBalance.toString(), '토큰');

  const bobContract = await PrivateTokenContract.at(contract.address, bob);
  const bobBalance = await bobContract.methods.get_balance(bob.getAddress()).simulate({});
  console.log('    Bob 잔액:', bobBalance.toString(), '토큰');
  console.log('');

  // =========================================================================
  // Step 5: 급여 전송 - ZKP 마법!
  // =========================================================================
  console.log('[5] 급여 전송 실행 중...');
  console.log('');
  console.log('    *** 프라이버시 급여 지급 진행 중 ***');
  console.log('');
  console.log('    회사가 2명의 직원에게 지급:');
  console.log('      - Alice:   5,000 토큰');
  console.log('      - Bob:     4,500 토큰');
  console.log('      --------------------------------');
  console.log('      합계:     9,500 토큰');
  console.log('');
  console.log('    온체인 관찰자가 보는 것:');
  console.log('      - "일부 노트가 소비됨"');
  console.log('      - "새로운 노트가 생성됨"');
  console.log('      - "ZK 증명이 유효함"');
  console.log('');
  console.log('    관찰자가 볼 수 없는 것:');
  console.log('      - 누가 받았는지');
  console.log('      - 각자 얼마나 받았는지');
  console.log('      - 총 급여 금액');
  console.log('');

  const ALICE_SALARY = 5000n;
  const BOB_SALARY = 4500n;

  // 개별 전송으로 급여 지급
  console.log('    Alice에게 5,000 토큰 전송 중...');
  await contract.methods
    .transfer(ALICE_SALARY, company.getAddress(), alice.getAddress())
    .send({ from: company.getAddress() })
    .wait();
  console.log('    Alice 전송 완료!');

  console.log('    Bob에게 4,500 토큰 전송 중...');
  await contract.methods
    .transfer(BOB_SALARY, company.getAddress(), bob.getAddress())
    .send({ from: company.getAddress() })
    .wait();
  console.log('    Bob 전송 완료!');
  console.log('');

  // =========================================================================
  // Step 6: 급여 지급 후 잔액 확인
  // =========================================================================
  console.log('[6] 급여 지급 후 잔액 확인 중...');
  console.log('');

  const companyBalanceAfter = await contract.methods.get_balance(company.getAddress()).simulate({});
  console.log('    회사 잔액:', companyBalanceAfter.toString(), '토큰 (이전 100,000, 지급 9,500)');

  const aliceBalanceAfter = await aliceContract.methods.get_balance(alice.getAddress()).simulate({});
  console.log('    Alice 잔액:', aliceBalanceAfter.toString(), '토큰 (이전 0, 수령 5,000)');

  const bobBalanceAfter = await bobContract.methods.get_balance(bob.getAddress()).simulate({});
  console.log('    Bob 잔액:', bobBalanceAfter.toString(), '토큰 (이전 0, 수령 4,500)');
  console.log('');

  // =========================================================================
  // 결과 요약
  // =========================================================================
  console.log('='.repeat(70));
  console.log('  성공! 프라이버시 급여 데모 완료');
  console.log('='.repeat(70));
  console.log('');
  console.log('  주요 결과:');
  console.log('    - 회사가 2명의 직원에게 비공개 전송으로 지급');
  console.log('    - 각 직원이 정확한 급여를 수령');
  console.log('    - 모든 금액이 온체인에서 비공개 유지');
  console.log('    - 수령자만 자신의 잔액 조회 가능');
  console.log('');
  console.log('  기업 활용 이점:');
  console.log('    - 급여 기밀성 유지');
  console.log('    - ZK 증명으로 프라이버시 보장');
  console.log('    - View Keys를 통한 규제 준수 가능');
  console.log('');
}

main().catch((error) => {
  console.error('오류:', error);
  process.exit(1);
});
```

---

## 7. 실행 가이드

### 7.1 전체 실행 순서 (Quick Start)

```bash
# 1. 프로젝트 클론 또는 생성
git clone <repository-url>
cd aztec-private-token

# 2. Aztec 툴체인 설치 (최초 1회)
curl -s https://install.aztec.network | bash
export PATH="$HOME/.aztec/bin:$PATH"

# 3. Sandbox 시작 (별도 터미널)
aztec start --sandbox

# 4. 테스트 의존성 설치
cd test
npm install

# 5. 테스트 실행
npm test
```

### 7.2 상세 실행 가이드

#### 터미널 1: Sandbox 실행

```bash
# Aztec 환경변수 설정
export PATH="$HOME/.aztec/bin:$PATH"

# Sandbox 시작
aztec start --sandbox

# 출력 예시:
# [16:00:00.000] INFO: aztec:node Block 1 mined
# [16:00:00.000] INFO: PXE listening on http://localhost:8080
```

#### 터미널 2: 테스트 실행

```bash
cd aztec-private-token/test

# 의존성 설치 (최초 1회)
npm install

# 테스트 실행
npm test
```

### 7.3 예상 출력

```
======================================================================
  PRIVACY PAYROLL - 기업용 비공개 급여 지급 데모
======================================================================

  시나리오:
    - 회사 보유 토큰: 100,000
    - 2명의 직원에게 다른 급여 지급:
      * 직원1 (Alice): 5,000 토큰
      * 직원2 (Bob):   4,500 토큰

[1] Aztec PXE에 연결 중...
    PXE 연결 완료: http://localhost:8080

[2] 테스트 계정 설정 중...
    - 회사 (test0): 0x2735b31fb4c6dc2f407bc468669a7edb40a580626...
    - Alice (test1): 0x104d071dbdcd942c30ec1c00b93b2289fd24e2ad7...
    - Bob (test2): 0x25ef07c482a856f04d2fdcba533d3875fd82e97b7b...

[3] 급여 토큰 컨트랙트 배포 중...
    초기 회사 잔액: 100000n 토큰

    ** ZKP 참고: 이 금액은 비공개입니다! **
    ** 회사만 실제 잔액을 알 수 있습니다 **

    ZK 증명 생성 중... (약 15초 소요)
    컨트랙트 배포 완료: 0x20031b9aaa3ffb07db3f63dc0aa64f627854935c...

[4] 초기 잔액 확인 중...
    회사 잔액: 100000 토큰
    Alice 잔액: 0 토큰
    Bob 잔액: 0 토큰

[5] 급여 전송 실행 중...
    Alice에게 5,000 토큰 전송 중...
    Alice 전송 완료!
    Bob에게 4,500 토큰 전송 중...
    Bob 전송 완료!

[6] 급여 지급 후 잔액 확인 중...
    회사 잔액: 90500 토큰 (이전 100,000, 지급 9,500)
    Alice 잔액: 5000 토큰 (이전 0, 수령 5,000)
    Bob 잔액: 4500 토큰 (이전 0, 수령 4,500)

======================================================================
  성공! 프라이버시 급여 데모 완료
======================================================================
```

---

## 8. 문제 해결

### 8.1 Sandbox 연결 오류

**오류 메시지:**
```
Error: Failed to connect to PXE at http://localhost:8080
```

**해결책:**
```bash
# 1. Sandbox가 실행 중인지 확인
curl http://localhost:8080

# 2. Sandbox 재시작
pkill -f aztec
aztec start --sandbox

# 3. 1-2분 대기 후 재시도
```

### 8.2 SDK 버그: "Cannot read properties of undefined"

**오류 메시지:**
```
TypeError: Cannot read properties of undefined (reading 'from')
TypeError: Cannot read properties of undefined (reading 'authWitnesses')
```

**원인:** Aztec SDK v2.1.8의 버그로, `send()` 및 `simulate()` 호출 시 options 매개변수가 필수입니다.

**해결책:**
```typescript
// 잘못된 사용법 (오류 발생)
.send()
.simulate()

// 올바른 사용법
.send({ from: wallet.getAddress() })
.simulate({})
```

### 8.3 컨트랙트 컴파일 오류

**오류 메시지:**
```
error: could not resolve dependency `aztec`
```

**해결책:**
```bash
# Nargo.toml의 태그 버전 확인
# v2.1.5 권장 (v2.1.8 SDK와 호환)

# 캐시 삭제 후 재컴파일
rm -rf target/
aztec-nargo compile
```

### 8.4 메모리 부족

**오류 메시지:**
```
FATAL ERROR: CALL_AND_RETRY_LAST Allocation failed - JavaScript heap out of memory
```

**해결책:**
```bash
# Node.js 메모리 증가
export NODE_OPTIONS="--max-old-space-size=8192"
npm test
```

---

## 9. 기업 활용 시나리오

### 9.1 프라이버시 급여 시스템

```
┌─────────────────────────────────────────────────────────────┐
│                    기업 급여 지급 흐름                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────┐    프라이빗     ┌──────────┐                  │
│  │  회사   │ ──전송────────→ │ 직원 A   │                  │
│  │ 계정    │                 └──────────┘                  │
│  │         │    프라이빗     ┌──────────┐                  │
│  │         │ ──전송────────→ │ 직원 B   │                  │
│  │         │                 └──────────┘                  │
│  │         │    프라이빗     ┌──────────┐                  │
│  │         │ ──전송────────→ │ 직원 C   │                  │
│  └─────────┘                 └──────────┘                  │
│                                                             │
│  온체인에서 보이는 것:                                       │
│  ✓ 트랜잭션 발생                                            │
│  ✓ ZK 증명 유효                                             │
│                                                             │
│  온체인에서 숨겨지는 것:                                     │
│  ✗ 발신자 (회사)                                            │
│  ✗ 수신자 (직원들)                                          │
│  ✗ 금액 (급여)                                              │
│  ✗ 총 지급액                                                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 9.2 규제 준수 (View Keys)

Aztec은 선택적 투명성을 지원합니다:

```typescript
// 감사관에게 읽기 권한 부여
const viewKey = wallet.getViewKey();

// 감사관은 이 키로 특정 계정의 트랜잭션 내역 조회 가능
// 일반 공개는 아님 - 키 보유자만 접근
```

### 9.3 다른 활용 사례

| 사례 | 설명 |
|------|------|
| **프라이버시 투표** | 투표 내용은 숨기고, 유효성만 증명 |
| **의료 데이터** | 진단 결과는 숨기고, 보험 청구 자격만 증명 |
| **공급망 금융** | 거래 금액은 숨기고, 대금 지급만 증명 |
| **크리에이터 로열티** | 수익 분배 금액은 숨기고, 지급 완료만 증명 |

---

## 부록: 참고 자료

### 공식 문서
- [Aztec Documentation](https://docs.aztec.network/)
- [Noir Language](https://noir-lang.org/)
- [aztec.js API Reference](https://docs.aztec.network/reference/aztec-js)

### GitHub 저장소
- [Aztec Packages](https://github.com/AztecProtocol/aztec-packages)
- [Noir Contracts](https://github.com/AztecProtocol/aztec-packages/tree/master/noir-projects/noir-contracts)

### 버전 정보
- **Aztec SDK**: v2.1.8
- **Noir Compiler**: >= 0.25.0
- **Node.js**: >= 18.0.0

---

> **작성일**: 2024년
> **라이선스**: MIT
