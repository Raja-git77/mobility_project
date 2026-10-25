require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { exec } = require('child_process');
const db = require('./db');

const app = express();
app.use(cors());
app.use(express.json());
const path = require('path');
app.use(express.static(path.join(__dirname, 'build/web')));

// Initialize database
db.initDatabase();

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', app: 'Mobility App', tagline: 'Smart Integrated Car, Driver & Partner Services' });
});

app.get('/fallback', (req, res) => {
  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Mobility App — Smart Integrated Car, Driver & Partner Services</title>
  <style>
    * { box-sizing: border-box; font-family: 'Segoe UI', sans-serif; }
    body { margin: 0; background: #f8fafc; color: #0f172a; }
    header { background: #0f172a; color: #fff; padding: 18px 28px; display: flex; justify-content: space-between; align-items: center; }
    .container { max-width: 1150px; margin: 22px auto; padding: 0 16px; }
    .card { background: #fff; border-radius: 12px; padding: 20px; margin-bottom: 18px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 16px; }
    .btn { background: #10b981; color: #fff; border: none; padding: 10px 18px; border-radius: 8px; cursor: pointer; font-weight: 600; }
    .btn-outline { background: #e2e8f0; color: #1e293b; border: none; padding: 10px 18px; border-radius: 8px; cursor: pointer; font-weight: 600; }
    .badge { background: #dbeafe; color: #1e40af; padding: 4px 10px; border-radius: 99px; font-size: 12px; font-weight: 700; }
    select, input { width: 100%; padding: 9px; border-radius: 8px; border: 1px solid #cbd5e1; margin-top: 6px; }
    .item-row { display: flex; justify-content: space-between; align-items: center; padding: 14px 0; border-bottom: 1px solid #e2e8f0; }
  </style>
</head>
<body>
  <header>
    <div>
      <h2 style="margin:0;">Mobility App</h2>
      <small>Smart Integrated Car, Driver & Partner Services</small>
    </div>
    <span class="badge" style="background:#10b981;color:#fff;">VERIFIED PLATFORM</span>
  </header>

  <div class="container">
    <div class="card">
      <h3 style="margin-top:0;">1. Select Mobility Service & Preferences</h3>
      <div class="grid">
        <div>
          <label><b>Service Mode</b></label><br><br>
          <button class="btn" onclick="alert('Self-Drive Mode Selected!')">Self-Drive Rental</button>
          <button class="btn-outline" onclick="alert('Driver Service Mode Selected!')">On-Demand Driver</button>
        </div>
        <div>
          <label><b>Preferred Category</b></label>
          <select id="cat">
            <option value="SUV">SUV</option>
            <option value="EV">Electric Vehicle (EV)</option>
            <option value="Sedan">Sedan</option>
          </select>
        </div>
        <div>
          <label><b>Duration (Hours): <span id="hrsTxt">4</span> hrs</b></label>
          <input type="range" id="hrs" min="1" max="24" value="4" oninput="document.getElementById('hrsTxt').innerText=this.value;">
        </div>
      </div>
    </div>

    <div class="card" style="background:#eff6ff; border:1px solid #bfdbfe;">
      <b>AI Route Optimization & Dynamic Pricing:</b><br>
      Optimized Distance: <b>11.8 km</b> (Saved 2.4 km vs baseline) • ETA: <b>22 mins</b> • Dynamic Fare Multiplier: <b>1.15x</b>
    </div>

    <div class="card">
      <h3 style="margin-top:0;">2. AI-Ranked Vehicles</h3>
      <div class="item-row">
        <div>
          <b>Hyundai Creta SX (SUV)</b> <span class="badge">AI Score: 96.5%</span><br>
          <small>Diesel • 1.2 km away • Rating: 4.8★ • <b>₹350/hr</b></small>
        </div>
        <button class="btn" onclick="book('Hyundai Creta SX', 350)">Book Now</button>
      </div>
      <div class="item-row">
        <div>
          <b>Tata Nexon EV (EV)</b> <span class="badge">AI Score: 94.0%</span><br>
          <small>Electric • 2.1 km away • Rating: 4.9★ • <b>₹280/hr</b></small>
        </div>
        <button class="btn" onclick="book('Tata Nexon EV', 280)">Book Now</button>
      </div>
    </div>

    <div class="card">
      <h3 style="margin-top:0;">3. Live GPS Tracking & Booking Status</h3>
      <div id="gpsArea" style="color:#64748b;">Select "Book Now" on any vehicle to start live GPS telemetry & Razorpay payment simulation.</div>
    </div>
  </div>

  <script>
    function book(name, rate) {
      let progress = 10;
      const box = document.getElementById('gpsArea');
      const timer = setInterval(() => {
        box.innerHTML = \`
          <div>
            <span class="badge" style="background:#dcfce7;color:#166534;">BOOKING CONFIRMED</span>
            <h4 style="margin:8px 0;">\&nbsp;\${name}</h4>
            <b>Live GPS Tracking: \${progress}% Completed</b>
            <div style="background:#e2e8f0;height:12px;border-radius:8px;margin:8px 0;">
              <div style="background:#16a34a;width:\${progress}%;height:12px;border-radius:8px;"></div>
            </div>
            <small>📍 Lat: \${(13.0827 - progress*0.0004).toFixed(4)}, Lng: \${(80.2707 - progress*0.0003).Tuple ? '' : (80.2707 - progress*0.0003).toFixed(4)} • Speed: 45 km/h</small>
          </div>
        \`;
        progress += 20;
        if (progress > 100) clearInterval(timer);
      }, 1000);
    }
  </script>
</body>
</html>`);
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  const url = `http://localhost:${PORT}`;
  console.log(`✅ Server running! Opening Chrome at: ${url}`);
  exec(`start ${url}`);
});