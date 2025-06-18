
CREATE DATABASE IF NOT EXISTS research_workflow;
USE research_workflow;


-- User Management
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash CHAR(60) NOT NULL,  -- BCrypt hash
    full_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE roles (
    role_id TINYINT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(20) UNIQUE NOT NULL
) ENGINE=InnoDB;

CREATE TABLE user_roles (
    user_id INT NOT NULL,
    role_id TINYINT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Paper Management
CREATE TABLE papers (
    paper_id INT AUTO_INCREMENT PRIMARY KEY,
    current_version SMALLINT DEFAULT 1,
    status ENUM('DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'REVISION_REQUESTED', 'ACCEPTED', 'REJECTED') DEFAULT 'DRAFT',
    corresponding_author_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (corresponding_author_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

CREATE TABLE paper_versions (
    paper_id INT NOT NULL,
    version SMALLINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    abstract TEXT NOT NULL,
    submission_date DATE NOT NULL,
    file_path VARCHAR(255) NOT NULL,  -- Reference to storage system
    submitted_by INT NOT NULL,
    PRIMARY KEY (paper_id, version),
    FOREIGN KEY (paper_id) REFERENCES papers(paper_id) ON DELETE CASCADE,
    FOREIGN KEY (submitted_by) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- Citation Management
CREATE TABLE citations (
    citing_paper_id INT NOT NULL,
    cited_paper_id INT NOT NULL,
    PRIMARY KEY (citing_paper_id, cited_paper_id),
    FOREIGN KEY (citing_paper_id) REFERENCES papers(paper_id) ON DELETE CASCADE,
    FOREIGN KEY (cited_paper_id) REFERENCES papers(paper_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Review System
CREATE TABLE reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    paper_id INT NOT NULL,
    paper_version SMALLINT NOT NULL,
    reviewer_id INT NOT NULL,
    comments TEXT,
    score TINYINT CHECK (score BETWEEN 1 AND 5),
    status ENUM('PENDING', 'COMPLETED') DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (paper_id, paper_version) REFERENCES paper_versions(paper_id, version) ON DELETE CASCADE,
    FOREIGN KEY (reviewer_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- Tagging System
CREATE TABLE tags (
    tag_id INT AUTO_INCREMENT PRIMARY KEY,
    tag_name VARCHAR(50) UNIQUE NOT NULL
) ENGINE=InnoDB;

CREATE TABLE paper_tags (
    paper_id INT NOT NULL,
    tag_id INT NOT NULL,
    PRIMARY KEY (paper_id, tag_id),
    FOREIGN KEY (paper_id) REFERENCES papers(paper_id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(tag_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Audit Logs
CREATE TABLE audit_logs (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id VARCHAR(100) NOT NULL,  -- Stores primary key value(s)
    action ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    old_data TEXT,
    new_data TEXT,
    performed_by INT NOT NULL,
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (performed_by) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- Indexes for Optimization
CREATE FULLTEXT INDEX idx_paper_title_abstract ON paper_versions(title, abstract);
CREATE INDEX idx_paper_status ON papers(status);
CREATE INDEX idx_review_status ON reviews(status);
CREATE INDEX idx_user_roles ON user_roles(user_id, role_id);

-- Sample Data
INSERT INTO roles (role_name) VALUES 
('AUTHOR'), ('REVIEWER'), ('ADMIN');

INSERT INTO users (email, password_hash, full_name) VALUES
('rudra@gmail.com', 'abc', 'Rudra Kanwar'),
('rk@gmail.com', 'cde', 'Rahul Kumar'),
('srk@gmail.com', 'sss', 'Shahrukh Khan');

INSERT INTO user_roles VALUES
(1, 1), (2, 1), (2, 2), (3, 3);

INSERT INTO papers (corresponding_author_id, status) VALUES
(1, 'UNDER_REVIEW'), (2, 'ACCEPTED');

INSERT INTO paper_versions (paper_id, version, title, abstract, submission_date, file_path, submitted_by) VALUES
(1, 1, 'AI in Healthcare', 'Exploring AI applications...', '2023-01-15', '/papers/ai_health_v1.pdf', 1),
(1, 2, 'Advanced AI in Healthcare', 'Updated research on AI...', '2023-02-20', '/papers/ai_health_v2.pdf', 1),
(2, 1, 'Quantum Computing', 'Breakthroughs in quantum...', '2023-03-10', '/papers/quantum_v1.pdf', 2);

INSERT INTO citations VALUES
(1, 2);  -- Paper 1 cites Paper 2

INSERT INTO reviews (paper_id, paper_version, reviewer_id, comments, score, status) VALUES
(1, 1, 2, 'Needs more data', 3, 'COMPLETED'),
(1, 2, 2, 'Improved significantly', 4, 'COMPLETED');

INSERT INTO tags (tag_name) VALUES
('Artificial Intelligence'), ('Healthcare'), ('Quantum Physics');

INSERT INTO paper_tags VALUES
(1, 1), (1, 2), (2, 3);

-- Triggers for Audit Logs
DELIMITER $$

CREATE TRIGGER papers_audit
AFTER INSERT ON papers FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (table_name, record_id, action, new_data, performed_by)
    VALUES ('papers', NEW.paper_id, 'INSERT', JSON_OBJECT('paper_id', NEW.paper_id), NEW.corresponding_author_id);
END$$

CREATE TRIGGER paper_versions_audit
AFTER INSERT ON paper_versions FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (table_name, record_id, action, new_data, performed_by)
    VALUES ('paper_versions', CONCAT(NEW.paper_id, '-', NEW.version), 'INSERT', 
            JSON_OBJECT('paper_id', NEW.paper_id, 'version', NEW.version), NEW.submitted_by);
END$$

-- Add similar triggers for UPDATE/DELETE on all critical tables

DELIMITER ;

-- Stored Procedures
DELIMITER $$

-- Submit new paper version
CREATE PROCEDURE submit_paper_version(
    IN p_paper_id INT,
    IN p_title VARCHAR(255),
    IN p_abstract TEXT,
    IN p_file_path VARCHAR(255),
    IN p_submitted_by INT
)
BEGIN
    DECLARE new_version SMALLINT;
    DECLARE is_author BOOLEAN;
    
    -- Verify user is author
    SELECT EXISTS(SELECT 1 FROM user_roles 
                 WHERE user_id = p_submitted_by AND role_id = 1) INTO is_author;
                 
    IF NOT is_author THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Only authors can submit papers';
    END IF;
    
    -- Get next version number
    SELECT COALESCE(MAX(version), 0) + 1 INTO new_version
    FROM paper_versions WHERE paper_id = p_paper_id;
    
    -- Insert new version
    INSERT INTO paper_versions (paper_id, version, title, abstract, submission_date, file_path, submitted_by)
    VALUES (p_paper_id, new_version, p_title, p_abstract, CURDATE(), p_file_path, p_submitted_by);
    
    -- Update paper status and version
    UPDATE papers 
    SET current_version = new_version,
        status = CASE 
            WHEN status = 'DRAFT' THEN 'SUBMITTED' 
            ELSE 'REVISION_REQUESTED' 
        END,
        updated_at = NOW()
    WHERE paper_id = p_paper_id;
END$$

-- Assign reviewer to paper
CREATE PROCEDURE assign_reviewer(
    IN p_paper_id INT,
    IN p_version SMALLINT,
    IN p_reviewer_id INT,
    IN p_assigned_by INT
)
BEGIN
    DECLARE is_admin BOOLEAN;
    
    -- Verify assigner is admin
    SELECT EXISTS(SELECT 1 FROM user_roles 
                 WHERE user_id = p_assigned_by AND role_id = 3) INTO is_admin;
                 
    IF NOT is_admin THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Only admins can assign reviewers';
    END IF;
    
    -- Verify reviewer role
    IF NOT EXISTS(SELECT 1 FROM user_roles 
                  WHERE user_id = p_reviewer_id AND role_id = 2) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'User is not a reviewer';
    END IF;
    
    -- Insert review assignment
    INSERT INTO reviews (paper_id, paper_version, reviewer_id)
    VALUES (p_paper_id, p_version, p_reviewer_id);
END$$

-- Bulk import papers (simplified example)

CREATE PROCEDURE bulk_import_papers(IN author_ids TEXT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE id TEXT;
    DECLARE total INT;

    SET total = LENGTH(author_ids) - LENGTH(REPLACE(author_ids, ',', '')) + 1;

    WHILE i <= total DO
        SET id = SUBSTRING_INDEX(SUBSTRING_INDEX(author_ids, ',', i), ',', -1);

        INSERT INTO papers (corresponding_author_id, status)
        VALUES (CAST(id AS UNSIGNED), 'SUBMITTED');

        SET i = i + 1;
    END WHILE;
END$$



-- Search papers
CREATE PROCEDURE search_papers(IN search_term VARCHAR(255))
BEGIN
    SELECT p.paper_id, v.title, v.abstract, p.status
    FROM papers p
    JOIN paper_versions v ON p.paper_id = v.paper_id AND p.current_version = v.version
    WHERE MATCH(v.title, v.abstract) AGAINST(search_term IN NATURAL LANGUAGE MODE)
    OR p.paper_id IN (
        SELECT pt.paper_id 
        FROM paper_tags pt 
        JOIN tags t ON pt.tag_id = t.tag_id
        WHERE t.tag_name LIKE CONCAT('%', search_term, '%')
    );
END$$

DELIMITER ;

-- Views for Statistics
CREATE VIEW most_cited_papers AS
SELECT p.paper_id, v.title, COUNT(c.citing_paper_id) AS citation_count
FROM papers p
JOIN paper_versions v ON p.current_version = v.version AND p.paper_id = v.paper_id
LEFT JOIN citations c ON p.paper_id = c.cited_paper_id
GROUP BY p.paper_id, v.title
ORDER BY citation_count DESC;

CREATE VIEW active_reviewers AS
SELECT u.user_id, u.full_name, COUNT(r.review_id) AS reviews_completed
FROM users u
JOIN reviews r ON u.user_id = r.reviewer_id
WHERE r.status = 'COMPLETED'
GROUP BY u.user_id, u.full_name
ORDER BY reviews_completed DESC;


-- EXAMPLES


-- 1. Get all papers with their latest version
SELECT p.paper_id, v.title, v.abstract, p.status 
FROM papers p
JOIN paper_versions v ON p.current_version = v.version AND p.paper_id = v.paper_id;

-- 2. Get all citations for a paper
SELECT cited_paper_id 
FROM citations 
WHERE citing_paper_id = 1;

-- 3. Get pending reviews for a reviewer
SELECT * FROM reviews 
WHERE reviewer_id = 2 AND status = 'PENDING';

-- 4. Update paper status
UPDATE papers SET status = 'ACCEPTED' WHERE paper_id = 1;

-- 5. Get papers by tag
SELECT p.paper_id, v.title 
FROM papers p
JOIN paper_versions v ON p.current_version = v.version AND p.paper_id = v.paper_id
JOIN paper_tags pt ON p.paper_id = pt.paper_id
JOIN tags t ON pt.tag_id = t.tag_id
WHERE t.tag_name = 'Artificial Intelligence';
