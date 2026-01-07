
# Transaction Usernames Loading Fix

## Overview
The "Posted by" and "Requested by" fields in the Transaction details and history were previously showing "Loading..." indefinitely for some transactions. This was caused by the `initiatedByName` and `targetUserName` fields being null in the transaction data, and the UI not having a mechanism to fetch them.

## Solution Implemented

1.  **UI Updates**:
    *   **`TransactionDetailScreen`**: Converted to `StatefulWidget` to asynchronously fetch missing user names using `FirebaseService`.
    *   **`TransactionHistoryScreen`**: Introduced a `TransactionCard` stateful widget to handle individual transaction items, allowing each card to fetch missing names independently if needed.

2.  **Backend/Service Updates**:
    *   **`FirebaseService`**: Updated `applyToJob`, `bookService`, and `requestRental` methods to accept and store `posterName`, `providerName`, and `ownerName` (mapped to `targetUserName` and `initiatedByName`) in the transaction document. This ensures future transactions have these names pre-populated.

3.  **Provider & Screen Updates**:
    *   Updated `JobsProvider`, `ServicesProvider`, and `RentalsProvider` to pass the required names to `FirebaseService`.
    *   Updated `JobDetailScreen`, `ServiceDetailScreen`, and `RentalDetailScreen` to pass the names from their respective models (`JobModel`, `ServiceModel`, `RentalModel`) when initiating a transaction.

## Benefits
*   **Backward Compatibility**: Existing transactions with missing names will now gracefully load the names.
*   **Performance**: New transactions will display names instantly without additional network requests.
*   **Reliability**: The "Loading..." state should now be transient and resolve to the correct user name.
