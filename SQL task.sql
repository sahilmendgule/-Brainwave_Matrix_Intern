DROP DATABASE IF EXISTS s1;
CREATE DATABASE s1;
USE s1;

DROP TABLE IF EXISTS Fines;
DROP TABLE IF EXISTS Transactions;
DROP TABLE IF EXISTS BookRequests;
DROP TABLE IF EXISTS Librarians;
DROP TABLE IF EXISTS Books;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS AuditLog;

CREATE TABLE Users (
    UserID INT PRIMARY KEY AUTO_INCREMENT,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    PhoneNumber VARCHAR(15) UNIQUE,
    MembershipDate DATE NOT NULL,
    MembershipStatus ENUM('Active', 'Inactive') DEFAULT 'Active'
);

CREATE TABLE Books (
    BookID INT PRIMARY KEY AUTO_INCREMENT,
    Title VARCHAR(255) NOT NULL,
    Author VARCHAR(255) NOT NULL,
    Publisher VARCHAR(255),
    YearPublished INT,
    ISBN VARCHAR(13) UNIQUE,
    Genre VARCHAR(50),
    CopiesAvailable INT DEFAULT 0 CHECK (CopiesAvailable >= 0)
);

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

CREATE TABLE Fines (
    FineID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT NOT NULL,
    TransactionID INT NOT NULL,
    Amount DECIMAL(10, 2) NOT NULL,
    PaidStatus ENUM('Unpaid', 'Paid') DEFAULT 'Unpaid',
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID) ON DELETE CASCADE
);

CREATE TABLE Librarians (
    LibrarianID INT PRIMARY KEY AUTO_INCREMENT,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    HireDate DATE NOT NULL
);

CREATE TABLE BookRequests (
    RequestID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT NOT NULL,
    Title VARCHAR(255) NOT NULL,
    Author VARCHAR(255),
    Status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
    RequestDate DATE NOT NULL,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);

CREATE TABLE AuditLog (
    LogID INT PRIMARY KEY AUTO_INCREMENT,
    TableName VARCHAR(50),
    Action VARCHAR(50),
    ChangedData TEXT,
    ActionTimestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER AfterReturn
AFTER UPDATE ON Transactions
FOR EACH ROW
BEGIN
    IF NEW.ReturnDate IS NOT NULL AND NEW.ReturnDate > NEW.DueDate THEN
        INSERT INTO Fines (UserID, TransactionID, Amount, PaidStatus)
        VALUES (NEW.UserID, NEW.TransactionID, DATEDIFF(NEW.ReturnDate, NEW.DueDate) * 1.00, 'Unpaid');
        
        INSERT INTO AuditLog (TableName, Action, ChangedData, ActionTimestamp)
        VALUES ('Transactions', 'Inserted Fine', CONCAT('UserID: ', NEW.UserID, ', Amount: ', DATEDIFF(NEW.ReturnDate, NEW.DueDate) * 1.00), NOW());
    END IF;
END;
//
DELIMITER ;

INSERT INTO Users (FirstName, LastName, Email, PhoneNumber, MembershipDate, MembershipStatus)
VALUES 
('John', 'Doe', 'johndoe@example.com', '1234567890', '2023-01-01', 'Active'),
('Jane', 'Smith', 'janesmith@example.com', '0987654321', '2023-01-02', 'Active'),
('Alice', 'Brown', 'alicebrown@example.com', '1231231231', '2023-02-01', 'Active'),
('Bob', 'White', 'bobwhite@example.com', '3213213210', '2023-03-01', 'Inactive'),
('Charlie', 'Green', 'charliegreen@example.com', '1112223333', '2023-04-01', 'Active');

INSERT INTO Books (Title, Author, Publisher, YearPublished, ISBN, Genre, CopiesAvailable)
VALUES 
('The Great Gatsby', 'F. Scott Fitzgerald', 'Scribner', 1925, '9780743273565', 'Fiction', 5),
('1984', 'George Orwell', 'Secker & Warburg', 1949, '9780451524935', 'Dystopian', 3),
('The Catcher in the Rye', 'J.D. Salinger', 'Little, Brown and Company', 1951, '9780316769488', 'Classic', 10),
('To Kill a Mockingbird', 'Harper Lee', 'J.B. Lippincott & Co.', 1960, '9780061120084', 'Fiction', 8),
('Brave New World', 'Aldous Huxley', 'Chatto & Windus', 1932, '9780060850524', 'Dystopian', 6);

INSERT INTO Transactions (UserID, BookID, BorrowDate, ReturnDate, Status)
VALUES 
(1, 1, '2023-01-03', NULL, 'Borrowed'),
(2, 2, '2023-01-03', '2023-01-10', 'Returned'),
(1, 3, '2023-03-01', '2023-03-15', 'Returned'),
(2, 4, '2023-03-05', NULL, 'Borrowed'),
(3, 5, '2023-03-10', '2023-03-25', 'Returned');

INSERT INTO Fines (UserID, TransactionID, Amount, PaidStatus)
VALUES 
(1, 1, 5.00, 'Paid'),
(2, 2, 10.00, 'Unpaid'),
(3, 3, 0.00, 'Paid');

INSERT INTO Librarians (FirstName, LastName, Email, HireDate)
VALUES 
('Diana', 'Prince', 'dianaprince@example.com', '2023-02-01'),
('Clark', 'Kent', 'clarkkent@example.com', '2023-03-01'),
('Bruce', 'Wayne', 'brucewayne@example.com', '2023-04-01');

INSERT INTO BookRequests (UserID, Title, Author, Status, RequestDate)
VALUES 
(1, 'Pride and Prejudice', 'Jane Austen', 'Approved', '2023-03-01'),
(2, 'Moby-Dick', 'Herman Melville', 'Rejected', '2023-03-05'),
(3, 'War and Peace', 'Leo Tolstoy', 'Pending', '2023-03-10');

SELECT * FROM Users;
SELECT * FROM Books;
SELECT * FROM Transactions;
SELECT * FROM Fines;
SELECT * FROM Librarians;
SELECT * FROM BookRequests;
SELECT * FROM AuditLog;

