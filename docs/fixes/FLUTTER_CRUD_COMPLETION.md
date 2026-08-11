# Flutter CRUD Completion Report

## 1. Contract CRUD Matrix & Implementation

- **Create Contract**: `ContractFormPage` sectioned form (title, linked project, freelancer, total amount, start/end dates, milestones, terms).
- **Edit Contract**: Pre-filled `ContractFormPage` connected to `ProjectRepository.updateContract`.
- **View Contract**: `ContractDetailsPage` displaying hero stats, progress bar, timeline of milestones, status chips.
- **Activate Contract**: Status action calling `PATCH /client/contracts/:id/activate` with confirmation dialog.
- **Complete Contract**: Status action calling `PATCH /client/contracts/:id/complete` with confirmation dialog.
- **Cancel Contract**: Destructive status action calling `PATCH /client/contracts/:id/cancel` with confirmation dialog.

## 2. Investment CRUD Matrix & Implementation

- **View Investment**: `_DealCard` and deal room views displaying startup logo, stage, offer amount, equity %, documents, and NDA badge.
- **Edit Investment**: `InvestmentEditSheet` modal bottom sheet allowing investors to update offer amount, equity %, message, and status.
- **Status Update / Withdraw Offer**: Action calling `PUT /investor/investments/:id/status` with `AppConfirmDialog`.
