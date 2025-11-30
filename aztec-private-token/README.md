# Aztec Private Token - ZKP Demo

이 프로젝트는 Aztec Protocol을 사용하여 **영지식 증명(ZKP)**으로 프라이버시를 보장하는 토큰 컨트랙트를 구현합니다.

## ZKP (Zero Knowledge Proof) 핵심 개념

### 일반 이더리움 토큰 vs Aztec 프라이빗 토큰

```
일반 ERC-20 (모든 정보 공개):
┌──────────────────────────────────────────┐
│ Transfer Event:                          │
│   From: 0xAlice...                      │
│   To: 0xBob...                          │
│   Amount: 100 USDC                      │
│                                          │
│ → 누구나 볼 수 있음!                      │
└──────────────────────────────────────────┘

Aztec Private Token (ZKP 사용):
┌──────────────────────────────────────────┐
│ On-chain Data:                           │
│   - Nullifier: 0x7f3a...  (의미 불명)    │
│   - Commitment: 0x2b8c... (암호화됨)     │
│   - ZK Proof: Valid ✓                    │
│                                          │
│ → 누가, 누구에게, 얼마를 보냈는지 모름!   │
│ → 하지만 거래가 유효함은 증명됨!          │
└──────────────────────────────────────────┘
```

### UTXO 모델과 노트(Note)

Aztec은 Bitcoin과 유사한 UTXO 모델을 사용합니다:

```
Alice의 잔액 = Note(50) + Note(30) + Note(20) = 100 토큰

Alice가 Bob에게 70 전송 시:
1. Note(50) 파괴 (Nullifier 생성)
2. Note(30) 파괴 (Nullifier 생성)
3. Bob에게 Note(70) 생성 (Commitment 생성)
4. Alice에게 Note(10) 생성 (거스름돈)

모든 노트는 암호화되어 소유자만 읽을 수 있음!
```

## 프로젝트 구조

```
aztec-private-token/
├── private_token/           # Noir 컨트랙트
│   ├── Nargo.toml          # 프로젝트 설정
│   ├── src/
│   │   └── main.nr         # 프라이빗 토큰 컨트랙트
│   └── target/             # 컴파일된 아티팩트
│       └── private_token-PrivateToken.json
├── test/
│   ├── package.json
│   └── test.ts             # 테스트 스크립트
└── README.md
```

## 실행 방법

### 1. 환경 설정

```bash
# Aztec 도구 설치 (이미 설치됨)
curl -s https://install.aztec.network | bash

# PATH 설정
export PATH="$HOME/.aztec/bin:$PATH"
```

### 2. Sandbox 시작

새 터미널에서:
```bash
aztec start --sandbox
```

Sandbox가 완전히 시작될 때까지 기다립니다 (약 1-2분).
"Aztec Server listening on port 8080" 메시지가 나타나면 준비 완료!

### 3. 컨트랙트 컴파일

```bash
cd aztec-private-token/private_token
aztec-nargo compile
```

### 4. 테스트 실행

```bash
cd aztec-private-token/test
npm install
npm test
```

## 컨트랙트 설명

### 주요 함수

| 함수 | 설명 | 프라이버시 |
|------|------|-----------|
| `constructor(initial_supply, owner)` | 초기 토큰 발행 | 발행량 숨김 |
| `mint(amount, owner)` | 토큰 추가 발행 | 발행량 숨김 |
| `transfer(amount, sender, recipient)` | 토큰 전송 | 모든 정보 숨김 |
| `get_balance(owner)` | 잔액 조회 | 소유자만 조회 가능 |

### 코드 하이라이트

```rust
// 프라이빗 전송 - ZKP의 핵심!
#[private]
fn transfer(amount: u64, sender: AztecAddress, recipient: AztecAddress) {
    let balances = storage.balances;

    // 보내는 사람 잔액 차감 (내부적으로 노트 파괴)
    balances.at(sender).sub(amount, sender);

    // 받는 사람에게 새 노트 생성 (암호화됨)
    balances.at(recipient).add(amount, recipient);
}
```

이 함수가 실행될 때:
1. ZK 회로가 `sender`의 잔액이 충분한지 증명
2. `sender`가 해당 노트의 소유자인지 증명
3. 토큰이 보존되는지 증명 (생성 = 파괴)
4. 위 모든 것을 **값을 공개하지 않고** 증명!

## 더 알아보기

### 프로젝트 문서
- **[Aztec 아키텍처 완전 가이드](./docs/AZTEC_ARCHITECTURE.md)** - 용어 설명, 동작 원리, 상세 전송 과정

### 외부 자료
- [Aztec Documentation](https://docs.aztec.network/)
- [Noir Language](https://noir-lang.org/)
- [Private Token Tutorial](https://docs.aztec.network/tutorials/codealong/contract_tutorials/token_contract)

## 라이선스

MIT
