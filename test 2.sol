#[program]
mod escrow {
    use super::*;

    #[state]
    pub struct Escrow {
        pub owner: Pubkey,
        pub release_time: i64,
        pub balances: HashMap<Pubkey, u64>,
    }

    impl Escrow {
        pub fn new(ctx: Context<Initialize>, release_time: i64) -> ProgramResult {
            let escrow = &mut ctx.accounts.escrow;
            escrow.owner = *ctx.accounts.owner.key;
            escrow.release_time = release_time;
            Ok(())
        }

        pub fn deposit(ctx: Context<Deposit>, amount: u64) -> ProgramResult {
            let escrow = &mut ctx.accounts.escrow;
            escrow.balances.insert(*ctx.accounts.depositor.key, amount);
            Ok(())
        }

        pub fn withdraw(ctx: Context<Withdraw>) -> ProgramResult {
            let escrow = &mut ctx.accounts.escrow;
            let owner = ctx.accounts.owner.key;
            let balance = escrow.balances.get(&owner).ok_or(ErrorCode::NoBalance)?;
            **ctx.accounts.owner.try_borrow_mut_lamports()? += *balance;
            escrow.balances.remove(&owner);
            Ok(())
        }

        pub fn withdraw_as_depositor(ctx: Context<WithdrawAsDepositor>) -> ProgramResult {
            let escrow = &mut ctx.accounts.escrow;
            let depositor = ctx.accounts.depositor.key;
            let balance = escrow.balances.get(&depositor).ok_or(ErrorCode::NoBalance)?;
            **ctx.accounts.depositor.try_borrow_mut_lamports()? += *balance;
            escrow.balances.remove(&depositor);
            Ok(())
        }
    }

    #[derive(Accounts)]
    pub struct Initialize<'info> {
        #[account(init, payer = owner, space = 256)]
        pub escrow: ProgramAccount<'info, Escrow>,
        pub owner: AccountInfo<'info>,
        pub system_program: AccountInfo<'info>,
    }

    #[derive(Accounts)]
    pub struct Deposit<'info> {
        #[account(mut)]
        pub escrow: ProgramAccount<'info, Escrow>,
        pub depositor: AccountInfo<'info>,
    }

    #[derive(Accounts)]
    pub struct Withdraw<'info> {
        #[account(mut)]
        pub escrow: ProgramAccount<'info, Escrow>,
        pub owner: AccountInfo<'info>,
        pub system_program: AccountInfo<'info>,
    }

    #[derive(Accounts)]
    pub struct WithdrawAsDepositor<'info> {
        #[account(mut)]
        pub escrow: ProgramAccount<'info, Escrow>,
        pub depositor: AccountInfo<'info>,
    }

    #[error]
    pub enum ErrorCode {
        #[msg("No balance for withdrawal")]
        NoBalance,
    }
}
