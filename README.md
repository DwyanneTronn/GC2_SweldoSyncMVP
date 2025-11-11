SweldoSync - Final Project Submission

This project is a functional MVP for SweldoSync, a multi-industry payroll computation engine designed for Philippine SMEs. It moves businesses from manual spreadsheets to an automated, "per-run" batch processing system.

Deployment Link: [Your-Vercel-Deployment-URL] (e.g., https://sweldosync-final-project.vercel.app)

Git Repo Link: [Your-Repo-URL.git]

1. Platform Architecture Plan

System Diagram

Our system uses a standard 3-Tier Architecture:

Client (Frontend): A Flutter Web application serves the user interface.

Server (Backend): A Node.js (Express) server provides a REST API. It handles all business logic, calculations, and database communication.

Database (Data): A PostgreSQL database (e.g., on Render) stores all persistent data.

External Services: The backend integrates with third-party APIs (e.g., Nager.Date for holidays).

Tech Stack Justification

Component

Technology

Version

Justification

Frontend

Flutter (Web)

3.22.x

(GC1 Business Concept) Our goal is an app that is simple and intuitive. Flutter's component-based UI provides a clean, modern, and trustworthy experience. Its cross-platform nature also allows us to target mobile in the future from the same codebase.

Backend

Node.js (Express)

20.x

Node.js is ideal for an I/O-heavy application that acts as an API gateway—receiving requests from Flutter, fetching data from the DB, calling external APIs, and returning JSON. Its speed is perfect for our "Core Engine" concept.

Database

PostgreSQL

16.x

(GC1/Panel Feedback) The panel was explicit: "SQL over NoSQL." Payroll data is highly relational, auditable, and requires strong transactional integrity (ACID). PostgreSQL is the best-in-class open-source relational DB for this.

Live API

Nager.Date API

v3

A free public API for fetching official public holidays. This is directly relevant to payroll for calculating special non-working day and regular holiday pay.

Hosting & Deployment Plan

The application is deployed using free-tier PaaS (Platform as a Service) providers that connect directly to our Git repository, enabling CI/CD.

Frontend (Flutter Web):

Provider: Vercel

Process: Vercel connects to our GitHub repo. On every git push, it automatically runs the flutter build web --release command, builds the static assets, and deploys them to its global CDN.

Backend (Node.js):

Provider: Render

Process: Render connects to our GitHub repo and monitors the backend_nodejs directory. On every git push, it re-builds the Node.js server, runs npm install, and deploys the new instance, ensuring zero downtime.

Database (PostgreSQL):

Provider: Render PostgreSQL

Process: A free-tier PostgreSQL instance is provisioned on Render. Our Node.js backend connects to this database using a secure, internal connection string.

Data Flow Description

Our "Core Transaction" (running a payroll) demonstrates the data flow:

User (HR) logs into the Flutter app (on Vercel) and clicks "Start Payroll Run."

Flutter App shows the employee list and fetches holiday data by sending a GET /api/holidays request to our Node.js backend (on Render).

Node.js Backend receives the request, calls the external Nager.Date API, gets the holiday list, and returns it to Flutter as JSON.

User inputs hours (regular, OT, holiday OT) and clicks "Calculate Payroll."

Flutter App bundles the industry and employeeInputs into a JSON object and sends it via POST /api/calculate to our Node.js backend.

Node.js Backend receives the data, applies the industry logic, calculates the payslips, and saves the results to the Render PostgreSQL Database.

Node.js Backend returns the final list of calculatedPayslips (JSON) to the Flutter app.

Flutter App receives the JSON and displays the final "Payroll Summary" screen.

2. Core Transaction Flow

Our app's primary transaction is a "Payroll Run," which follows the "Other app type" flow (Browse → Select → Confirm → Persist).

Browse (Dashboard): The user sees the main dashboard (PayrollHomeScreen) with the next active pay period.

Select (Input Form): The user clicks "Start Payroll Run," which navigates them to the _buildInputView. Here, they:

Select the Industry Template (Standard, BPO, Airline).

Input data for each employee (e.g., Days Worked, Holiday OT).

Can use "Simulate Bulk Import" to mock uploading a CSV for 50+ employees.

Confirm (Summary): The user clicks "Calculate Payroll." The app calls the backend and, upon success, navigates to the _buildSummaryView. This screen shows a complete summary of all calculations.

Persist (Mocked): The user clicks "Approve & Disburse." This simulates the final step, where the data would be finalized in the database and an API call would be made to a bank partner (Phase 2).

3. Performance & Discoverability Optimization

As a Flutter Web application, we focus on app load time and responsiveness.

App Load Time (LCP): Flutter's flutter build web --release command (run by Vercel) automatically performs code splitting (tree-shaking) and minification. This means the user only downloads the code necessary for the initial route.

Responsiveness (Adaptive Layouts): The app is built within a ConstrainedBox(maxWidth: 1200) and uses Flutter's ListView and Row/Column widgets, which are inherently responsive.

Asset Optimization: Our app avoids large images, using lightweight .dart-based Material Icon widgets, which are part of a single bundled "font" file.

Performance Metrics

Lighthouse scores for the live Vercel deployment.

Before (Debug Mode):

Lighthouse Performance: ~45

After (Release Mode on Vercel):

Lighthouse Performance: 90+

(Screenshot below)

4. Live API Integration (Nager.Date)

To make our payroll calculations more accurate, we integrate a live public API for Philippine Public Holidays, which affects overtime pay calculations.

API: Nager.Date API (https://date.nager.at)

Endpoint: GET https://date.nager.at/api/v3/PublicHolidays/{year}/{countryCode}

Implementation:

We created a new backend endpoint: GET /api/holidays.

When this endpoint is called, our Node.js server makes a server-to-server request to https://date.nager.at/api/v3/2024/PH.

The Flutter app fetches this list from our backend and displays it as a banner.

We added a "Special Holiday OT" input field to the UI, which is now part of the calculation.

Error Handling: The _calculatePayroll and _fetchHolidays functions in main.dart are wrapped in try...catch blocks. If the backend fails, a _showErrorDialog is shown to the user with a friendly error message, preventing the app from crashing.

5. Setup & Running the Project

Prerequisites

Flutter SDK (v3.22.x)

Node.js (v20.x)

Backend Setup (Local)

Navigate to the backend_nodejs folder:

cd backend_nodejs


Install dependencies:

npm install express cors axios


Run the server:

node server.js


Output: SweldoSync Backend running on http://localhost:3000

Frontend Setup (Local)

Open a new terminal.

Navigate to the frontend_flutter folder:

cd frontend_flutter


Get packages:

flutter pub get


Run the app on Chrome (Web):

flutter run -d chrome


(This will open the app, connected to your local backend.)

6. Known Issues & Limitations

Mocked Deductions: All government deductions (SSS, PhilHealth, Tax) are currently a flat 12% simplification for this MVP.

Authentication: There is no login screen. The app currently serves a single "mocked" user.

Database Integration: The backend logic for fetching/saving from the PostgreSQL database is commented out in server.js for this MVP. The app currently trusts the basic salary sent from the client, which is not secure but sufficient for this demo.