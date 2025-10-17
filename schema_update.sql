-- Step 1: Add Primary Keys and NOT NULL constraints if missing
ALTER TABLE customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);

ALTER TABLE accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);

ALTER TABLE transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);

-- Ensure NOT NULL constraints
ALTER TABLE customers
    ALTER COLUMN id SET NOT NULL,
    ALTER COLUMN name SET NOT NULL,
    ALTER COLUMN email SET NOT NULL;

ALTER TABLE accounts
    ALTER COLUMN id SET NOT NULL,
    ALTER COLUMN customer_id SET NOT NULL,
    ALTER COLUMN balance SET NOT NULL,
    ALTER COLUMN opened_at SET NOT NULL;

ALTER TABLE transactions
    ALTER COLUMN id SET NOT NULL,
    ALTER COLUMN account_id SET NOT NULL,
    ALTER COLUMN amount SET NOT NULL,
    ALTER COLUMN created_at SET NOT NULL,
    ALTER COLUMN type SET NOT NULL;  -- Assuming 'type' tracks 'credit'/'debit' etc.

-- Step 2: Add unique constraints and check constraints
ALTER TABLE customers
    ADD CONSTRAINT customers_email_unique UNIQUE (email);

ALTER TABLE accounts
    ADD CONSTRAINT accounts_number_unique UNIQUE (number); -- if 'number' is present

ALTER TABLE accounts
    ADD CONSTRAINT accounts_positive_balance CHECK (balance >= 0);

ALTER TABLE transactions
    ADD CONSTRAINT transactions_amount_nonzero CHECK (amount <> 0);

ALTER TABLE transactions
    ADD CONSTRAINT transactions_type_check CHECK (type IN ('credit', 'debit'));

-- Step 3: Add Foreign Key Constraints
ALTER TABLE accounts
    ADD CONSTRAINT accounts_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE;

ALTER TABLE transactions
    ADD CONSTRAINT transactions_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE;

-- Step 4: Add indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_accounts_customer_id ON accounts(customer_id);
CREATE INDEX IF NOT EXISTS idx_transactions_account_id ON transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at);

-- If you expect to often filter transactions for a customer, composite index helps
CREATE INDEX IF NOT EXISTS idx_transactions_account_customer ON transactions(account_id);

-- Step 5: Basic Reporting Queries
-- 1. Fetch all transactions for a given customer (by customer_id)
-- :customer_id is a bind variable
SELECT t.*
FROM transactions t
JOIN accounts a ON t.account_id = a.id
WHERE a.customer_id = :customer_id
ORDER BY t.created_at DESC;

-- 2. Fetch balances per account (all)
SELECT id AS account_id, balance
FROM accounts;

-- 3. List accounts with unusually high transaction counts (e.g., more than 100 txs)
SELECT a.id, a.customer_id, COUNT(t.id) AS transaction_count
FROM accounts a
JOIN transactions t ON t.account_id = a.id
GROUP BY a.id, a.customer_id
HAVING COUNT(t.id) > 100
ORDER BY transaction_count DESC;