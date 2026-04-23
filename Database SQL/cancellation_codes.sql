CREATE TABLE cancellation_codes (
    cancellation_reason VARCHAR(1) PRIMARY KEY,
    cancellation_description VARCHAR(255)
);

INSERT INTO cancellation_codes (cancellation_reason, cancellation_description) VALUES ('A', 'Airline/Carrier');
INSERT INTO cancellation_codes (cancellation_reason, cancellation_description) VALUES ('B', 'Weather');
INSERT INTO cancellation_codes (cancellation_reason, cancellation_description) VALUES ('C', 'National Air System');
INSERT INTO cancellation_codes (cancellation_reason, cancellation_description) VALUES ('D', 'Security');