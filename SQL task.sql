CREATE DATABASE IF NOT EXISTS s1;
USE s1;

-- Users Table
CREATE TABLE Users (
    UserID INT PRIMARY KEY AUTO_INCREMENT,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    PhoneNumber VARCHAR(15) UNIQUE,
    MembershipDate DATE NOT NULL,
    MembershipStatus ENUM('Active', 'Inactive') DEFAULT 'Active'
);

INSERT INTO Users (FirstName, LastName, Email, PhoneNumber, MembershipDate, MembershipStatus)
VALUES 
('John', 'Doe', 'johndoe@example.com', '1234567890', '2025-01-01', 'Active'),
('Jane', 'Smith', 'janesmith@example.com', '0987654321', '2025-01-02', 'Active');

-- Books Table
CREATE TABLE Books (
    BookID INT PRIMARY KEY AUTO_INCREMENT,
    Title VARCHAR(255) NOT NULL,
    Author VARCHAR(255) NOT NULL,
    Publisher VARCHAR(255),
    YearPublished INT CHECK (YearPublished >= 1000 AND YearPublished <= YEAR(CURDATE())),
    ISBN VARCHAR(13) UNIQUE,
    Genre VARCHAR(50),
    CopiesAvailable INT DEFAULT 0 CHECK (CopiesAvailable >= 0)
);

INSERT INTO Books (Title, Author, Publisher, YearPublished, ISBN, Genre, CopiesAvailable)
VALUES 
('The Great Gatsby', 'F. Scott Fitzgerald', 'Scribner', 1925, '9780743273565', 'Fiction', 5),
('1984', 'George Orwell', 'Secker & Warburg', 1949, '9780451524935', 'Dystopian', 3);

-- Transactions Table
CREATE TABLE Transactions (
    TransactionID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT NOT NULL,
    BookID INT NOT NULL,
    BorrowDate DATE NOT NULL,
    DueDate DATE GENERATED ALWAYS AS (DATE_ADD(BorrowDate, INTERVAL 14 DAY)) VIRTUAL,
    ReturnDate DATE,
    Status ENUM('Borrowed', 'Returned') DEFAULT 'Borrowed',
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    FOREIGN KEY (BookID) REFERENCES Books(BookID) ON DELETE CASCADE
);

INSERT INTO Transactions (UserID, BookID, BorrowDate, ReturnDate, Status)
VALUES 
(1, 1, '2025-01-03', NULL, 'Borrowed'),
(2, 2, '2025-01-03', '2025-01-10', 'Returned');

-- Fines Table
CREATE TABLE Fines (
    FineID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT NOT NULL,
    TransactionID INT NOT NULL,
    Amount DECIMAL(10, 2) NOT NULL,
    PaidStatus ENUM('Unpaid', 'Paid') DEFAULT 'Unpaid',
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID) ON DELETE CASCADE
);

-- Trigger to Auto-Generate Fines for Late Returns
DELIMITER //
CREATE TRIGGER AfterReturn
AFTER UPDATE ON Transactions
FOR EACH ROW
BEGIN
    IF NEW.ReturnDate IS NOT NULL AND NEW.ReturnDate > NEW.DueDate THEN
        INSERT INTO Fines (UserID, TransactionID, Amount, PaidStatus)
        VALUES (NEW.UserID, NEW.TransactionID, DATEDIFF(NEW.ReturnDate, NEW.DueDate) * 1.00, 'Unpaid');
    END IF;
END;
//
DELIMITER ;

-- Librarians Table
CREATE TABLE Librarians (
    LibrarianID INT PRIMARY KEY AUTO_INCREMENT,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    HireDate DATE NOT NULL
);

INSERT INTO Librarians (FirstName, LastName, Email, HireDate)
VALUES 
('Alice', 'Johnson', 'alicejohnson@example.com', '2025-01-01');

-- Book Requests Table
CREATE TABLE BookRequests (
    RequestID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT NOT NULL,
    Title VARCHAR(255) NOT NULL,
    Author VARCHAR(255),
    Status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
    RequestDate DATE NOT NULL,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);

INSERT INTO BookRequests (UserID, Title, Author, Status, RequestDate)
VALUES 
(1, 'To Kill a Mockingbird', 'Harper Lee', 'Pending', '2025-01-03');

-- Audit Log Table for Changes
CREATE TABLE AuditLog (
    LogID INT PRIMARY KEY AUTO_INCREMENT,
    TableName VARCHAR(50),
    Action VARCHAR(50),
    ChangedData TEXT,
    ActionTimestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER LogUserChanges
AFTER INSERT OR UPDATE OR DELETE ON Users
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, Action, ChangedData)
    VALUES 
    ('Users', CASE
        WHEN OLD.UserID IS NULL THEN 'INSERT'
        WHEN NEW.UserID IS NULL THEN 'DELETE'
        ELSE 'UPDATE'
    END, CONCAT('Old: ', COALESCE(OLD.UserID, 'NULL'), ', New: ', COALESCE(NEW.UserID, 'NULL')));
END;
//
DELIMITER ;

-- Indexes for Optimization
CREATE INDEX idx_user_email ON Users (Email);
CREATE INDEX idx_books_genre ON Books (Genre);
CREATE INDEX idx_transactions_status ON Transactions (Status);

-- Test Queries
SELECT * FROM Users;
SELECT * FROM Books;
SELECT * FROM Transactions;
SELECT * FROM Fines;
SELECT * FROM Librarians;
SELECT * FROM BookRequests;
SELECT * FROM AuditLog;