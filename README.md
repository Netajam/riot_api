# Riot API Implementation

## Overview

This project implements an HTTP API with four endpoints as specified by the Riot Take-Home Technical Challenge. It provides basic operations for data manipulation:

1.  **Encryption:** Encodes top-level (1 detph level) JSON values using Base64.
2.  **Decryption:** Decodes Base64 values, leaving others untouched.
3.  **Signing:** Generates an HMAC-SHA256 signature based on the JSON object's value (order-independent).
4.  **Verification:** Validates a signature against provided JSON data.

Built with Elixir and the Phoenix Framework.

## API Endpoints

All endpoints accept `POST` requests with `Content-Type: application/json`.

*   **`/api/v1/encrypt`**
    *   **Input:** Any JSON object.
    *   **Output:** JSON object with depth-1 property values Base64 encoded. *(Note: Base64 is used for simplicity per challenge requirements, not for real security).*
*   **`/api/v1/decrypt`**
    *   **Input:** JSON object, potentially with Base64 encoded values.
    *   **Output:** JSON object with Base64 values decoded back to their original types. Non-Base64 values are returned unchanged.
*   **`/api/v1/sign`**
    *   **Input:** Any JSON object.
    *   **Output:** `{"signature": "..."}` containing the Base64 encoded HMAC-SHA256 signature. The signature depends only on the *value* of the JSON, not the order of keys.
*   **`/api/v1/verify`**
    *   **Input:** `{"signature": "...", "data": { ... }}`
    *   **Output:**
        *   `204 No Content` if the signature is valid for the data.
        *   `400 Bad Request` if the signature is invalid or the payload structure is incorrect.
    
# Additional
*For developer setup, running the application (development/production), and testing instructions, please see [`DEV_README.md`](./DEV_README.md).*
