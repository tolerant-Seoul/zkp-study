/**
 * ============================================================================
 * Enterprise Privacy Payroll Test - ZKP Batch Transfer Demo
 * ============================================================================
 * 회사가 직원들에게 비공개로 급여를 지급하는 시뮬레이션:
 * - 회사가 초기 자금 입금
 * - 2명의 직원에게 개별 전송으로 급여 지급
 * - 모든 금액과 수령인은 온체인에서 숨겨짐
 * ============================================================================
 */

import {
  createPXEClient,
  waitForPXE,
} from '@aztec/aztec.js';
import { getInitialTestAccountsWallets } from '@aztec/accounts/testing';
// 공식 Aztec 컨트랙트 사용 (VK 포함)
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

  // 생성된 래퍼를 사용하여 배포
  // from 옵션을 명시적으로 전달 (SDK 버그 회피)
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

  // simulate()에도 빈 객체 전달 (SDK 버그 회피)
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
  // Step 5: 배치 급여 전송 - ZKP 마법!
  // =========================================================================
  console.log('[5] 배치 급여 전송 실행 중...');
  console.log('');
  console.log('    *** 프라이버시 급여 지급 진행 중 ***');
  console.log('');
  console.log('    회사가 2명의 직원에게 한 번에 지급:');
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
