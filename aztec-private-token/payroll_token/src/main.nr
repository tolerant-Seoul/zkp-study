// ============================================================================
// Payroll Token Contract - Enterprise Privacy Payroll
// ============================================================================
// This contract enables private salary payments.
// All salary amounts and recipients are HIDDEN from observers.
// ============================================================================

use dep::aztec::macros::aztec;

#[aztec]
pub contract PayrollToken {
    use dep::aztec::macros::{
        functions::{initializer, private, utility},
        storage::storage
    };
    use dep::aztec::{protocol_types::address::AztecAddress, state_vars::Map};
    use dep::easy_private_state::EasyPrivateUint;

    #[storage]
    struct Storage<Context> {
        balances: Map<AztecAddress, EasyPrivateUint<Context>, Context>,
    }

    // Initialize with company's payroll budget
    #[private]
    #[initializer]
    fn constructor(initial_supply: u64, owner: AztecAddress) {
        let balances = storage.balances;
        balances.at(owner).add(initial_supply, owner);
    }

    // Mint additional tokens (e.g., monthly payroll budget)
    #[private]
    fn mint(amount: u64, owner: AztecAddress) {
        let balances = storage.balances;
        balances.at(owner).add(amount, owner);
    }

    // Single transfer - for individual salary payment
    #[private]
    fn transfer(amount: u64, sender: AztecAddress, recipient: AztecAddress) {
        let balances = storage.balances;
        balances.at(sender).sub(amount, sender);
        balances.at(recipient).add(amount, recipient);
    }

    // Check balance (only owner can read)
    #[utility]
    unconstrained fn get_balance(owner: AztecAddress) -> Field {
        storage.balances.at(owner).get_value()
    }
}
