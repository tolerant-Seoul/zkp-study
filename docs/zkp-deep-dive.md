# Zero-Knowledge Proof (ZKP) 심화 학습 문서

> 이 문서는 ZKP의 핵심 개념부터 Aztec 프로토콜의 실제 구현까지 체계적으로 정리한 심화 학습 자료입니다.

---

## 목차

1. [ZKP 핵심 개념](#1-zkp-핵심-개념)
2. [선택적 공개 (Selective Disclosure)](#2-선택적-공개-selective-disclosure)
3. [Viewing Key 생성 원리](#3-viewing-key-생성-원리)
4. [Aztec Viewing Key 구현](#4-aztec-viewing-key-구현)
5. [Grumpkin 곡선 상세](#5-grumpkin-곡선-상세)
6. [Nullifier 동작 원리](#6-nullifier-동작-원리)
7. [참고 자료](#7-참고-자료)

---

## 1. ZKP 핵심 개념

### 1.1 ZKP란?

**"나는 비밀을 알고 있다"를 증명하면서, 그 비밀 자체는 공개하지 않는 기술**

### 1.2 동굴 문제 비유

```
         입구
          │
      ┌───┴───┐
      │       │
    A 길     B 길
      │       │
      └───┬───┘
        마법문
       (비밀번호 필요)
```

1. Alice는 마법문의 비밀번호를 안다고 주장
2. Bob은 입구에서 기다림
3. Alice가 랜덤하게 A 또는 B 길로 들어감
4. Bob이 "A 길로 나와!" 또는 "B 길로 나와!" 요청
5. Alice가 비밀번호를 알면 → 항상 요청대로 나올 수 있음
6. 모르면 → 50% 확률로 실패

**20번 반복해서 매번 성공하면 → 비밀번호를 알고 있음이 증명됨 (비밀번호 노출 없이!)**

### 1.3 ZKP의 3가지 속성

| 속성 | 설명 |
|------|------|
| **Completeness** | 증명자가 진실을 알고 있으면, 검증자를 항상 납득시킬 수 있음 |
| **Soundness** | 증명자가 거짓말을 하면, 검증자를 속일 확률이 매우 낮음 |
| **Zero-Knowledge** | 검증자는 "참/거짓" 외에 어떤 추가 정보도 얻지 못함 |

### 1.4 블록체인에서의 ZKP 적용

```
일반 이더리움:
"Alice가 Bob에게 100 ETH 보냄" → 모든 정보가 공개됨

Aztec (ZKP 적용):
"누군가가 누군가에게 무언가를 보냄" + ZK 증명: "이 거래는 유효함"
→ 검증자는 거래가 유효한지만 알고, 상세 내용은 모름
```

---

## 2. 선택적 공개 (Selective Disclosure)

### 2.1 핵심 질문

> "ZKP로 특정 대상(정부기관)에게만 정보를 공개할 수 있는가?"

**답변: 가능합니다.**

ZKP에서는 **서로 다른 수준의 정보를 서로 다른 대상에게 공개**할 수 있습니다.

### 2.2 시나리오 분석

```
┌─────────────────────────────────────────────────────────────┐
│                      당신의 거래                              │
│         "100 자산을 Bob에게 전송"                             │
└─────────────────────────────────────────────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            ▼               ▼               ▼
      ┌─────────┐     ┌─────────┐     ┌─────────┐
      │ 일반 대중 │     │   Bob   │     │ 정부기관 │
      └─────────┘     └─────────┘     └─────────┘

      볼 수 있는 것:    볼 수 있는 것:    볼 수 있는 것:
      ❌ 송신자         ✅ 송신자(당신)   ✅ 송신자
      ❌ 수신자         ✅ 금액(100)      ✅ 수신자
      ❌ 금액           ✅ 본인이 수신자   ✅ 금액
      ✅ "유효한 거래"                    ✅ 타임스탬프
```

### 2.3 구현 방식: Viewing Keys

#### 키 구조

```
┌─────────────────────────────────────────┐
│              사용자 키 체계               │
├─────────────────────────────────────────┤
│  Spending Key (소비 키)                  │
│  └─ 자산을 전송할 때 사용                 │
│                                         │
│  Viewing Key (조회 키)                   │
│  └─ 거래 내역을 복호화할 때 사용           │
│  └─ 제3자에게 선택적으로 공유 가능         │
│                                         │
│  Nullifier Key (무효화 키)               │
│  └─ 이중 지불 방지용                     │
└─────────────────────────────────────────┘
```

#### 정부기관에 조회권 부여 흐름

```
Step 1: 거래 생성
┌──────────────────────────────────────────────────┐
│  당신 → Bob: 100 자산                            │
│  - 거래 데이터는 암호화되어 체인에 기록            │
│  - ZK Proof: "이 거래는 유효함" (공개)            │
└──────────────────────────────────────────────────┘
                    │
                    ▼
Step 2: Viewing Key 파생
┌──────────────────────────────────────────────────┐
│  Master Viewing Key                              │
│       │                                          │
│       ├─→ 정부기관용 Restricted Viewing Key       │
│       │   (특정 거래 범위만 볼 수 있음)            │
│       │                                          │
│       └─→ 회계사용 Viewing Key                   │
│           (다른 범위의 거래만 볼 수 있음)          │
└──────────────────────────────────────────────────┘
                    │
                    ▼
Step 3: 정부기관의 검증
┌──────────────────────────────────────────────────┐
│  정부기관이 Viewing Key로 거래 복호화:            │
│  - 송신자: 당신                                  │
│  - 수신자: Bob                                   │
│  - 금액: 100                                     │
│  - 시간: 2025-01-15 14:30:00                    │
└──────────────────────────────────────────────────┘
```

### 2.4 암호화 계층 분리

거래 데이터를 **다중 레이어로 암호화**하여 저장:

```
┌─────────────────────────────────────────────────────────────────┐
│                        거래 데이터 구조                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Layer 5: 최고 기밀 (Master Key만 복호화)                  │   │
│  │ ┌─────────────────────────────────────────────────────┐ │   │
│  │ │ Layer 4: 송신자 개인정보                             │ │   │
│  │ │ ┌─────────────────────────────────────────────────┐│ │   │
│  │ │ │ Layer 3: 타임스탬프 + 메모                      ││ │   │
│  │ │ │ ┌─────────────────────────────────────────────┐││ │   │
│  │ │ │ │ Layer 2: 송수신자 주소                      │││ │   │
│  │ │ │ │ ┌─────────────────────────────────────────┐│││ │   │
│  │ │ │ │ │ Layer 1: 금액만                        ││││ │   │
│  │ │ │ │ │         Enc(amount, key_depth_1)       ││││ │   │
│  │ │ │ │ └─────────────────────────────────────────┘│││ │   │
│  │ │ │ │ Enc(addresses, key_depth_2)                │││ │   │
│  │ │ │ └─────────────────────────────────────────────┘││ │   │
│  │ │ │ Enc(timestamp + memo, key_depth_3)             ││ │   │
│  │ │ └─────────────────────────────────────────────────┘│ │   │
│  │ │ Enc(sender_metadata, key_depth_4)                  │ │   │
│  │ └─────────────────────────────────────────────────────┘ │   │
│  │ Enc(full_audit_log, key_depth_5)                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.5 기관별 권한 매핑

| 기관 | Depth | 볼 수 있는 정보 |
|------|-------|----------------|
| 통계청 | 1 | 금액만 (익명화된 거래량 집계) |
| 국세청 | 2 | 금액 + 수신자 주소 |
| 금융감독원 | 3 | 금액 + 주소 + 시간 |
| 검찰/경찰 | 4 | 위 + 송신자 메타데이터 (영장 필요) |
| 본인 | 5 | 모든 정보 |

---

## 3. Viewing Key 생성 원리

### 3.1 키 계층 구조 (Hierarchical Key Derivation)

```
                    ┌─────────────────────┐
                    │   Master Seed       │
                    │   (최상위 시드)      │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │   Spending Key (sk) │
                    │   자산 전송 권한      │
                    └──────────┬──────────┘
                               │
               ┌───────────────┼───────────────┐
               ▼               ▼               ▼
      ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
      │ Full View   │  │ Incoming    │  │ Nullifier   │
      │ Key (fvk)   │  │ View Key    │  │ Key (nk)    │
      │ 전체 조회    │  │ 수신만 조회  │  │ 이중지불방지 │
      └──────┬──────┘  └─────────────┘  └─────────────┘
             │
    ┌────────┼────────┬────────────────┐
    ▼        ▼        ▼                ▼
┌───────┐┌───────┐┌───────┐      ┌───────────┐
│Depth 1││Depth 2││Depth 3│ ...  │ Custom    │
│금액만 ││+주소  ││+시간  │      │ Scoped Key│
└───────┘└───────┘└───────┘      └───────────┘
```

### 3.2 수학적 원리

#### 키 파생 (Key Derivation Function)

```
기본 공식:

Master Viewing Key (mvk) = PRF(spending_key, "viewing")

여기서 PRF = Pseudo-Random Function (예: BLAKE2, Poseidon Hash)
```

#### 계층적 파생

```python
def derive_viewing_key(master_key, depth, scope):
    """
    master_key: 마스터 조회 키
    depth: 공개 깊이 (1-5)
    scope: 범위 제한 (시간, 주소 등)
    """

    # 1단계: 깊이별 서브키 생성
    depth_key = hash(master_key || depth)

    # 2단계: 범위 제한 적용
    scoped_key = hash(depth_key || scope)

    # 3단계: 기관용 최종 키 생성
    final_key = hash(scoped_key || institution_id)

    return final_key
```

### 3.3 Layered Encryption 원리

```
각 레이어는 독립적인 키로 암호화:

Ciphertext = Enc(Enc(Enc(Enc(Enc(
    plaintext,      // 원본 데이터
    key_5),         // Layer 5 키
    key_4),         // Layer 4 키
    key_3),         // Layer 3 키
    key_2),         // Layer 2 키
    key_1)          // Layer 1 키

복호화 시:
- key_1만 있으면 → Layer 1까지만 복호화 (금액)
- key_1 + key_2 있으면 → Layer 2까지 복호화 (금액 + 주소)
- ...
```

### 3.4 실제 구현 예시 (Rust-like 의사코드)

```rust
// 거래 데이터 구조체
struct TransactionData {
    amount: u64,           // Layer 1
    sender: Address,       // Layer 2
    receiver: Address,     // Layer 2
    timestamp: u64,        // Layer 3
    memo: String,          // Layer 3
    sender_metadata: Meta, // Layer 4
    full_audit: AuditLog,  // Layer 5
}

// 계층적 Viewing Key 구조체
struct HierarchicalViewingKey {
    depth: u8,                    // 1-5
    scope: KeyScope,              // 시간/주소 범위 제한
    derived_keys: Vec<[u8; 32]>,  // depth만큼의 복호화 키
}

impl HierarchicalViewingKey {
    // 마스터 키에서 특정 깊이의 Viewing Key 파생
    fn derive(master_vk: &MasterViewingKey, depth: u8, scope: KeyScope) -> Self {
        let mut derived_keys = Vec::new();

        for d in 1..=depth {
            // 각 레이어의 복호화 키 생성
            let layer_key = poseidon_hash(&[
                master_vk.as_bytes(),
                &d.to_le_bytes(),
                &scope.to_bytes(),
            ]);
            derived_keys.push(layer_key);
        }

        Self { depth, scope, derived_keys }
    }

    // 이 키로 복호화 가능한 데이터 범위
    fn decrypt(&self, encrypted_tx: &EncryptedTransaction) -> PartialTransaction {
        let mut result = PartialTransaction::empty();

        // Depth 1: 금액
        if self.depth >= 1 {
            result.amount = Some(decrypt(
                &encrypted_tx.layer1,
                &self.derived_keys[0]
            ));
        }

        // Depth 2: 주소들
        if self.depth >= 2 {
            let addrs = decrypt(&encrypted_tx.layer2, &self.derived_keys[1]);
            result.sender = Some(addrs.sender);
            result.receiver = Some(addrs.receiver);
        }

        // Depth 3: 시간 + 메모
        if self.depth >= 3 {
            let meta = decrypt(&encrypted_tx.layer3, &self.derived_keys[2]);
            result.timestamp = Some(meta.timestamp);
            result.memo = Some(meta.memo);
        }

        // ... Layer 4, 5 동일 패턴

        result
    }
}
```

### 3.5 Scope (범위) 제한 기능

깊이 외에도 **범위**를 제한할 수 있습니다:

```rust
struct KeyScope {
    // 시간 범위: 이 기간의 거래만 볼 수 있음
    time_range: Option<(Timestamp, Timestamp)>,

    // 주소 범위: 특정 주소와의 거래만 볼 수 있음
    address_filter: Option<Vec<Address>>,

    // 금액 범위: 일정 금액 이상만 볼 수 있음
    min_amount: Option<u64>,

    // 거래 유형: 특정 유형만 볼 수 있음
    tx_types: Option<Vec<TxType>>,
}

// 예시: 국세청용 키 생성
let tax_authority_key = HierarchicalViewingKey::derive(
    &master_vk,
    depth: 2,  // 금액 + 주소까지
    scope: KeyScope {
        time_range: Some((
            Timestamp::from("2024-01-01"),
            Timestamp::from("2024-12-31"),
        )),  // 2024년도 거래만
        address_filter: None,  // 모든 주소
        min_amount: Some(10_000_000),  // 1천만원 이상만
        tx_types: None,
    }
);
```

### 3.6 키 폐기 및 권한 회수

```rust
struct RevocableViewingKey {
    key: HierarchicalViewingKey,
    valid_until: Timestamp,        // 만료 시간
    revocation_nullifier: Hash,    // 폐기용 식별자
}

impl RevocableViewingKey {
    fn revoke(&self, master_key: &MasterKey) {
        // 1. 폐기 nullifier를 블록체인에 게시
        publish_revocation(self.revocation_nullifier);

        // 2. 이후 새 거래는 이 키로 복호화 불가
    }
}
```

---

## 4. Aztec Viewing Key 구현

### 4.1 Aztec 키 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                    Aztec 키 아키텍처                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                      Master Seed                                │
│                          │                                      │
│          ┌───────────────┼───────────────┬──────────────┐       │
│          ▼               ▼               ▼              ▼       │
│    ┌──────────┐   ┌───────────┐   ┌───────────┐  ┌──────────┐  │
│    │ nsk_m    │   │ ivsk_m    │   │ ovsk_m    │  │ tsk_m    │  │
│    │ Nullifier│   │ Incoming  │   │ Outgoing  │  │ Tagging  │  │
│    │ Secret   │   │ Viewing   │   │ Viewing   │  │ Secret   │  │
│    │ Key      │   │ Secret Key│   │ Secret Key│  │ Key      │  │
│    └────┬─────┘   └─────┬─────┘   └─────┬─────┘  └────┬─────┘  │
│         │               │               │              │        │
│         ▼               ▼               ▼              ▼        │
│    ┌──────────┐   ┌───────────┐   ┌───────────┐  ┌──────────┐  │
│    │ Npk_m    │   │ Ivpk_m    │   │ Ovpk_m    │  │ Tpk_m    │  │
│    │ Public   │   │ Public    │   │ Public    │  │ Public   │  │
│    └──────────┘   └───────────┘   └───────────┘  └──────────┘  │
│                                                                 │
│    address = hash(Npk_m, Ivpk_m, Ovpk_m, Tpk_m)                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### 키 유형 설명

| 키 | 용도 | 설명 |
|----|------|------|
| `nsk_m` / `Npk_m` | Nullifier | 노트 소비(spending) 시 nullifier 생성 |
| `ivsk_m` / `Ivpk_m` | Incoming Viewing | 수신 데이터 복호화 |
| `ovsk_m` / `Ovpk_m` | Outgoing Viewing | 송신 데이터 복호화 (예약됨) |
| `tsk_m` / `Tpk_m` | Tagging | 노트 발견 최적화 (예약됨) |

### 4.2 Viewing Key 파생 공식

```noir
// Master Incoming Viewing Secret Key 파생
// Grumpkin 타원곡선 사용

// 1. 마스터 시크릿 키 생성
ivsk_m = derive_master_secret_key_from_seed("az_ivsk_m", seed)

// 2. 마스터 퍼블릭 키 생성 (타원곡선 곱셈)
Ivpk_m = derive_public_key(ivsk_m)
       = ivsk_m * G  // G는 Grumpkin 생성점

// 3. 주소 계산
public_keys_hash = poseidon_hash(Npk_m, Ivpk_m, Ovpk_m, Tpk_m)
pre_address = poseidon_hash(public_keys_hash, partial_address)
address = (pre_address * G + Ivpk_m).x  // x 좌표만 사용
```

### 4.3 App-Siloed Key (계층적 공개의 핵심)

```noir
// 앱별로 격리된 키 파생 - 특정 컨트랙트에서만 유효한 키

// Nullifier Key의 앱 격리
nsk_app = poseidon_hash(nsk_m, app_contract_address)

// Viewing Key의 앱 격리 (개념적)
ivsk_app = poseidon_hash(ivsk_m, app_contract_address, scope_params)
```

**App-Siloed가 중요한 이유:**

```
┌─────────────────────────────────────────────────────────────────┐
│ 사용자가 3개의 앱 사용 중                                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │ DeFi App    │  │ NFT Market  │  │ Payment App │             │
│  │ (Contract A)│  │ (Contract B)│  │ (Contract C)│             │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘             │
│         │                │                │                     │
│         ▼                ▼                ▼                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │ ivsk_app_A  │  │ ivsk_app_B  │  │ ivsk_app_C  │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                 │
│  국세청에 ivsk_app_C만 제공하면:                                 │
│  ✅ Payment App 거래만 볼 수 있음                                │
│  ❌ DeFi, NFT 거래는 볼 수 없음                                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.4 Note 암호화 과정 (ECDH 기반)

```noir
// === 송신자 측 (Alice가 Bob에게 전송) ===

fn encrypt_note_for_recipient(
    note: Note,
    recipient_ivpk: Point,  // Bob의 Incoming Viewing Public Key
) -> EncryptedNote {
    // 1. 임시 키 쌍 생성 (ephemeral)
    let eph_sk = random_scalar();           // 임시 비밀키
    let eph_pk = eph_sk * G;                // 임시 공개키

    // 2. 공유 비밀 계산 (ECDH)
    let shared_secret = eph_sk * recipient_ivpk;  // S = eph_sk * Ivpk_bob

    // 3. 대칭 암호화 키 파생
    let encryption_key = poseidon_hash(shared_secret.x, shared_secret.y);

    // 4. 노트 데이터 암호화
    let encrypted_data = aes_encrypt(note.serialize(), encryption_key);

    EncryptedNote {
        ephemeral_public_key: eph_pk,  // 체인에 공개
        ciphertext: encrypted_data,     // 암호화된 노트
    }
}


// === 수신자 측 (Bob이 복호화) ===

fn decrypt_note(
    encrypted_note: EncryptedNote,
    recipient_ivsk: Field,  // Bob의 Incoming Viewing Secret Key
) -> Note {
    // 1. 동일한 공유 비밀 계산
    let shared_secret = recipient_ivsk * encrypted_note.ephemeral_public_key;
    // S = ivsk_bob * eph_pk
    //   = ivsk_bob * (eph_sk * G)
    //   = eph_sk * (ivsk_bob * G)
    //   = eph_sk * Ivpk_bob

    // 2. 동일한 대칭 암호화 키 파생
    let encryption_key = poseidon_hash(shared_secret.x, shared_secret.y);

    // 3. 복호화
    let note_data = aes_decrypt(encrypted_note.ciphertext, encryption_key);

    Note::deserialize(note_data)
}
```

### 4.5 실제 Aztec Token Contract 구현

```noir
// 출처: aztec-packages/noir-projects/noir-contracts/contracts/token_contract

use dep::aztec::prelude::{
    AztecAddress,
    PrivateContext,
    PrivateSet,
    Map,
};
use dep::aztec::encrypted_logs::encrypted_note_emission::encode_and_encrypt_note;

#[aztec]
contract Token {
    use dep::aztec::keys::getters::get_public_keys;
    use dep::value_note::value_note::ValueNote;

    #[storage]
    struct Storage<Context> {
        balances: Map<AztecAddress, PrivateSet<ValueNote, Context>, Context>,
    }

    /// Private Transfer - Viewing Key가 사용되는 핵심 함수
    #[private]
    fn transfer(to: AztecAddress, amount: Field) {
        let from = context.msg_sender();

        // 1. 송신자 잔액에서 차감
        let from_balance = storage.balances.at(from);
        from_balance.sub(from, amount);

        // 2. 수신자에게 새 노트 생성
        let to_balance = storage.balances.at(to);

        // 3. 수신자의 공개키들 조회 (Viewing Key 포함)
        let to_keys = get_public_keys(to);

        // 4. 새 ValueNote 생성
        let mut note = ValueNote::new(amount, to_keys.npk_m.hash());

        // 5. 노트를 저장하고 암호화된 로그 발행
        to_balance.insert(&mut note).emit(
            encode_and_encrypt_note(
                &mut context,
                to_keys.ovpk_m,  // Outgoing Viewing Public Key
                to_keys.ivpk_m,  // Incoming Viewing Public Key ← 핵심!
                to,
            )
        );
    }
}
```

### 4.6 TypeScript SDK에서의 Viewing Key 사용

```typescript
import {
    PXE,
    AccountWallet,
    deriveKeys,
    computeAddress
} from '@aztec/aztec.js';

// 1. 키 파생
const seed = randomBytes(32);
const keys = deriveKeys(seed);

console.log({
    // Nullifier Keys
    nsk_m: keys.masterNullifierSecretKey,
    npk_m: keys.masterNullifierPublicKey,

    // Incoming Viewing Keys - 수신 데이터 복호화
    ivsk_m: keys.masterIncomingViewingSecretKey,
    ivpk_m: keys.masterIncomingViewingPublicKey,

    // Outgoing Viewing Keys - 송신 데이터 복호화 (미래용)
    ovsk_m: keys.masterOutgoingViewingSecretKey,
    ovpk_m: keys.masterOutgoingViewingPublicKey,
});

// 2. 주소 계산
const address = computeAddress(keys.publicKeys);

// 3. 특정 앱용 Viewing Key 파생 (감사자 제공용)
function deriveAppScopedViewingKey(
    masterIvsk: Fr,
    appAddress: AztecAddress,
    scope: AuditScope
): Fr {
    return poseidonHash([
        masterIvsk,
        appAddress.toField(),
        scope.minAmount,
        scope.startTime,
        scope.endTime,
    ]);
}
```

---

## 5. Grumpkin 곡선 상세

### 5.1 Grumpkin이란?

**Grumpkin**은 Aztec 프로토콜의 Zachary J. Williamson이 설계한 타원곡선으로, BN254와 **곡선 사이클(curve cycle)**을 형성합니다.

### 5.2 곡선 파라미터

```
곡선 방정식: Y² = X³ - 17

파라미터:
┌────────────────────────────────────────────────────────────────┐
│ p (필드 크기)                                                   │
│ = 21888242871839275222246405745257275088548364400416034343698  │
│   204186575808495617                                           │
│                                                                 │
│ a = 0                                                          │
│ b = -17                                                        │
│                                                                 │
│ r (그룹 차수)                                                   │
│ = 21888242871839275222246405745257275088696311157297823662689  │
│   037894645226208583                                           │
│                                                                 │
│ 보안 수준: ~127비트 (Pollard's Rho 공격 기준)                   │
│ 비트 크기: 254비트                                              │
└────────────────────────────────────────────────────────────────┘
```

### 5.3 BN254와의 사이클 관계

```
┌─────────────────────────────────────────────────────────────────┐
│                    곡선 사이클 (Curve Cycle)                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│     ┌──────────────┐          ┌──────────────┐                 │
│     │   BN254      │          │   Grumpkin   │                 │
│     │   (페어링)    │◄────────►│   (일반)      │                 │
│     └──────────────┘          └──────────────┘                 │
│                                                                 │
│     필드 차수 (p)  ◄──────────► 그룹 차수 (r)                   │
│     그룹 차수 (r)  ◄──────────► 필드 차수 (p)                   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ BN254의 스칼라 필드 = Grumpkin의 기본 필드                 │   │
│  │ Grumpkin의 스칼라 필드 = BN254의 기본 필드                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.4 왜 곡선 사이클이 중요한가?

```
ZK-SNARK 증명 검증 과정:

일반적인 경우:
┌───────────────────────────────────────────────────────────────┐
│  증명 생성 (곡선 A)  →  증명 검증 (곡선 A 연산을 B에서 시뮬레이션) │
│                                                                │
│  문제: 곡선 A의 연산을 곡선 B의 회로에서 구현하면 매우 비효율적   │
└───────────────────────────────────────────────────────────────┘

곡선 사이클 사용:
┌───────────────────────────────────────────────────────────────┐
│  증명 생성 (BN254)  →  증명 검증 (Grumpkin 회로 내에서)         │
│                        │                                       │
│                        ▼                                       │
│  증명 생성 (Grumpkin) →  증명 검증 (BN254 회로 내에서)          │
│                                                                │
│  장점: 각 곡선의 연산이 다른 곡선의 "네이티브" 필드에서 수행됨   │
│  → 재귀적 SNARK (Recursive SNARKs)에 최적화                    │
└───────────────────────────────────────────────────────────────┘
```

### 5.5 Grumpkin의 용도

| 용도 | 설명 |
|------|------|
| **Pedersen Hash** | 노트 커밋먼트 해시 계산 |
| **ECDH 키 교환** | Viewing Key를 통한 암호화/복호화 |
| **Schnorr 서명** | 트랜잭션 서명 (선택적) |
| **재귀적 증명** | BN254와 함께 증명 재귀에 사용 |

### 5.6 코드에서의 Grumpkin 사용

```rust
// Grumpkin 곡선 연산 예시 (gnark-crypto 스타일)

use grumpkin::{G1Affine, Fr, G1Projective};

// 1. 스칼라 (비밀키) 생성
let secret_key: Fr = Fr::random();

// 2. 공개키 계산 (G는 생성점)
let public_key: G1Affine = (G1Projective::generator() * secret_key).into();

// 3. ECDH 공유 비밀 계산
fn compute_shared_secret(
    my_secret: Fr,
    their_public: G1Affine
) -> G1Affine {
    (G1Projective::from(their_public) * my_secret).into()
}

// 4. Pedersen 커밋먼트
fn pedersen_commit(value: Fr, blinding: Fr) -> G1Affine {
    let G = G1Projective::generator();
    let H = G1Projective::hash_to_curve("pedersen_h");

    (G * value + H * blinding).into()
}
```

### 5.7 Grumpkin vs 다른 곡선

| 곡선 | 페어링 | 보안 수준 | 사이클 파트너 | 주요 용도 |
|------|--------|-----------|---------------|-----------|
| **Grumpkin** | ❌ | 127비트 | BN254 | Aztec 내부 연산 |
| **BN254** | ✅ | 100비트* | Grumpkin | SNARK 검증 |
| **BLS12-381** | ✅ | 128비트 | - | Ethereum 2.0 |
| **secp256k1** | ❌ | 128비트 | - | Bitcoin, Ethereum |

*BN254의 보안 수준은 최근 연구로 하향 조정됨

---

## 6. Nullifier 동작 원리

### 6.1 Nullifier란?

**Nullifier**는 프라이빗 노트(UTXO)가 "소비되었음"을 표시하는 고유 식별자입니다. 이를 통해 **이중 지불(Double Spending)을 방지**하면서도 **어떤 노트가 소비되었는지는 숨깁니다**.

### 6.2 왜 Nullifier가 필요한가?

```
문제: 프라이버시를 유지하면서 이중 지불을 방지해야 함

일반 블록체인 (투명):
┌────────────────────────────────────────────────────────────┐
│  UTXO #123 (100 ETH)  →  소비됨으로 표시  →  다시 사용 불가  │
│                                                             │
│  문제: 누구나 #123이 소비되었음을 알 수 있음                 │
└────────────────────────────────────────────────────────────┘

프라이버시 블록체인 (Nullifier 사용):
┌────────────────────────────────────────────────────────────┐
│  UTXO #123 (암호화)  →  Nullifier 발행  →  다시 사용 불가   │
│                                                             │
│  Nullifier = hash(secret_key, note_id)                      │
│                                                             │
│  외부 관찰자:                                                │
│  - Nullifier가 발행되었음은 알 수 있음                       │
│  - 어떤 노트에 해당하는지는 알 수 없음 (해시 역산 불가)       │
└────────────────────────────────────────────────────────────┘
```

### 6.3 UTXO와 Nullifier 관계

```
┌─────────────────────────────────────────────────────────────────┐
│                    노트 생명주기                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. 노트 생성                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Note {                                                  │   │
│  │    value: 100,                                           │   │
│  │    owner: Alice_pubkey,                                  │   │
│  │    randomness: r  // 고유성 보장                          │   │
│  │  }                                                       │   │
│  │                                                          │   │
│  │  commitment = hash(value, owner, randomness)             │   │
│  │  → Note Hash Tree에 추가됨                               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                          │                                      │
│                          ▼                                      │
│  2. 노트 소비 (전송 시)                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  nullifier = hash(nsk, commitment)                       │   │
│  │                                                          │   │
│  │  ZK Proof 생성:                                          │   │
│  │  - "나는 commitment에 해당하는 노트를 알고 있다"          │   │
│  │  - "나는 이 노트의 소유자다 (nsk를 알고 있다)"            │   │
│  │  - "이 nullifier는 해당 노트에서 올바르게 파생되었다"     │   │
│  │                                                          │   │
│  │  → Nullifier Tree에 nullifier 추가                       │   │
│  │  → 노트는 더 이상 사용 불가                               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 6.4 Nullifier 계산 공식

```noir
// Aztec에서의 Nullifier 계산

// 1. 노트 해시 계산
fn compute_note_hash(note: Note) -> Field {
    poseidon_hash([
        note.value,
        note.owner.to_field(),
        note.randomness,
    ])
}

// 2. Nullifier 계산
fn compute_nullifier(
    note_hash: Field,
    nsk_app: Field,  // App-siloed Nullifier Secret Key
) -> Field {
    poseidon_hash([
        note_hash,
        nsk_app,
    ])
}

// 3. App-Siloed Nullifier Key 파생
fn derive_nsk_app(
    nsk_m: Field,           // Master Nullifier Secret Key
    app_address: AztecAddress,
) -> Field {
    poseidon_hash([
        nsk_m,
        app_address.to_field(),
    ])
}
```

### 6.5 이중 지불 방지 메커니즘

```
┌─────────────────────────────────────────────────────────────────┐
│                    이중 지불 시도 시나리오                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Alice의 노트: Note_A (100 토큰)                                 │
│  commitment_A = hash(100, Alice, r_A)                           │
│  nullifier_A = hash(nsk_alice, commitment_A)                    │
│                                                                 │
│  ═══════════════════════════════════════════════════════════   │
│                                                                 │
│  첫 번째 전송 (성공):                                            │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Alice → Bob: 100 토큰                                   │   │
│  │  1. ZK Proof 생성 (Note_A 소유 증명)                      │   │
│  │  2. nullifier_A를 Nullifier Tree에 삽입                  │   │
│  │  3. Bob에게 새 노트 생성                                  │   │
│  │  ✅ 성공                                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  두 번째 전송 시도 (실패):                                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Alice → Charlie: 100 토큰 (같은 노트 재사용 시도)        │   │
│  │  1. ZK Proof 생성 (Note_A 소유 증명)                      │   │
│  │  2. nullifier_A를 Nullifier Tree에 삽입 시도             │   │
│  │  3. ❌ 실패: nullifier_A가 이미 존재함!                   │   │
│  │                                                          │   │
│  │  → 트랜잭션 거부됨                                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 6.6 Nullifier Tree 구조

```
┌─────────────────────────────────────────────────────────────────┐
│                    Aztec의 상태 트리 구조                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────┐     ┌─────────────────────┐           │
│  │   Note Hash Tree    │     │   Nullifier Tree    │           │
│  │   (Append-only)     │     │   (Indexed Merkle)  │           │
│  └──────────┬──────────┘     └──────────┬──────────┘           │
│             │                           │                       │
│             ▼                           ▼                       │
│  ┌─────────────────────┐     ┌─────────────────────┐           │
│  │     commitment_1    │     │    nullifier_1      │           │
│  │     commitment_2    │     │    nullifier_2      │           │
│  │     commitment_3    │     │    nullifier_3      │           │
│  │         ...         │     │        ...          │           │
│  └─────────────────────┘     └─────────────────────┘           │
│                                                                 │
│  노트 생성 시:                 노트 소비 시:                     │
│  → commitment 추가            → nullifier 추가                  │
│  → 삭제 불가 (append-only)    → 삭제 불가 (append-only)         │
│                                                                 │
│  ═══════════════════════════════════════════════════════════   │
│                                                                 │
│  핵심: commitment와 nullifier는 연결되어 있지만,                │
│        외부에서는 어떤 commitment가 어떤 nullifier와              │
│        연결되는지 알 수 없음 (ZK 증명으로만 검증)                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 6.7 ZK 회로에서의 Nullifier 검증

```noir
// Nullifier 유효성 검증 회로

fn verify_note_spend(
    // 공개 입력 (Public Inputs)
    nullifier: Field,              // 발행할 nullifier
    note_hash_tree_root: Field,    // 현재 노트 트리 루트
    nullifier_tree_root: Field,    // 현재 nullifier 트리 루트

    // 비밀 입력 (Private Inputs / Witnesses)
    note: Note,                    // 소비할 노트
    nsk_app: Field,                // App-siloed nullifier secret key
    note_path: MerklePath,         // 노트 존재 증명 경로
) {
    // 1. 노트 해시 계산
    let computed_commitment = poseidon_hash([
        note.value,
        note.owner.to_field(),
        note.randomness,
    ]);

    // 2. 노트가 트리에 존재하는지 검증
    assert(
        verify_merkle_proof(
            computed_commitment,
            note_path,
            note_hash_tree_root
        )
    );

    // 3. Nullifier가 올바르게 계산되었는지 검증
    let computed_nullifier = poseidon_hash([
        computed_commitment,
        nsk_app,
    ]);
    assert(nullifier == computed_nullifier);

    // 4. Nullifier가 아직 사용되지 않았는지는
    //    회로 외부에서 Nullifier Tree 삽입 시 검증됨
}
```

### 6.8 Nullifier의 보안 속성

| 속성 | 설명 |
|------|------|
| **유일성** | 각 노트에 대해 정확히 하나의 유효한 nullifier만 존재 |
| **비연결성** | Nullifier에서 원본 노트를 역추적할 수 없음 |
| **소유권 증명** | nsk 없이는 유효한 nullifier 생성 불가 |
| **결정론적** | 같은 노트와 키로는 항상 같은 nullifier 생성 |

### 6.9 전체 프라이빗 전송 흐름

```
┌─────────────────────────────────────────────────────────────────┐
│              Alice → Bob: 100 토큰 프라이빗 전송                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Step 1: Alice의 노트 선택                                      │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Alice의 노트: Note_A (value: 150)                       │   │
│  │  commitment_A = hash(150, Alice_npk, r_A)               │   │
│  │  → Note Hash Tree에 존재                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                          │                                      │
│                          ▼                                      │
│  Step 2: ZK 증명 생성 (Alice의 PXE에서)                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  증명 내용:                                               │   │
│  │  1. "commitment_A가 Note Hash Tree에 존재함"              │   │
│  │  2. "나(Alice)는 Note_A의 소유자임"                       │   │
│  │  3. "Note_A.value(150) >= 전송량(100)"                   │   │
│  │  4. "nullifier_A는 commitment_A에서 올바르게 파생됨"      │   │
│  │  5. "새 노트들의 value 합 = 기존 노트 value"              │   │
│  └─────────────────────────────────────────────────────────┘   │
│                          │                                      │
│                          ▼                                      │
│  Step 3: 새 노트 생성                                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Note_Bob (value: 100, owner: Bob_npk)                   │   │
│  │  → commitment_Bob = hash(100, Bob_npk, r_Bob)            │   │
│  │  → Bob의 ivpk로 암호화되어 발행                           │   │
│  │                                                          │   │
│  │  Note_Alice_change (value: 50, owner: Alice_npk)         │   │
│  │  → commitment_change = hash(50, Alice_npk, r_change)     │   │
│  │  → Alice의 ivpk로 암호화되어 발행                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                          │                                      │
│                          ▼                                      │
│  Step 4: 온체인 상태 업데이트                                    │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Note Hash Tree:                                         │   │
│  │  + commitment_Bob                                        │   │
│  │  + commitment_change                                     │   │
│  │                                                          │   │
│  │  Nullifier Tree:                                         │   │
│  │  + nullifier_A (Note_A 무효화)                            │   │
│  │                                                          │   │
│  │  공개되는 정보:                                           │   │
│  │  - ZK Proof (유효성 증명)                                 │   │
│  │  - nullifier_A (어떤 노트인지는 모름)                     │   │
│  │  - 새 commitments (내용은 모름)                           │   │
│  │  - 암호화된 노트 데이터 (소유자만 복호화 가능)             │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. 참고 자료

### 공식 문서

- [Aztec Keys Documentation](https://docs.aztec.network/developers/docs/concepts/accounts/keys)
- [Aztec Protocol Specification - Keys](https://docs.aztec.network/protocol-specs/addresses-and-keys/keys)
- [Aztec Notes (UTXOs)](https://docs.aztec.network/developers/docs/concepts/storage/notes)
- [Indexed Merkle Tree (Nullifier Tree)](https://docs.aztec.network/developers/docs/concepts/advanced/storage/indexed_merkle_tree)

### GitHub 저장소

- [AztecProtocol/aztec-packages](https://github.com/AztecProtocol/aztec-packages)
- [AztecProtocol/aztec-nr](https://github.com/AztecProtocol/aztec-nr)
- [arkworks-rs/curves (Grumpkin)](https://github.com/arkworks-rs/curves)
- [ConsenSys/gnark-crypto](https://github.com/ConsenSys/gnark-crypto)

### 학습 자료

- [matter-labs/awesome-zero-knowledge-proofs](https://github.com/matter-labs/awesome-zero-knowledge-proofs)
- [Mull Over The Nullifier - HackMD](https://hackmd.io/@liangcc/nullifier)
- [BN254 For The Rest Of Us - HackMD](https://hackmd.io/@jpw/bn254)

### 프로젝트 비교

| 프로젝트 | Viewing Key | Nullifier | 곡선 |
|---------|-------------|-----------|------|
| **Aztec** | ✅ (ivsk/Ivpk) | ✅ | Grumpkin + BN254 |
| **Zcash** | ✅ | ✅ | Jubjub + BLS12-381 |
| **Tornado Cash** | ❌ | ✅ | BN254 |
| **Railgun** | ✅ | ✅ | BN254 |

---

## 요약

```
┌─────────────────────────────────────────────────────────────────┐
│                    ZKP 심화 학습 핵심 정리                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. 선택적 공개 (Selective Disclosure)                          │
│     • Viewing Key로 특정 대상에게만 정보 공개 가능               │
│     • 계층적 키 파생으로 깊이(Depth)별 공개 수준 제어             │
│     • Scope 제한으로 시간/금액/앱별 범위 지정 가능               │
│                                                                 │
│  2. Aztec Viewing Key                                           │
│     • ECDH 기반 암호화 (Grumpkin 곡선)                           │
│     • ivsk_m / Ivpk_m: 수신 데이터 복호화                        │
│     • App-Siloed Key: 앱별 격리된 조회 권한                      │
│                                                                 │
│  3. Grumpkin 곡선                                               │
│     • Y² = X³ - 17 (254비트, ~127비트 보안)                     │
│     • BN254와 곡선 사이클 형성                                   │
│     • 재귀적 SNARK에 최적화                                      │
│                                                                 │
│  4. Nullifier                                                   │
│     • 이중 지불 방지의 핵심 메커니즘                              │
│     • nullifier = hash(nsk, commitment)                         │
│     • 노트 소비 시 발행, 재사용 불가                              │
│     • 어떤 노트가 소비되었는지는 숨김 (비연결성)                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

*마지막 업데이트: 2025-12-29*
