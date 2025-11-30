// ============================================================================
// Private Token Contract
// ============================================================================
// This contract demonstrates ZKP (Zero Knowledge Proofs) in action:
//
// 1. PRIVACY: Balances are stored as encrypted "notes"
//    - Only the owner can decrypt and read their balance
//    - Outsiders see nothing
//
// 2. UTXO MODEL: Like Bitcoin, but private
//    - Alice has: Note(50) + Note(30) + Note(20) = 100 tokens
//    - Transfer 70 to Bob:
//      * Destroy Note(50), Note(30)
//      * Create Note(70) for Bob
//      * Create Note(10) for Alice (change)
//
// 3. ZK PROOF: Proves validity without revealing data
//    - "I have enough balance" (without showing actual balance)
//    - "I own these notes" (without revealing which notes)
//    - "No tokens created/destroyed" (conservation law)
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
    // Storage
    // ========================================================================
    // balances: Map<Address -> EasyPrivateUint>
    //
    // EasyPrivateUint internally uses encrypted "notes" to store values.
    // Each user's balance = sum of all their notes
    // Notes are ONLY readable by the owner (encrypted with owner's key)
    // ========================================================================

    #[storage]
    struct Storage<Context> {
        balances: Map<AztecAddress, EasyPrivateUint<Context>, Context>,
    }

    // ========================================================================
    // Constructor
    // ========================================================================
    // Creates initial token supply for the owner.
    // This is a PRIVATE function - the initial_supply amount is hidden!
    //
    // ZK Proof generated:
    // - "A valid note was created for 'owner'"
    // - Amount is NOT revealed on-chain
    // ========================================================================

    #[private]
    #[initializer]
    fn constructor(initial_supply: u64, owner: AztecAddress) {
        let balances = storage.balances;
        balances.at(owner).add(initial_supply, owner);
    }

    // ========================================================================
    // Mint - Create new tokens
    // ========================================================================
    // Mints `amount` tokens to `owner`
    //
    // In production, you'd add admin checks here.
    // For this demo, anyone can mint (to simplify testing).
    //
    // What happens:
    // 1. New encrypted note created with `amount`
    // 2. Note added to owner's balance set
    // 3. ZK proof proves note is valid
    // ========================================================================

    #[private]
    fn mint(amount: u64, owner: AztecAddress) {
        let balances = storage.balances;
        balances.at(owner).add(amount, owner);
    }

    // ========================================================================
    // Transfer - The ZKP Magic!
    // ========================================================================
    // Transfers `amount` from `sender` to `recipient`
    //
    // This is where zero-knowledge proofs shine:
    //
    // WHAT THE ZK CIRCUIT PROVES:
    // 1. sender has notes totaling >= amount (has enough balance)
    // 2. sender owns those notes (has the private key)
    // 3. new notes sum equals old notes sum (no tokens created/destroyed)
    //
    // WHAT GOES ON-CHAIN:
    // - Nullifiers for spent notes (prevents double-spending)
    // - Commitments for new notes (encrypted values)
    // - The ZK proof itself
    //
    // WHAT AN OBSERVER SEES:
    // - "Some notes were spent"
    // - "Some notes were created"
    // - "The proof is valid"
    //
    // WHAT AN OBSERVER CANNOT SEE:
    // - Who sent (sender address hidden)
    // - Who received (recipient address hidden)
    // - How much (amount hidden)
    // - Account balances (notes are encrypted)
    // ========================================================================

    #[private]
    fn transfer(amount: u64, sender: AztecAddress, recipient: AztecAddress) {
        let balances = storage.balances;

        // Subtract from sender - internally:
        // 1. Finds notes totaling >= amount
        // 2. Creates nullifiers (marks notes as spent)
        // 3. Creates change note if needed
        balances.at(sender).sub(amount, sender);

        // Add to recipient - internally:
        // 1. Creates new encrypted note
        // 2. Only recipient can decrypt it
        balances.at(recipient).add(amount, recipient);
    }

    // ========================================================================
    // Batch Transfer - Enterprise Payroll Use Case
    // ========================================================================
    // Transfers different amounts to multiple recipients in a single call.
    // Perfect for salary payments where:
    // - Company pays multiple employees at once
    // - Each employee receives different amount
    // - All amounts and recipients are HIDDEN
    //
    // Example: Company pays 3 employees
    //   batch_transfer(
    //     sender: Company,
    //     recipients: [Alice, Bob, Charlie],
    //     amounts: [5000, 4500, 6000]
    //   )
    //
    // On-chain observer sees:
    // - "Some notes were spent"
    // - "Multiple notes were created"
    // - Number of recipients is visible (3 in this case)
    //
    // Observer CANNOT see:
    // - Who received what amount
    // - Total payroll amount
    // - Individual salaries
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

        // Deduct total from sender
        balances.at(sender).sub(total, sender);

        // Add to each recipient
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

        // Deduct total from sender
        balances.at(sender).sub(total, sender);

        // Add to each recipient
        balances.at(recipient1).add(amount1, recipient1);
        balances.at(recipient2).add(amount2, recipient2);
        balances.at(recipient3).add(amount3, recipient3);
    }

    // ========================================================================
    // Get Balance - Read-only query
    // ========================================================================
    // Returns the balance of `owner`
    //
    // This is an "unconstrained" function:
    // - Runs off-chain (no gas cost)
    // - Only the owner can see their actual balance
    // - Others would get an error (can't decrypt the notes)
    // ========================================================================

    #[utility]
    unconstrained fn get_balance(owner: AztecAddress) -> Field {
        storage.balances.at(owner).get_value()
    }
}
