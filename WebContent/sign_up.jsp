<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>TravelLog — 회원가입</title>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: 'Inter', sans-serif; overflow: hidden; height: 100vh; }
  #map { position: absolute; inset: 0; z-index: 0; }
  .map-overlay {
    position: absolute; inset: 0; z-index: 1;
    background: linear-gradient(135deg, rgba(10,15,35,0.75) 0%, rgba(20,40,100,0.4) 50%, rgba(10,15,35,0.68) 100%);
  }
  .nav-bar {
    position: absolute; top: 0; left: 0; right: 0; z-index: 10;
    display: flex; align-items: center; justify-content: space-between;
    padding: 20px 40px;
    background: rgba(255,255,255,0.04);
    backdrop-filter: blur(12px);
    border-bottom: 1px solid rgba(255,255,255,0.08);
  }
  .nav-logo { color: #fff; font-size: 22px; font-weight: 700; }
  .nav-logo span { color: #60a5fa; }
  .nav-links a {
    color: rgba(255,255,255,0.7); text-decoration: none;
    margin-left: 24px; font-size: 14px; font-weight: 500; transition: color 0.2s;
  }
  .nav-links a:hover { color: #fff; }
  .nav-links a.active { color: #60a5fa; }

  .signup-wrapper {
    position: absolute; inset: 0; z-index: 10;
    display: flex; align-items: center; justify-content: center;
    padding-top: 80px; overflow-y: auto;
  }
  .signup-card {
    background: rgba(255,255,255,0.07);
    backdrop-filter: blur(28px);
    border: 1px solid rgba(255,255,255,0.13);
    border-radius: 24px;
    padding: 44px 40px;
    width: 100%; max-width: 440px;
    box-shadow: 0 30px 60px rgba(0,0,0,0.45);
    margin: 20px;
  }
  .signup-card h2 { color: #fff; font-size: 26px; font-weight: 700; margin-bottom: 6px; }
  .signup-card p { color: rgba(255,255,255,0.5); font-size: 13px; margin-bottom: 28px; }

  .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 10px; }
  .form-group { margin-bottom: 10px; }
  .form-group label { display: block; font-size: 11px; color: rgba(255,255,255,0.5); text-transform: uppercase; letter-spacing: 0.8px; margin-bottom: 6px; }
  .form-group input,
  .form-group select {
    width: 100%; padding: 12px 14px;
    background: rgba(255,255,255,0.07);
    border: 1px solid rgba(255,255,255,0.12);
    border-radius: 10px;
    color: #fff; font-size: 14px; font-family: 'Inter', sans-serif;
    outline: none; transition: border-color 0.2s, background 0.2s;
    appearance: none;
  }
  .form-group input::placeholder { color: rgba(255,255,255,0.3); }
  .form-group input:focus,
  .form-group select:focus { border-color: #60a5fa; background: rgba(96,165,250,0.08); }
  .form-group select option { background: #1e293b; color: #fff; }

  .btn-signup {
    width: 100%; padding: 14px;
    background: linear-gradient(135deg, #3b82f6, #1d4ed8);
    border: none; border-radius: 12px;
    color: #fff; font-size: 15px; font-weight: 600;
    cursor: pointer; margin-top: 6px;
    transition: transform 0.15s, box-shadow 0.15s;
    font-family: 'Inter', sans-serif;
  }
  .btn-signup:hover { transform: translateY(-1px); box-shadow: 0 10px 28px rgba(59,130,246,0.5); }
  .signup-footer { margin-top: 20px; text-align: center; color: rgba(255,255,255,0.45); font-size: 13px; }
  .signup-footer a { color: #60a5fa; text-decoration: none; font-weight: 500; }

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
    <a href="main.jsp">로그인</a>
    <a href="sign_up.jsp" class="active">회원가입</a>
  </div>
</nav>

<div class="signup-wrapper">
  <div class="signup-card">
    <h2>여정을 시작하세요 🌍</h2>
    <p>계정을 만들고 전 세계 여행자들과 함께하세요</p>
    <form method="post" action="sign_up_Action.jsp">
      <div class="form-group">
        <label>아이디</label>
        <input type="text" placeholder="사용할 아이디 입력" name="id" maxlength="20" autocomplete="off">
      </div>
      <div class="form-group">
        <label>비밀번호</label>
        <input type="password" placeholder="비밀번호 입력" name="pw" maxlength="20">
      </div>
      <div class="form-row">
        <div class="form-group">
          <label>이름</label>
          <input type="text" placeholder="이름" name="name" maxlength="20">
        </div>
        <div class="form-group">
          <label>나이</label>
          <input type="text" placeholder="나이" name="age" maxlength="5">
        </div>
      </div>
      <div class="form-row">
        <div class="form-group">
          <label>성별</label>
          <select name="gender">
            <option value="" disabled selected>선택</option>
            <option value="남">남</option>
            <option value="여">여</option>
          </select>
        </div>
        <div class="form-group">
          <label>주소</label>
          <input type="text" placeholder="거주 도시" name="addr" maxlength="50">
        </div>
      </div>
      <button type="submit" class="btn-signup">회원가입</button>
    </form>
    <div class="signup-footer">
      이미 계정이 있으신가요? <a href="main.jsp">로그인하기</a>
    </div>
  </div>
</div>

<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
const map = L.map('map', {
  zoomControl: false, attributionControl: false,
  scrollWheelZoom: false, dragging: false, doubleClickZoom: false
}).setView([20, 10], 2);

L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', { maxZoom: 19 }).addTo(map);

const destinations = [
  [37.5665, 126.978], [48.8566, 2.3522], [35.6762, 139.650],
  [40.7128, -74.006], [51.5074, -0.128], [-33.869, 151.209],
  [19.4326, -99.133], [1.3521, 103.820], [25.2048, 55.2708]
];

destinations.forEach(([lat, lng]) => {
  L.marker([lat, lng], { icon: L.divIcon({
    className: '',
    html: `<div style="width:10px;height:10px;border-radius:50%;background:#60a5fa;border:2px solid rgba(255,255,255,0.7);position:relative;">
      <div style="position:absolute;inset:-4px;border-radius:50%;background:rgba(96,165,250,0.3);animation:pulse 2.5s infinite;"></div>
    </div>`,
    iconSize: [10, 10], iconAnchor: [5, 5]
  })}).addTo(map);
});
</script>
</body>
</html>
