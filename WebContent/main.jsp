<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="java.sql.*"%>
<%
  response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
  response.setHeader("Pragma", "no-cache");
  response.setDateHeader("Expires", 0);

  int totalUsers = 0, totalJournals = 0;
  try {
    Connection conn = db.DBUtil.getConnection();
    Statement stmt = conn.createStatement();
    ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM test.impormation");
    if (rs.next()) totalUsers = rs.getInt(1);
    rs.close();
    rs = stmt.executeQuery("SELECT COUNT(*) FROM test.`write`");
    if (rs.next()) totalJournals = rs.getInt(1);
    rs.close();
    stmt.close(); conn.close();
  } catch (Exception e) { e.printStackTrace(); }
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>TravelLog — 여행일지</title>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: 'Inter', sans-serif; overflow: hidden; height: 100vh; }
  #map { position: absolute; inset: 0; z-index: 0; }
  .map-overlay {
    position: absolute; inset: 0; z-index: 1;
    background: linear-gradient(135deg, rgba(10,15,35,0.72) 0%, rgba(20,40,100,0.38) 50%, rgba(10,15,35,0.65) 100%);
  }
  .nav-bar {
    position: absolute; top: 0; left: 0; right: 0; z-index: 10;
    display: flex; align-items: center; justify-content: space-between;
    padding: 20px 40px;
    background: rgba(255,255,255,0.04);
    backdrop-filter: blur(12px);
    border-bottom: 1px solid rgba(255,255,255,0.08);
  }
  .nav-logo { color: #fff; font-size: 22px; font-weight: 700; letter-spacing: -0.5px; }
  .nav-logo span { color: #60a5fa; }
  .nav-links { display: flex; gap: 10px; align-items: center; }
  .nav-btn-outline {
    padding: 8px 18px; border-radius: 9px; border: 1px solid rgba(255,255,255,0.25);
    background: rgba(255,255,255,0.07); color: rgba(255,255,255,0.85);
    font-size: 13px; font-weight: 500; text-decoration: none;
    transition: all 0.15s; font-family: 'Inter', sans-serif;
    backdrop-filter: blur(8px); cursor: pointer; display: inline-block;
  }
  .nav-btn-outline:hover { background: rgba(255,255,255,0.14); color: #fff; border-color: rgba(255,255,255,0.4); }
  .nav-btn-filled {
    padding: 8px 18px; border-radius: 9px; border: none;
    background: linear-gradient(135deg, #3b82f6, #1d4ed8); color: #fff;
    font-size: 13px; font-weight: 600; text-decoration: none;
    transition: all 0.15s; font-family: 'Inter', sans-serif;
    cursor: pointer; display: inline-block;
  }
  .nav-btn-filled:hover { box-shadow: 0 4px 16px rgba(59,130,246,0.5); transform: translateY(-1px); }

  .login-wrapper {
    position: absolute; inset: 0; z-index: 10;
    display: flex; align-items: center; justify-content: center;
    padding-top: 80px;
  }
  .login-card {
    background: rgba(255,255,255,0.07);
    backdrop-filter: blur(28px);
    border: 1px solid rgba(255,255,255,0.13);
    border-radius: 24px;
    padding: 48px 40px;
    width: 100%; max-width: 400px;
    box-shadow: 0 30px 60px rgba(0,0,0,0.45);
  }
  .login-card h2 { color: #fff; font-size: 28px; font-weight: 700; margin-bottom: 8px; }
  .login-card p { color: rgba(255,255,255,0.55); font-size: 14px; margin-bottom: 32px; }
  .form-group { margin-bottom: 14px; }
  .form-group input {
    width: 100%; padding: 14px 16px;
    background: rgba(255,255,255,0.07);
    border: 1px solid rgba(255,255,255,0.13);
    border-radius: 12px;
    color: #fff; font-size: 14px; font-family: 'Inter', sans-serif;
    outline: none; transition: border-color 0.2s, background 0.2s;
  }
  .form-group input::placeholder { color: rgba(255,255,255,0.35); }
  .form-group input:focus { border-color: #60a5fa; background: rgba(96,165,250,0.08); }
  .btn-login {
    width: 100%; padding: 14px;
    background: linear-gradient(135deg, #3b82f6, #1d4ed8);
    border: none; border-radius: 12px;
    color: #fff; font-size: 15px; font-weight: 600;
    cursor: pointer; margin-top: 8px;
    transition: transform 0.15s, box-shadow 0.15s;
    font-family: 'Inter', sans-serif;
  }
  .btn-login:hover { transform: translateY(-1px); box-shadow: 0 10px 28px rgba(59,130,246,0.5); }
  .login-footer { margin-top: 24px; text-align: center; color: rgba(255,255,255,0.45); font-size: 13px; }
  .login-footer a { color: #60a5fa; text-decoration: none; font-weight: 500; }

  .floating-stat {
    position: absolute; z-index: 10;
    background: rgba(255,255,255,0.07);
    backdrop-filter: blur(16px);
    border: 1px solid rgba(255,255,255,0.11);
    border-radius: 16px; padding: 16px 22px; color: #fff;
  }
  .stat-left { bottom: 40px; left: 40px; }
  .stat-right { bottom: 40px; right: 40px; }
  .stat-label { font-size: 10px; color: rgba(255,255,255,0.45); text-transform: uppercase; letter-spacing: 1.2px; margin-bottom: 6px; }
  .stat-value { font-size: 26px; font-weight: 700; color: #60a5fa; line-height: 1; }
  .stat-desc { font-size: 12px; color: rgba(255,255,255,0.5); margin-top: 4px; }

  .route-badge {
    position: absolute; bottom: 112px; left: 50%; transform: translateX(-50%);
    z-index: 10;
    background: rgba(255,255,255,0.09);
    backdrop-filter: blur(12px);
    border: 1px solid rgba(255,255,255,0.15);
    border-radius: 100px; padding: 10px 22px;
    color: #fff; font-size: 13px; font-weight: 500;
    display: flex; align-items: center; gap: 10px;
    white-space: nowrap;
  }
  .route-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
  .route-line { width: 48px; height: 2px; background: linear-gradient(90deg, #f59e0b, #60a5fa); border-radius: 2px; }

  @keyframes pulse {
    0%, 100% { transform: scale(1); opacity: 0.5; }
    50% { transform: scale(2); opacity: 0; }
  }
</style>
</head>
<body>

<div id="map"></div>
<div class="map-overlay"></div>

<nav class="nav-bar">
  <div class="nav-logo">Travel<span>Log</span></div>
  <div class="nav-links">
    <a href="sign_up.jsp" class="nav-btn-outline">회원가입</a>
    <a href="#" class="nav-btn-filled" onclick="focusLogin(); return false;">로그인</a>
  </div>
</nav>

<div class="login-wrapper">
  <div class="login-card">
    <h2>다시 만나요 ✈️</h2>
    <p>여행 일지에 로그인하고 여정을 이어가세요</p>
    <form method="post" action="login_Action.jsp">
      <div class="form-group">
        <input type="text" placeholder="아이디" name="id" maxlength="20" autocomplete="off">
      </div>
      <div class="form-group">
        <input type="password" placeholder="비밀번호" name="pw" maxlength="20">
      </div>
      <button type="submit" class="btn-login">로그인</button>
    </form>
    <div class="login-footer">
      처음이신가요? <a href="sign_up.jsp">회원가입하기</a>
    </div>
  </div>
</div>

<div class="floating-stat stat-left">
  <div class="stat-label">Total Travelers</div>
  <div class="stat-value"><%=totalUsers%></div>
  <div class="stat-desc">전 세계 여행자</div>
</div>
<div class="floating-stat stat-right">
  <div class="stat-label">Travel Journals</div>
  <div class="stat-value"><%=totalJournals%></div>
  <div class="stat-desc">등록된 여행 일지</div>
</div>

<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
const map = L.map('map', {
  zoomControl: false, attributionControl: false,
  scrollWheelZoom: false, dragging: false, doubleClickZoom: false
}).setView([30, 20], 2);

L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', { maxZoom: 19 }).addTo(map);

const users = [
  { lat: 37.5665, lng: 126.9780, name: 'J', count: 12, color: '#f59e0b' },
  { lat: 48.8566, lng: 2.3522,   name: 'M', count: 8,  color: '#60a5fa' },
  { lat: 35.6762, lng: 139.6503, name: 'K', count: 5,  color: '#34d399' },
  { lat: 40.7128, lng: -74.006,  name: 'A', count: 15, color: '#f472b6' },
  { lat: 51.5074, lng: -0.1278,  name: 'S', count: 7,  color: '#a78bfa' },
  { lat: -33.869, lng: 151.209,  name: 'T', count: 3,  color: '#fb923c' },
  { lat: 19.4326, lng: -99.133,  name: 'R', count: 9,  color: '#22d3ee' },
];

users.forEach(u => {
  const icon = L.divIcon({
    className: '',
    html: `<div style="position:relative;width:42px;height:42px;">
      <div style="width:36px;height:36px;border-radius:50%;background:${u.color};border:3px solid rgba(255,255,255,0.9);display:flex;align-items:center;justify-content:center;font-weight:700;font-size:14px;color:#0f172a;font-family:Inter,sans-serif;">${u.name}</div>
      <div style="position:absolute;top:-2px;right:-2px;background:#ef4444;border-radius:50%;width:18px;height:18px;display:flex;align-items:center;justify-content:center;font-size:9px;font-weight:700;color:#fff;border:2px solid #0f172a;">${u.count}</div>
    </div>`,
    iconSize: [42, 42], iconAnchor: [21, 21]
  });
  L.marker([u.lat, u.lng], { icon }).addTo(map);
});

function focusLogin() {
  const card = document.querySelector('.login-card');
  const idInput = document.querySelector('input[name="id"]');
  card.style.transition = 'box-shadow 0.3s, border-color 0.3s';
  card.style.boxShadow = '0 30px 60px rgba(0,0,0,0.55), 0 0 0 2px rgba(96,165,250,0.5)';
  card.style.borderColor = 'rgba(96,165,250,0.5)';
  idInput.focus();
  setTimeout(() => {
    card.style.boxShadow = '0 30px 60px rgba(0,0,0,0.45)';
    card.style.borderColor = 'rgba(255,255,255,0.13)';
  }, 1800);
}
</script>
</body>
</html>
