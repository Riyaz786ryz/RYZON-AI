# RYZONE Wallet and Provider Billing Design

## Approved business model

RYZONE uses two separate payment flows:

1. **Customer: prepaid, pay before use.** A customer adds money to their RYZONE wallet using an approved payment gateway. The wallet balance is used to pay for AI generations. A customer must have sufficient available balance before a billable job starts.
2. **RYZONE: provider postpaid, if the provider account is eligible.** RYZONE records its AI-provider usage and pays the provider's invoice according to the provider's actual billing terms and due date. Postpaid availability, credit limits, and payment terms must be confirmed with the provider; do not assume every Google AI account supports postpaid.

These are independent flows. Customer money is collected by RYZONE; the provider bills RYZONE separately.

## Customer wallet lifecycle

- Payment gateway confirms a successful payment through a verified server-side webhook.
- Only after webhook verification does the backend credit the wallet.
- Store amounts in integer paise (not floating-point rupees).
- Maintain an append-only wallet ledger: top-up, reservation, final debit, release/refund, and manual adjustment. Every entry has a unique transaction ID and links to a user and job/payment ID.
- Never trust a balance, price, role, or payment-success flag supplied by the Android app.
- Do not credit a wallet from a client redirect or screenshot.
- Show wallet balance, pending holds, transaction history, and receipts in the app.

## Safe AI job charging

1. Authenticate the Firebase user on the backend.
2. Validate the requested feature, duration, model, and server-owned price.
3. Estimate the maximum charge and atomically reserve that amount from the user's available wallet balance.
4. Reject the request before calling the provider if the balance is insufficient.
5. Run the provider job and record provider, model, operation, job ID, timestamps, estimated cost, and final cost.
6. On success, settle the reservation using the server-calculated customer price; release any unused hold.
7. On failure or timeout, reconcile the provider result before releasing/refunding. Do not blindly refund a job that may have completed and incurred provider cost.
8. Make requests idempotent so retries cannot create duplicate jobs or double-charge customers.

## Pricing and profit accounting

For every billable operation, record separately:
- customer amount charged;
- actual provider cost;
- payment gateway fee;
- applicable tax;
- storage, rendering, and delivery costs where measurable;
- estimated contribution/profit.

Customer prices must be set per feature and duration only after measuring real provider costs. Never promise unlimited use at a fixed price without a funded quota and cost controls. Coins, if introduced later, must map to a clearly defined rupee value in the backend.

## Provider postpaid and owner protection

- Confirm in writing/console that the selected provider account has postpaid billing and understand its credit limit, invoice cycle, due date, and suspension policy.
- Reconcile backend usage records with provider billing reports/invoices; estimates are not invoices.
- Keep an owner-side monthly budget guard independent of customer wallets. Alerts are warnings; enforce a server-side pause on new billable jobs at the configured safety threshold.
- Account for delayed provider billing, in-flight jobs, retries, refunds, taxes, and currency conversion.
- If provider postpaid is unavailable, stop and ask the owner to choose an alternative billing arrangement; do not silently activate paid resources.

## Security and implementation requirements

- Keep provider API keys and payment secrets only in server-side secret storage. Never commit them to Git or embed them in the APK.
- Verify payment gateway webhook signatures server-side.
- Use atomic database transactions for wallet reservations and ledger updates.
- Apply per-user and global quotas/rate limits on the backend.
- Keep admin budget controls server-authorized; never trust a client-side `isAdmin` flag.
- Log enough information for reconciliation without logging secrets or sensitive payment data.

## Implementation status

Implemented in the repository (automated unit tests pass; not yet deployed or tested against live Firestore):
- Integer-paise wallet reservation, settlement, release, append-only ledger writes, and idempotent job handling in `cloud-backend/src/wallet.js`.
- A server-side idempotent wallet-credit primitive for a verified payment. It must only be called after a gateway webhook signature and payment status are verified; it is not exposed as a client endpoint.
- Authenticated `GET /v1/wallet` and `GET /v1/wallet/transactions` endpoints.
- Firestore index configuration for newest-first wallet ledger history.
- Flutter wallet screen showing balance, reserved amount, available amount, and recent transactions. It requires the backend URL and deployed service to work.

Still not implemented / not live:
- Payment gateway selection, checkout/order creation, signed webhook endpoint, refunds, and settlement reconciliation.
- Admin support tools and role-protected adjustments.
- Firestore emulator/concurrency testing and live Firestore verification.
- AI endpoint integration with wallet reservation and settlement. AI routes do not yet deduct customer wallet funds.
- Provider postpaid billing, invoices, owner budget enforcement, and live cost reconciliation.

Do not deploy billable services, activate payment collection, or enable paid billing without the owner's explicit approval.
