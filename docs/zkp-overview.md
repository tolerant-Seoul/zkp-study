## ZKP(Zero knowledge Proof) 기본 개념

ZKP ?

"나는 비밀을 알고 있다"를 증명하면서, 그 비밀 자체는 공개하지 않는 기술

실생활 예시: 동굴 문제

         입구
          │
      ┌───┴───┐
      │       │
    A 길     B 길
      │       │
      └───┬───┘
        마법문
       (비밀번호 필요)

1. Alice는 마법문의 비밀번호를 안다고 주장
2. Bob은 입구에서 기다림
3. Alice가 랜덤하게 A 또는 B 길로 들어감
4. Bob이 "A 길로 나와!" 또는 "B 길로 나와!" 요청
5. Alice가 비밀번호를 알면 → 항상 요청대로 나올 수 있음
6. 모르면 → 50% 확률로 실패

20번 반복해서 매번 성공하면 → 비밀번호를 알고 있음이 증명됨 (비밀번호 노출 없이!)

Aztec에서의 ZKP 적용

일반 이더리움:
"Alice가 Bob에게 100 ETH 보냄" → 모든 정보가 공개됨

Aztec (ZKP 적용):
"누군가가 누군가에게 무언가를 보냄" + ZK 증명: "이 거래는 유효함 (잔액 충분, 서명 유효)"
→ 검증자는 거래가 유효한지만 알고, 상세 내용은 모름

---

## Install Aztec toolchain

```
curl -s https://install.aztec.network | bash 2>&1 | tail -20

export PATH="$HOME/.aztec/bin:$PATH" && aztec --version 2>&1 | head -5
```

## Create project directory

```
mkdir -p ~/aztec-private-token
ls -la ~/aztec-private-token
```

## Initialize Noir contract project

```
cd ~/aztec-private-token
export PATH="$HOME/.aztec/bin:$PATH" && aztec-nargo new --contract private_token
```

## Implement Private Token Contract by Noir

### Nargo.toml에 Aztec 의존성을 추가

```
# private_token/Nargo.toml

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

### Private Token Contract 작성

```
// ============================================================================
// 프라이빗 토큰 컨트랙트 (Private Token Contract)
// ============================================================================
// 이 컨트랙트는 ZKP(영지식 증명)를 사용하여:
// 1. 누가 얼마를 가지고 있는지 숨김 (프라이빗 잔액)
// 2. 누가 누구에게 보냈는지 숨김 (프라이빗 전송)
// 3. 하지만 모든 거래가 유효함은 증명됨
// ============================================================================

// Aztec 라이브러리 임포트
use dep::aztec::macros::aztec;

#[aztec]
pub contract PrivateToken {
    // ========================================================================
    // 임포트 섹션
    // ========================================================================

    // 핵심 Aztec 프리루드 - 기본 타입들
    use dep::aztec::prelude::{
        AztecAddress,      // Aztec 네트워크 주소 타입
        Map,               // 키-값 매핑 (Solidity의 mapping과 유사)
        PrivateSet,        // 프라이빗 상태를 저장하는 집합
        PublicMutable,     // 공개적으로 변경 가능한 상태
    };

    // 프라이빗 컨텍스트 - ZK 증명 생성에 필요
    use dep::aztec::context::private_context::PrivateContext;

    // 매크로들 - 컴파일 타임에 ZK 회로 생성
    use dep::aztec::macros::{
        storage::storage,    // 스토리지 정의용
        functions::{
            private,         // 프라이빗 함수 (ZK 증명 생성)
            public,          // 퍼블릭 함수 (온체인 실행)
            initializer,     // 컨트랙트 초기화 함수
            view,            // 읽기 전용 함수
        },
    };

    // UintNote - 프라이빗 잔액을 저장하는 "노트"
    // Note: Aztec에서 프라이빗 상태는 "노트"라는 암호화된 데이터로 저장됨
    use dep::uint_note::uint_note::UintNote;

    // ========================================================================
    // 스토리지 정의
    // ========================================================================
    //
    // ZKP 핵심 개념:
    // - "balances"는 Map<AztecAddress, PrivateSet<UintNote>>
    // - 각 사용자의 잔액은 여러 개의 "노트"로 구성됨
    // - 노트는 암호화되어 있어 오직 소유자만 읽을 수 있음
    // - 전송 시: 기존 노트 파괴 → 새 노트 생성 (UTXO 모델)
    //
    // 예시:
    //   Alice의 잔액 = Note(50) + Note(30) + Note(20) = 100 토큰
    //   Bob에게 70 전송 시:
    //     - Note(50) 파괴, Note(30) 파괴
    //     - Bob에게 Note(70) 생성
    //     - Alice에게 Note(10) 생성 (거스름돈)
    // ========================================================================

    #[storage]
    struct Storage<Context> {
        // 관리자 주소 (민팅 권한 보유)
        admin: PublicMutable<AztecAddress, Context>,

        // 총 발행량 (공개 정보)
        total_supply: PublicMutable<u64, Context>,

        // 프라이빗 잔액 - 핵심!
        // Map: 주소 → PrivateSet<UintNote>
        // 각 사용자의 잔액은 암호화된 노트들의 집합
        balances: Map<AztecAddress, PrivateSet<UintNote, Context>, Context>,
    }

    // ========================================================================
    // 초기화 함수 (Constructor)
    // ========================================================================

    /// 컨트랙트 초기화 - 관리자 설정
    ///
    /// 호출자가 관리자로 설정되며, 민팅 권한을 갖게 됨
    #[public]
    #[initializer]
    fn constructor(admin: AztecAddress) {
        storage.admin.write(admin);
        storage.total_supply.write(0);
    }

    // ========================================================================
    // 프라이빗 민트 함수
    // ========================================================================
    //
    // ZKP가 적용되는 방식:
    // 1. 이 함수가 호출되면 ZK 증명이 생성됨
    // 2. 증명 내용: "호출자가 admin과 동일하다"
    // 3. 체인에는 증명만 기록되고, 실제 값들은 숨겨짐
    // ========================================================================

    /// 프라이빗 민트 - 새 토큰을 생성하여 지정 주소에 할당
    ///
    /// # Arguments
    /// * `to` - 토큰을 받을 주소
    /// * `amount` - 민트할 양
    ///
    /// # Privacy
    /// - `to`와 `amount`는 프라이빗 (외부에서 볼 수 없음)
    /// - ZK 증명으로 "관리자가 유효한 민트를 했다"만 증명됨
    #[private]
    fn mint_private(to: AztecAddress, amount: u64) {
        // 1. 관리자 확인 (ZK 증명으로 검증됨)
        let admin = storage.admin.read();
        assert(context.msg_sender() == admin, "Only admin can mint");

        // 2. 프라이빗 노트 생성
        // - 새 UintNote가 생성되어 `to` 주소의 PrivateSet에 추가됨
        // - 이 노트는 암호화되어 오직 `to`만 읽을 수 있음
        let to_balance = storage.balances.at(to);
        to_balance.insert(&mut UintNote::new(amount as u128, to));

        // 3. 총 발행량 업데이트 (공개 상태)
        // enqueue_call: 프라이빗 실행 후 퍼블릭 함수 호출 예약
        PrivateToken::at(context.this_address())
            ._increase_total_supply(amount)
            .enqueue(&mut context);
    }

    /// 내부 함수: 총 발행량 증가 (퍼블릭)
    #[public]
    #[internal]
    fn _increase_total_supply(amount: u64) {
        let current = storage.total_supply.read();
        storage.total_supply.write(current + amount);
    }

    // ========================================================================
    // 프라이빗 전송 함수 - ZKP의 핵심!
    // ========================================================================
    //
    // 이것이 ZKP의 마법이 일어나는 곳입니다:
    //
    // 1. Alice가 Bob에게 70 토큰을 보내려 함
    // 2. ZK 회로가 다음을 증명:
    //    - Alice의 노트 합계 >= 70 (잔액 충분)
    //    - Alice가 해당 노트의 소유자임 (서명 유효)
    //    - 새로 생성된 노트의 합 = 기존 노트의 합 (토큰 보존)
    // 3. 체인에 기록되는 것:
    //    - "노트 X, Y가 파괴됨" (어떤 값인지는 모름)
    //    - "노트 A, B가 생성됨" (어떤 값인지는 모름)
    //    - ZK 증명 (위 조건들이 만족됨을 증명)
    // 4. 외부 관찰자가 아는 것: "누군가가 누군가에게 무언가를 보냄"
    //    모르는 것: 누가, 누구에게, 얼마를
    // ========================================================================

    /// 프라이빗 전송 - 토큰을 다른 주소로 전송
    ///
    /// # Arguments
    /// * `to` - 받는 주소 (프라이빗)
    /// * `amount` - 전송 금액 (프라이빗)
    ///
    /// # How it works (UTXO 모델)
    /// 1. 보내는 사람의 노트들에서 `amount` 만큼 선택
    /// 2. 선택된 노트들을 "nullify" (무효화/파괴)
    /// 3. 받는 사람에게 새 노트 생성 (amount)
    /// 4. 보내는 사람에게 잔돈 노트 생성 (선택 노트 합 - amount)
    #[private]
    fn transfer(to: AztecAddress, amount: u64) {
        let sender = context.msg_sender();

        // 1. 보내는 사람의 잔액에서 차감
        // sub_assign: 내부적으로 적절한 노트를 선택하고 파괴함
        let sender_balance = storage.balances.at(sender);
        sender_balance.sub_assign(&mut context, sender, amount as u128);

        // 2. 받는 사람에게 새 노트 생성
        // 이 노트는 암호화되어 오직 `to`만 볼 수 있음
        let to_balance = storage.balances.at(to);
        to_balance.insert(&mut UintNote::new(amount as u128, to));
    }

    // ========================================================================
    // 조회 함수들
    // ========================================================================

    /// 프라이빗 잔액 조회
    ///
    /// # Privacy
    /// - 오직 자신의 잔액만 조회 가능
    /// - 다른 사람의 잔액은 볼 수 없음 (노트가 암호화되어 있음)
    #[private]
    #[view]
    fn get_balance(owner: AztecAddress) -> u64 {
        // owner의 모든 노트 합계를 계산
        // 호출자가 owner가 아니면 노트를 복호화할 수 없어 실패
        let balance_set = storage.balances.at(owner);
        balance_set.balance_of() as u64
    }

    /// 총 발행량 조회 (공개 정보)
    #[public]
    #[view]
    fn get_total_supply() -> u64 {
        storage.total_supply.read()
    }

    /// 관리자 주소 조회 (공개 정보)
    #[public]
    #[view]
    fn get_admin() -> AztecAddress {
        storage.admin.read()
    }
}
```

### Compile Contract

```
cd ~/aztec-private-token/private_token
export PATH="$HOME/.aztec/bin:$PATH" && aztec-nargo compile
```

## Aztec Sandbox로 실제 테스트

### Sandbox 실행

```
docker run -it --rm -p 8080:8080 aztecprotocol/aztec:2.1.5 start --sandbox
```

### Contract 배포

```
aztec deploy ./target/private_token-PrivateToken.json --args <initial_supply> <owner_address>
```

### 함수 호출 테스트

```
  aztec call <contract_address> mint --args <amount> <owner_address>
  aztec call <contract_address> transfer --args <amount> <sender> <recipient>
  aztec call <contract_address> get_balance --args <owner_address>
```

### Project 설정

```
cd ~/aztec-private-token
npm init -y
npm install @aztec/aztec.js@2.1.5 @types/node @aztec/accounts@2.1.5 typescript tsx
```

### tsconfig.json 생성

```
  cat > /Users/kevin/aztec-private-token/tsconfig.json << 'EOF'
  {
    "compilerOptions": {
      "target": "ES2022",
      "module": "NodeNext",
      "moduleResolution": "NodeNext",
      "esModuleInterop": true,
      "resolveJsonModule": true,
      "strict": true,
      "skipLibCheck": true
    }
  }
  EOF
```

### TypeScript 테스트 작성

```
  import { createPXEClient, AccountWallet, Contract } from '@aztec/aztec.js';

  const pxe = createPXEClient('http://localhost:8080');
  const wallet = await AccountWallet.create(pxe);

  // 배포
  const contract = await Contract.deploy(wallet, PrivateTokenArtifact, [1000n, wallet.getAddress()]).send().deployed();

  // 테스트
  await contract.methods.mint(100n, wallet.getAddress()).send().wait();
  const balance = await contract.methods.get_balance(wallet.getAddress()).simulate();
```
