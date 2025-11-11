// This is your Node.js Express server.
// It handles all the "hard" work (calculations, database calls).
// Your Flutter app will call this server.

const express = require('express');
const cors = require('cors');
const axios = require('axios'); // <-- NEW: For Live API integration
// const { Pool } = require('pg'); // Ready for when you connect to PostgreSQL

const app = express();
const port = process.env.PORT || 3000;

// --- Database Setup (Mocked for now) ---
// const pool = new Pool({
//   user: 'your_db_user',
//   host: 'localhost',
//   database: 'sweldosync_db',
//   password: 'your_db_password',
//   port: 5432,
// });

// --- Middleware ---
app.use(cors()); // Allows your Flutter app to call this server
app.use(express.json()); // Parses incoming JSON data from Flutter

// --- LOGIC (Migrated from your index.html) ---
// This is the "Strategy Pattern" for different industries.
// This BELONGS on the server, not in the app.
const INDUSTRY_CONFIG = {
    standard: {
        label1: "Days Worked",
        label2: "Overtime (Hrs)",
        label3: "Holiday OT (Hrs)", // <-- NEW
        calculate: (basic, val1, val2, val3) => {
            const dailyRate = (basic * 12) / 261;
            const basicPay = dailyRate * val1;
            const otPay = (dailyRate / 8) * 1.25 * val2;
            const holidayOtPay = (dailyRate / 8) * 2.0 * val3; // <-- NEW: 200% rate for Holiday OT
            return { basicPay, variablePay: otPay + holidayOtPay, variableLabel: "Overtime/Holiday Pay" };
        }
    },
    bpo: {
        label1: "Days Worked",
        label2: "Night Diff (Hrs)",
        label3: "Holiday OT (Hrs)", // <-- NEW
        calculate: (basic, val1, val2, val3) => {
            const dailyRate = (basic * 12) / 261;
            const basicPay = dailyRate * val1;
            const ndPay = (dailyRate / 8) * 0.10 * val2;
            const holidayOtPay = (dailyRate / 8) * 2.0 * val3; // <-- NEW
            return { basicPay, variablePay: ndPay + holidayOtPay, variableLabel: "Differentials/Holiday Pay" };
        }
    },
    airline: {
        label1: "Base Pay %",
        label2: "Flight Hours",
        label3: "Holiday Flight (Hrs)", // <-- NEW
        calculate: (basic, val1, val2, val3) => {
            const basicPay = basic * (val1 > 0 ? 1 : 0);
            const flightRate = 1500; // Hardcoded hypothetical rate
            const flightPay = val2 * flightRate;
            const holidayFlightPay = val3 * (flightRate * 2.0); // <-- NEW
            return { basicPay, variablePay: flightPay + holidayFlightPay, variableLabel: "Flight Pay" };
        }
    }
};

// --- API ENDPOINTS ---

/**
 * NEW: Live API Integration Endpoint
 * This endpoint fetches live holiday data from an external API.
 * The Flutter app will call THIS endpoint, not the external one directly.
 */
app.get('/api/holidays', async (req, res) => {
    try {
        const year = new Date().getFullYear();
        // This is the live API call
        const response = await axios.get(
            `https://date.nager.at/api/v3/PublicHolidays/${year}/PH`
        );
        
        // We only care about the date and name
        const holidays = response.data.map(holiday => ({
            date: holiday.date,
            name: holiday.localName
        }));

        res.json(holidays);

    } catch (error) {
        console.error("Error fetching holidays:", error.message);
        res.status(500).json({ error: 'Failed to fetch holiday data.' });
    }
});


/**
 * This is the "Core Engine" API.
 * Flutter sends the industry and employee inputs.
 * This server does the math and sends the results back.
 */
app.post('/api/calculate', (req, res) => {
    const { industry, employees } = req.body;

    if (!industry || !employees) {
        return res.status(400).json({ error: 'Missing industry or employee data' });
    }

    const config = INDUSTRY_CONFIG[industry];
    if (!config) {
        return res.status(400).json({ error: 'Invalid industry specified' });
    }

    // In a real app, you would loop and fetch each employee's 'basic' salary
    // from your SQL database.
    // e.g., const dbEmployee = await pool.query('SELECT * FROM employees WHERE id = $1', [emp.id]);
    // const basic = dbEmployee.rows[0].basic_salary;
    
    // For this MVP, we trust the 'basic' salary sent from the client.
    
    try {
        const calculatedPayslips = employees.map(emp => {
            // UPDATED: Now accepts val3 for holiday pay
            const { basicPay, variablePay, variableLabel } = config.calculate(
                emp.basic, 
                emp.inputs.val1, 
                emp.inputs.val2,
                emp.inputs.val3 // <-- NEW
            );

            const gross = basicPay + variablePay;
            // Simplified Deductions (as per prototype)
            const deductions = gross * 0.12; 
            const netPay = gross - deductions;

            return {
                id: emp.id,
                name: emp.name,
                basicEarned: basicPay,
                variablePay: variablePay,
                variableLabel: variableLabel,
                deductions: deductions,
                netPay: netPay
            };
        });

        // Success! Send the results back to Flutter.
        res.json({ payslips: calculatedPayslips });

    } catch (error) {
        console.error("Calculation Error:", error);
        res.status(500).json({ error: 'An error occurred during calculation.' });
    }
});

app.listen(port, () => {
    console.log(`SweldoSync Backend running on http://localhost:${port}`);
});