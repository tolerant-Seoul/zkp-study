#!/bin/bash
# ============================================================================
# Private Token Contract Test - ZKP (Zero Knowledge Proof) Demo
# ============================================================================

set -e

export PATH="$HOME/.aztec/bin:$PATH"

echo ""
echo "======================================================================"
echo "  AZTEC PRIVATE TOKEN - ZKP (Zero Knowledge Proof) DEMO"
echo "======================================================================"
echo ""

# Contract artifact path
CONTRACT_ARTIFACT="../private_token/target/private_token-PrivateToken.json"

# =========================================================================
# Step 1: Import test accounts from Sandbox
# =========================================================================
echo "[1] Importing test accounts from Sandbox..."
aztec-wallet import-test-accounts || { echo "Error: Sandbox not running. Start with: aztec start --sandbox"; exit 1; }
echo ""

# =========================================================================
# Step 2: Show aliases (accounts)
# =========================================================================
echo "[2] Getting test accounts..."
aztec-wallet get-alias
echo ""

# =========================================================================
# Step 3: Deploy Private Token Contract
# =========================================================================
echo "[3] Deploying Private Token contract..."
echo "    Initial supply: 1000 tokens"
echo "    Owner: Alice (test0)"
echo ""
echo "    ** ZKP NOTE: The initial supply (1000) is PRIVATE! **"
echo "    ** On-chain, only a commitment to this value exists **"
echo ""

# Deploy: constructor(initial_supply: u64, owner: AztecAddress)
DEPLOY_OUTPUT=$(aztec-wallet deploy $CONTRACT_ARTIFACT \
  --from accounts:test0 \
  --args 1000 accounts:test0 \
  --alias contracts:private_token 2>&1)

echo "$DEPLOY_OUTPUT"

# Extract contract address
CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "Contract deployed at" | awk '{print $4}')
echo ""
echo "    Contract Address: $CONTRACT_ADDRESS"
echo ""

# =========================================================================
# Step 4: Check balances
# =========================================================================
echo "[4] Checking balances..."
echo ""
echo "    ** ZKP NOTE: Only the owner can read their own balance **"
echo ""

echo "    Checking Alice's balance..."
aztec-wallet simulate get_balance \
  --from accounts:test0 \
  --contract-address $CONTRACT_ADDRESS \
  --contract-artifact $CONTRACT_ARTIFACT \
  --args accounts:test0

echo ""
echo "    Checking Bob's balance..."
aztec-wallet simulate get_balance \
  --from accounts:test1 \
  --contract-address $CONTRACT_ADDRESS \
  --contract-artifact $CONTRACT_ARTIFACT \
  --args accounts:test1

echo ""

# =========================================================================
# Step 5: Private Transfer - The ZKP Magic!
# =========================================================================
echo "[5] Private Transfer: Alice -> Bob (300 tokens)"
echo ""
echo "    ** THIS IS WHERE ZKP MAGIC HAPPENS! **"
echo ""
echo "    What ZK proof verifies:"
echo "    - Alice has >= 300 tokens (without revealing actual balance)"
echo "    - Alice owns the notes being spent (valid signature)"
echo "    - Total tokens conserved (no creation/destruction)"
echo ""
echo "    What an observer CANNOT see:"
echo "    - Sender, Receiver, Amount - ALL HIDDEN!"
echo ""

# Transfer: transfer(amount: u64, sender: AztecAddress, recipient: AztecAddress)
aztec-wallet send transfer \
  --from accounts:test0 \
  --contract-address $CONTRACT_ADDRESS \
  --contract-artifact $CONTRACT_ARTIFACT \
  --args 300 accounts:test0 accounts:test1

echo ""
echo "    Transfer complete!"
echo ""

# =========================================================================
# Step 6: Verify balances after transfer
# =========================================================================
echo "[6] Checking balances after transfer..."

echo "    Alice's balance (was 1000):"
aztec-wallet simulate get_balance \
  --from accounts:test0 \
  --contract-address $CONTRACT_ADDRESS \
  --contract-artifact $CONTRACT_ARTIFACT \
  --args accounts:test0

echo ""
echo "    Bob's balance (was 0):"
aztec-wallet simulate get_balance \
  --from accounts:test1 \
  --contract-address $CONTRACT_ADDRESS \
  --contract-artifact $CONTRACT_ARTIFACT \
  --args accounts:test1

echo ""

# =========================================================================
# Step 7: Mint more tokens
# =========================================================================
echo "[7] Minting 500 more tokens to Bob..."

# Mint: mint(amount: u64, owner: AztecAddress)
aztec-wallet send mint \
  --from accounts:test0 \
  --contract-address $CONTRACT_ADDRESS \
  --contract-artifact $CONTRACT_ARTIFACT \
  --args 500 accounts:test1

echo ""
echo "    Bob's final balance:"
aztec-wallet simulate get_balance \
  --from accounts:test1 \
  --contract-address $CONTRACT_ADDRESS \
  --contract-artifact $CONTRACT_ARTIFACT \
  --args accounts:test1

echo ""

# =========================================================================
# Summary
# =========================================================================
echo "======================================================================"
echo "  SUCCESS! ZKP Demo Complete"
echo "======================================================================"
echo ""
echo "  All transfers were private - sender, receiver, amounts hidden!"
echo ""
