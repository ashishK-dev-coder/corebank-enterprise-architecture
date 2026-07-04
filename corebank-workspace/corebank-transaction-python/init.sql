CREATE TABLE IF NOT EXISTS accounts (
    id SERIAL PRIMARY KEY,
    account_number VARCHAR(50) UNIQUE NOT NULL,
    balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00
);

INSERT INTO accounts (account_number, balance)
VALUES ('DUMMY-100K', 100000.00)
ON CONFLICT (account_number) DO NOTHING;
