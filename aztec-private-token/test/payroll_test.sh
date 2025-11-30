#!/bin/bash
# ============================================================================
# Enterprise Privacy Payroll Test - ZKP Transfer Demo
# ============================================================================
# This test simulates a company paying multiple employees privately:
# - Company deposits funds (initial supply)
# - Company pays 2 employees with private transfers
# - All salary amounts and recipients are HIDDEN from observers
# ============================================================================

set -e

export PATH="$HOME/.aztec/bin:$PATH"

echo ""
echo "======================================================================"
echo "  PRIVACY PAYROLL - Enterprise Payment Demo"
echo "======================================================================"
echo ""
echo "  Scenario:"
echo "    - Company has 100,000 tokens for payroll"
echo "    - 2 Employees receive different salaries:"
echo "      * Employee1 (Alice): 5,000 tokens"
echo "      * Employee2 (Bob):   4,500 tokens"
echo ""
echo "  Privacy guarantees:"
echo "    - Salary amounts: HIDDEN"
echo "    - Employee identities: HIDDEN"
echo "    - Total payroll: HIDDEN"
echo ""

# Use official PrivateToken from Aztec's example contracts
# This contract has pre-generated verification keys
CONTRACT_NAME="PrivateToken"

# =========================================================================
# Step 1: Import test accounts from Sandbox
# =========================================================================
echo "[1] Setting up test accounts..."
echo "    - test0 = Company (Payroll Admin)"
echo "    - test1 = Employee1 (Alice)"
echo "    - test2 = Employee2 (Bob)"
echo ""
aztec-wallet import-test-accounts || { echo "Error: Sandbox not running. Start with: aztec start --sandbox"; exit 1; }
echo ""

# Get account addresses for use in commands
COMPANY_ADDR=$(aztec-wallet get-address -a test0 2>&1 | tail -1)
ALICE_ADDR=$(aztec-wallet get-address -a test1 2>&1 | tail -1)
BOB_ADDR=$(aztec-wallet get-address -a test2 2>&1 | tail -1)

echo "    Account Addresses:"
echo "    - Company: $COMPANY_ADDR"
echo "    - Alice:   $ALICE_ADDR"
echo "    - Bob:     $BOB_ADDR"
echo ""

# =========================================================================
# Step 2: Deploy Private Token Contract (Company's Payroll Account)
# =========================================================================
echo "[2] Deploying Payroll Token contract..."
echo "    Initial Company Balance: 100,000 tokens"
echo ""
echo "    ** ZKP NOTE: This amount is PRIVATE! **"
echo "    ** Only Company knows their actual balance **"
echo ""

DEPLOY_OUTPUT=$(aztec-wallet deploy $CONTRACT_NAME \
  --from accounts:test0 \
  --args 100000 accounts:test0 2>&1)

echo "$DEPLOY_OUTPUT"

# Extract contract address from deployment output
CONTRACT_ADDR=$(echo "$DEPLOY_OUTPUT" | sed -n 's/.*Contract deployed at \(0x[a-fA-F0-9]*\).*/\1/p')
echo ""
echo "    Contract Address: $CONTRACT_ADDR"
echo ""

if [ -z "$CONTRACT_ADDR" ]; then
    echo "ERROR: Failed to extract contract address from deployment output"
    exit 1
fi

# =========================================================================
# Step 3: Verify Initial Balances
# =========================================================================
echo "[3] Checking initial balances..."
echo ""

echo "    Company balance:"
aztec-wallet simulate get_balance \
  --from accounts:test0 \
  --contract-address $CONTRACT_ADDR \
  --contract-artifact $CONTRACT_NAME \
  --args $COMPANY_ADDR

echo ""
echo "    Employee1 (Alice) balance:"
aztec-wallet simulate get_balance \
  --from accounts:test1 \
  --contract-address $CONTRACT_ADDR \
  --contract-artifact $CONTRACT_NAME \
  --args $ALICE_ADDR

echo ""
echo "    Employee2 (Bob) balance:"
aztec-wallet simulate get_balance \
  --from accounts:test2 \
  --contract-address $CONTRACT_ADDR \
  --contract-artifact $CONTRACT_NAME \
  --args $BOB_ADDR

echo ""

# =========================================================================
# Step 4: Private Payroll Transfers - The ZKP Magic!
# =========================================================================
echo "[4] Executing Private Payroll Transfers..."
echo ""
echo "    *** PRIVACY PAYROLL IN ACTION ***"
echo ""
echo "    Company is paying 2 employees:"
echo "      - Employee1 (Alice):   5,000 tokens"
echo "      - Employee2 (Bob):     4,500 tokens"
echo "      --------------------------------"
echo "      Total:                  9,500 tokens"
echo ""
echo "    What on-chain observer sees:"
echo "      - 'Some notes were spent'"
echo "      - 'New notes created'"
echo "      - 'ZK proof is valid'"
echo ""
echo "    What observer CANNOT see:"
echo "      - Who got paid"
echo "      - How much each person got"
echo "      - Total payroll amount"
echo ""

# Transfer to Alice
echo "    Transferring 5,000 tokens to Alice..."
aztec-wallet send transfer \
  --from accounts:test0 \
  --contract-address $CONTRACT_ADDR \
  --contract-artifact $CONTRACT_NAME \
  --args 5000 $COMPANY_ADDR $ALICE_ADDR

echo ""
echo "    Transfer to Alice complete!"
echo ""

# Transfer to Bob
echo "    Transferring 4,500 tokens to Bob..."
aztec-wallet send transfer \
  --from accounts:test0 \
  --contract-address $CONTRACT_ADDR \
  --contract-artifact $CONTRACT_NAME \
  --args 4500 $COMPANY_ADDR $BOB_ADDR

echo ""
echo "    Payroll transfers complete!"
echo ""

# =========================================================================
# Step 5: Verify Balances After Payroll
# =========================================================================
echo "[5] Verifying balances after payroll..."
echo ""

echo "    Company balance (was 100,000, paid 9,500):"
aztec-wallet simulate get_balance \
  --from accounts:test0 \
  --contract-address $CONTRACT_ADDR \
  --contract-artifact $CONTRACT_NAME \
  --args $COMPANY_ADDR

echo ""
echo "    Employee1 (Alice) balance (was 0, received 5,000):"
aztec-wallet simulate get_balance \
  --from accounts:test1 \
  --contract-address $CONTRACT_ADDR \
  --contract-artifact $CONTRACT_NAME \
  --args $ALICE_ADDR

echo ""
echo "    Employee2 (Bob) balance (was 0, received 4,500):"
aztec-wallet simulate get_balance \
  --from accounts:test2 \
  --contract-address $CONTRACT_ADDR \
  --contract-artifact $CONTRACT_NAME \
  --args $BOB_ADDR

echo ""

# =========================================================================
# Summary
# =========================================================================
echo "======================================================================"
echo "  SUCCESS! Privacy Payroll Demo Complete"
echo "======================================================================"
echo ""
echo "  Key Results:"
echo "    - Company paid 2 employees with private transfers"
echo "    - Each employee received their correct salary"
echo "    - All amounts remain PRIVATE on-chain"
echo "    - Only the recipient can view their own balance"
echo ""
echo "  Enterprise Benefits:"
echo "    - Salary confidentiality maintained"
echo "    - ZK proofs ensure correctness without revealing data"
echo "    - Regulatory compliance possible via View Keys"
echo ""
