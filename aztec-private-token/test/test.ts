/**
 * ============================================================================
 * Private Token Contract Test - ZKP (Zero Knowledge Proof) Demo
 * ============================================================================
 */

import {
  createPXEClient,
  waitForPXE,
  Contract,
  loadContractArtifact,
} from '@aztec/aztec.js';
import { getInitialTestAccountsWallets } from '@aztec/accounts/testing';
import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// PXE URL (default sandbox)
const PXE_URL = process.env.PXE_URL || 'http://localhost:8080';

/**
 * Load compiled contract artifact
 */
function getContractArtifact() {
  const artifactPath = resolve(__dirname, '../private_token/target/private_token-PrivateToken.json');
  const artifactJson = JSON.parse(readFileSync(artifactPath, 'utf-8'));
  return loadContractArtifact(artifactJson);
}

async function main() {
  console.log('');
  console.log('='.repeat(70));
  console.log('  AZTEC PRIVATE TOKEN - ZKP (Zero Knowledge Proof) DEMO');
  console.log('='.repeat(70));
  console.log('');

  // =========================================================================
  // Step 1: Connect to PXE (Private Execution Environment)
  // =========================================================================
  console.log('[1] Connecting to Aztec PXE...');
  const pxe = createPXEClient(PXE_URL);
  await waitForPXE(pxe);
  console.log('    Connected to PXE at', PXE_URL);
  console.log('');

  // =========================================================================
  // Step 2: Get test wallets from Sandbox (pre-funded)
  // =========================================================================
  console.log('[2] Getting test wallets from Sandbox...');
  const wallets = await getInitialTestAccountsWallets(pxe);

  if (wallets.length < 2) {
    throw new Error('Need at least 2 test accounts. Make sure sandbox is running with test accounts.');
  }

  const alice = wallets[0];
  const bob = wallets[1];

  console.log('    Alice address:', alice.getAddress().toString());
  console.log('    Bob address:', bob.getAddress().toString());
  console.log('');

  // =========================================================================
  // Step 3: Deploy Private Token Contract
  // =========================================================================
  console.log('[3] Deploying Private Token contract...');
  const artifact = getContractArtifact();

  const INITIAL_SUPPLY = 1000n;
  console.log('    Initial supply:', INITIAL_SUPPLY, 'tokens');
  console.log('    Owner: Alice');

  // Deploy with initial supply going to Alice
  const contract = await Contract.deploy(alice, artifact, [INITIAL_SUPPLY, alice.getAddress()])
    .send()
    .deployed();

  console.log('    Contract deployed at:', contract.address.toString());
  console.log('');
  console.log('    ** ZKP NOTE: The initial supply (1000) is PRIVATE! **');
  console.log('    ** On-chain, only a commitment to this value exists **');
  console.log('');

  // =========================================================================
  // Step 4: Check Alice's balance (Private operation)
  // =========================================================================
  console.log('[4] Checking balances...');
  console.log('');
  console.log('    ** ZKP NOTE: Only the owner can read their own balance **');
  console.log('');

  const aliceBalance = await contract.methods.get_balance(alice.getAddress()).simulate();
  console.log('    Alice balance:', aliceBalance.toString(), 'tokens');

  const bobBalance = await contract.methods.get_balance(bob.getAddress()).simulate();
  console.log('    Bob balance:', bobBalance.toString(), 'tokens');
  console.log('');

  // =========================================================================
  // Step 5: Private Transfer - The ZKP Magic!
  // =========================================================================
  console.log('[5] Private Transfer: Alice -> Bob (300 tokens)');
  console.log('');
  console.log('    ** THIS IS WHERE ZKP MAGIC HAPPENS! **');
  console.log('');
  console.log('    What ZK proof verifies:');
  console.log('    - Alice has >= 300 tokens (without revealing actual balance)');
  console.log('    - Alice owns the notes being spent (valid signature)');
  console.log('    - Total tokens conserved (no creation/destruction)');
  console.log('');
  console.log('    What an observer CANNOT see:');
  console.log('    - Sender, Receiver, Amount - ALL HIDDEN!');
  console.log('');

  const TRANSFER_AMOUNT = 300n;

  // Alice transfers to Bob
  const aliceContract = await Contract.at(contract.address, artifact, alice);
  await aliceContract.methods
    .transfer(TRANSFER_AMOUNT, alice.getAddress(), bob.getAddress())
    .send()
    .wait();

  console.log('    Transfer complete!');
  console.log('');

  // =========================================================================
  // Step 6: Verify balances after transfer
  // =========================================================================
  console.log('[6] Checking balances after transfer...');

  const aliceBalanceAfter = await aliceContract.methods.get_balance(alice.getAddress()).simulate();
  console.log('    Alice balance:', aliceBalanceAfter.toString(), 'tokens (was 1000)');

  const bobContract = await Contract.at(contract.address, artifact, bob);
  const bobBalanceAfter = await bobContract.methods.get_balance(bob.getAddress()).simulate();
  console.log('    Bob balance:', bobBalanceAfter.toString(), 'tokens (was 0)');
  console.log('');

  // =========================================================================
  // Step 7: Mint more tokens
  // =========================================================================
  console.log('[7] Minting 500 more tokens to Bob...');

  await aliceContract.methods.mint(500n, bob.getAddress()).send().wait();

  const bobFinalBalance = await bobContract.methods.get_balance(bob.getAddress()).simulate();
  console.log('    Bob final balance:', bobFinalBalance.toString(), 'tokens');
  console.log('');

  // =========================================================================
  // Summary
  // =========================================================================
  console.log('='.repeat(70));
  console.log('  SUCCESS! ZKP Demo Complete');
  console.log('='.repeat(70));
  console.log('');
  console.log('  All transfers were private - sender, receiver, amounts hidden!');
  console.log('');
}

main().catch((error) => {
  console.error('Error:', error);
  process.exit(1);
});
