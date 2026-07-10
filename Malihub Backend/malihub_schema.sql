
CREATE DATABASE IF NOT EXISTS malihub
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE malihub;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS financial_goals;
DROP TABLE IF EXISTS budgets;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id             INT AUTO_INCREMENT PRIMARY KEY,
    first_name          VARCHAR(50)  NOT NULL,
    last_name           VARCHAR(50)  NOT NULL,
    email               VARCHAR(100) NOT NULL UNIQUE,
    phone_number        VARCHAR(20)  NULL,
    currency_preference VARCHAR(3)   NOT NULL DEFAULT 'KES',
    password_hash       VARCHAR(255) NOT NULL,
    is_active           BOOLEAN      NOT NULL DEFAULT TRUE,
    last_login_at       DATETIME     NULL,
    created_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                                      ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;


CREATE TABLE categories (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    user_id       INT NOT NULL,
    category_name VARCHAR(50) NOT NULL,
    icon          VARCHAR(50) NULL,
    is_default    BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_category_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE,
    CONSTRAINT uq_user_category UNIQUE (user_id, category_name)
) ENGINE=InnoDB;

CREATE TABLE accounts (
    account_id   INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT NOT NULL,
    account_name VARCHAR(50) NOT NULL,
    account_type ENUM('checking','savings','credit_card','cash') NOT NULL,
    balance      DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_account_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE budgets (
    budget_id       INT AUTO_INCREMENT PRIMARY KEY,
    user_id         INT NOT NULL,
    category_id     INT NOT NULL,
    budget_amount   DECIMAL(14,2) NOT NULL,
    period_type     ENUM('weekly','monthly','yearly') NOT NULL,
    start_date      DATE NOT NULL,
    alert_threshold DECIMAL(5,2) NULL,
    CONSTRAINT fk_budget_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_budget_category
        FOREIGN KEY (category_id) REFERENCES categories(category_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE financial_goals (
    goal_id        INT AUTO_INCREMENT PRIMARY KEY,
    user_id        INT NOT NULL,
    goal_name      VARCHAR(50) NOT NULL,
    target_amount  DECIMAL(14,2) NOT NULL,
    current_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    deadline       DATE NULL,
    CONSTRAINT fk_goal_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE transactions (
    transaction_id   INT AUTO_INCREMENT PRIMARY KEY,
    account_id        INT NOT NULL,
    category_id        INT NOT NULL,
    amount              DECIMAL(14,2) NOT NULL,
    transaction_type    ENUM('debit','credit') NOT NULL,
    description          VARCHAR(150) NULL,
    transaction_date     DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT fk_transaction_account
        FOREIGN KEY (account_id) REFERENCES accounts(account_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_transaction_category
        FOREIGN KEY (category_id) REFERENCES categories(category_id)
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE notifications (
    notification_id   INT AUTO_INCREMENT PRIMARY KEY,
    user_id             INT NOT NULL,
    notification_type    ENUM('budget_exceeded','goal_milestone') NOT NULL,
    message                TEXT NOT NULL,
    is_read                 BOOLEAN NOT NULL DEFAULT FALSE,
    created_at               DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notification_guser
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;
