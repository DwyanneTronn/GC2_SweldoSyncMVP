const express = require('express');
const router = express.Router();
const axios = require('axios');

// Get holidays from external API
router.get('/', async (req, res) => {
  try {
    const year = new Date().getFullYear();
    const response = await axios.get(
      `https://date.nager.at/api/v3/PublicHolidays/${year}/PH`
    );
    
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

module.exports = router;

