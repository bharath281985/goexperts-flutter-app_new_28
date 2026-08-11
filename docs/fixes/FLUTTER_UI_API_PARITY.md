# Flutter UI ↔ API Parity Report

## 5 UI-Missing APIs Connected to Full UI Parity

1. **Contract Create/Edit UI (`ContractFormPage`)**:
   - Sectioned contract form (Overview, Financials, Milestones, Terms).
   - Bottom sticky action bar with "Save Contract".
   - Direct integration with `ProjectRepository.createContract` & `updateContract`.

2. **Investment Edit UI (`InvestmentEditSheet`)**:
   - Bottom sheet for editing offer amount, equity percentage, message, and status.
   - Status actions with confirmation dialogs ("Withdraw Offer", "Update Status").
   - Direct integration with `InvestorRepository.updateInvestment`.

3. **Portfolio Dedicated Route (`/freelancer/portfolio`)**:
   - Registered `/freelancer/portfolio` route in `AppRouter`.
   - Wired dedicated portfolio list and form views.

4. **Withdrawal Request Flow (`WithdrawalRequestSheet`)**:
   - Bottom sheet with Bank / UPI selection, balance checks, and validation.
   - Wired to `WalletRepository.requestWithdrawal`.

5. **Investor Due Diligence Persistence**:
   - Wired due diligence checklist items to API persistence layer.
