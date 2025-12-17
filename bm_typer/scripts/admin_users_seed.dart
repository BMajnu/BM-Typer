// Admin Users Seed Script
// Run this once to create the initial admin users in Firestore
// 
// Usage: 
// 1. Open Firebase Console > Firestore Database
// 2. Create collection: admin_users
// 3. Add documents with the following structure:

/*
=== Document 1: Developer Admin ===
Collection: admin_users
Document ID: (auto-generate or use custom ID)

Fields:
{
  "email": "badiuzzamanmajnu786@gmail.com",
  "role": "developer",
  "organizationId": null,
  "createdAt": (server timestamp),
  "lastLoginAt": null,
  "isActive": true
}

=== Optional: Add more admins ===

Super Admin Example:
{
  "email": "superadmin@example.com",
  "role": "superAdmin",
  "organizationId": null,
  "createdAt": (server timestamp),
  "lastLoginAt": null,
  "isActive": true
}

Org Admin Example:
{
  "email": "orgadmin@school.edu.bd",
  "role": "orgAdmin",
  "organizationId": "org_123", // Link to organization
  "createdAt": (server timestamp),
  "lastLoginAt": null,
  "isActive": true
}

Team Lead Example:
{
  "email": "teamlead@company.com",
  "role": "teamLead",
  "organizationId": "org_456",
  "createdAt": (server timestamp),
  "lastLoginAt": null,
  "isActive": true
}
*/

// Role Hierarchy:
// 1. developer - Full access including hidden dev tools
// 2. superAdmin - All admin features except dev tools
// 3. orgAdmin - Manage own organization only
// 4. teamLead - View team members only
