<!DOCTYPE html>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.util.Calendar"%>
<%@page import="java.sql.*"%>
<%@ page contentType="text/html; charset=utf-8" isELIgnored="true"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<%
  response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
  response.setHeader("Pragma", "no-cache");
  response.setDateHeader("Expires", 0);
  if (session.getAttribute("loginUser") == null) {
    response.sendRedirect("main.jsp");
    return;
  }
  Calendar cal = Calendar.getInstance();
  String strYear = request.getParameter("year");
  String strMonth = request.getParameter("month");
  int year = cal.get(Calendar.YEAR);
  int month = cal.get(Calendar.MONTH);
  if (strYear != null) { year = Integer.parseInt(strYear); month = Integer.parseInt(strMonth); }
  cal.set(year, month, 1);
  int endDay = cal.getActualMaximum(java.util.Calendar.DAY_OF_MONTH);
  int start = cal.get(java.util.Calendar.DAY_OF_WEEK);
  int newLine = 0;
  Calendar todayCal = Calendar.getInstance();
  SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd");
  int intToday = Integer.parseInt(sdf.format(todayCal.getTime()));

  int userCount = 0, journalCount = 0, countryCount = 0;
  StringBuilder countryJson = new StringBuilder("[");
  StringBuilder journalJson = new StringBuilder("[");

  try {
    Connection conn = db.DBUtil.getConnection();
    Statement stmt = conn.createStatement();

    ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM test.impormation");
    if (rs.next()) userCount = rs.getInt(1);
    rs.close();

    rs = stmt.executeQuery("SELECT COUNT(*) FROM test.`write`");
    if (rs.next()) journalCount = rs.getInt(1);
    rs.close();

    rs = stmt.executeQuery("SELECT trip, COUNT(*) as cnt FROM test.`write` WHERE trip IS NOT NULL AND trip!='' GROUP BY trip");
    boolean first = true;
    while (rs.next()) {
      countryCount++;
      if (!first) countryJson.append(",");
      String t = rs.getString("trip").replace("\\","\\\\").replace("\"","\\\"");
      countryJson.append("{\"name\":\"").append(t).append("\",\"count\":").append(rs.getInt("cnt")).append("}");
      first = false;
    }
    rs.close();

    String calLoginUser = (String) session.getAttribute("loginUser");
    rs = stmt.executeQuery("SELECT trip, title, memo, image, DATE_FORMAT(sysdate,'%Y-%m-%d %H:%i') as dt, DATE_FORMAT(sysdate,'%Y-%m-%d %H:%i:%S') as ts, IFNULL(id,'') as writer FROM test.`write` ORDER BY sysdate DESC");
    first = true;
    while (rs.next()) {
      if (!first) journalJson.append(",");
      String t  = rs.getString("trip")   == null ? "" : rs.getString("trip").replace("\\","\\\\").replace("\"","\\\"");
      String ti = rs.getString("title")  == null ? "" : rs.getString("title").replace("\\","\\\\").replace("\"","\\\"");
      String me = rs.getString("memo")   == null ? "" : rs.getString("memo").replace("\\","\\\\").replace("\"","\\\"").replace("\n","\\n").replace("\r","");
      String im = rs.getString("image")  == null ? "" : rs.getString("image").replace("\"","\\\"");
      String dt = rs.getString("dt")     == null ? "" : rs.getString("dt");
      String wr = rs.getString("writer") == null ? "" : rs.getString("writer").replace("\\","\\\\").replace("\"","\\\"");
      String tsC = rs.getString("ts") == null ? "" : rs.getString("ts");
      boolean isMineC = calLoginUser != null && calLoginUser.equals(rs.getString("writer"));
      journalJson.append("{\"ts\":\"").append(tsC.replace("\"","\\\""))
                 .append("\",\"trip\":\"").append(t)
                 .append("\",\"title\":\"").append(ti)
                 .append("\",\"memo\":\"").append(me)
                 .append("\",\"image\":\"").append(im)
                 .append("\",\"date\":\"").append(dt)
                 .append("\",\"writer\":\"").append(wr)
                 .append("\",\"mine\":").append(isMineC).append("}");
      first = false;
    }
    rs.close(); stmt.close(); conn.close();
  } catch (Exception e) { e.printStackTrace(); }
  countryJson.append("]");
  journalJson.append("]");
%>

<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>TravelLog — 탐험하기</title>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: 'Inter', sans-serif; overflow: hidden; height: 100vh; background: #0f172a; }
  #map { position: absolute; inset: 0; z-index: 0; }

  .nav-bar {
    position: absolute; top: 0; left: 0; right: 0; z-index: 100;
    display: flex; align-items: center; justify-content: space-between;
    padding: 14px 28px; background: rgba(10,15,35,0.7);
    backdrop-filter: blur(16px); border-bottom: 1px solid rgba(255,255,255,0.08);
  }
  .nav-logo { color: #fff; font-size: 20px; font-weight: 700; }
  .nav-logo span { color: #60a5fa; }
  .nav-actions { display: flex; align-items: center; gap: 10px; }
  .nav-btn {
    padding: 8px 18px; border-radius: 8px; border: none;
    font-size: 13px; font-weight: 500; cursor: pointer;
    font-family: 'Inter', sans-serif; transition: all 0.15s;
  }
  .nav-btn-blue { background: linear-gradient(135deg,#3b82f6,#1d4ed8); color: #fff; }
  .nav-btn-blue:hover { box-shadow: 0 4px 16px rgba(59,130,246,0.5); transform: translateY(-1px); }
  .nav-btn-ghost { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.8); border: 1px solid rgba(255,255,255,0.12); }
  .nav-btn-ghost:hover { background: rgba(255,255,255,0.14); color: #fff; }

  /* CALENDAR — 70% 크기 */
  .calendar-panel {
    position: absolute; top: 62px; left: 20px; z-index: 100;
    background: rgba(10,15,35,0.85); backdrop-filter: blur(24px);
    border: 1px solid rgba(255,255,255,0.11); border-radius: 16px;
    padding: 17px; width: 268px;
    box-shadow: 0 20px 40px rgba(0,0,0,0.45);
  }
  .cal-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
  .cal-title { color: #fff; font-size: 13px; font-weight: 700; }
  .cal-nav-btn {
    background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.1);
    color: rgba(255,255,255,0.7); border-radius: 6px; width: 24px; height: 24px;
    cursor: pointer; font-size: 12px; display: flex; align-items: center; justify-content: center;
    text-decoration: none; transition: background 0.15s;
  }
  .cal-nav-btn:hover { background: rgba(255,255,255,0.16); color: #fff; }
  .cal-grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 2px; }
  .cal-day-name { text-align: center; font-size: 9px; font-weight: 600; color: rgba(255,255,255,0.35); padding: 4px 0; }
  .cal-day-name.sun { color: #f87171; }
  .cal-day-name.sat { color: #60a5fa; }
  .cal-day {
    text-align: center; padding: 6px 2px; font-size: 10px;
    color: rgba(255,255,255,0.75); border-radius: 6px; cursor: pointer; transition: background 0.15s;
  }
  .cal-day:hover { background: rgba(96,165,250,0.2); color: #fff; }
  .cal-day.today { background: #3b82f6; color: #fff; font-weight: 700; }
  .cal-day.sun { color: #f87171; }
  .cal-day.sat { color: #60a5fa; }
  .cal-day.empty { cursor: default; }
  .cal-day.empty:hover { background: none; }

  /* LOCATION CARD */
  .location-card {
    position: absolute; bottom: 28px; left: 20px; z-index: 100;
    background: rgba(10,15,35,0.82); backdrop-filter: blur(20px);
    border: 1px solid rgba(255,255,255,0.1); border-radius: 18px; padding: 16px 20px; width: 270px;
    box-shadow: 0 16px 32px rgba(0,0,0,0.35);
  }
  .card-label { font-size: 10px; color: rgba(255,255,255,0.4); text-transform: uppercase; letter-spacing: 1px; margin-bottom: 8px; }
  .location-info { display: flex; align-items: center; gap: 10px; }
  .location-icon {
    width: 38px; height: 38px; border-radius: 10px;
    background: linear-gradient(135deg,#3b82f6,#1d4ed8);
    display: flex; align-items: center; justify-content: center; font-size: 18px; flex-shrink: 0;
  }
  .location-city { font-size: 15px; font-weight: 600; color: #fff; }
  .location-country { font-size: 11px; color: rgba(255,255,255,0.5); margin-top: 2px; }
  .location-coords { font-size: 10px; color: rgba(255,255,255,0.3); margin-top: 8px; font-family: monospace; }

  /* STATS */
  .stats-row { position: absolute; bottom: 28px; right: 20px; z-index: 100; display: flex; gap: 10px; }
  .stat-pill {
    background: rgba(10,15,35,0.82); backdrop-filter: blur(16px);
    border: 1px solid rgba(255,255,255,0.1); border-radius: 14px; padding: 14px 20px;
    text-align: center; box-shadow: 0 8px 20px rgba(0,0,0,0.3); min-width: 80px;
  }
  .stat-pill-value { color: #60a5fa; font-size: 22px; font-weight: 700; line-height: 1; }
  .stat-pill-label { color: rgba(255,255,255,0.4); font-size: 11px; margin-top: 4px; }

  /* 일지 사이드 패널 */
  .journal-panel {
    position: absolute; top: 62px; right: 0; bottom: 0; z-index: 200;
    width: 360px; background: rgba(10,15,35,0.95); backdrop-filter: blur(24px);
    border-left: 1px solid rgba(255,255,255,0.1);
    transform: translateX(100%); transition: transform 0.3s cubic-bezier(0.4,0,0.2,1);
    display: flex; flex-direction: column; overflow: hidden;
  }
  .journal-panel.open { transform: translateX(0); }
  .panel-header {
    padding: 20px 24px 16px; border-bottom: 1px solid rgba(255,255,255,0.08);
    display: flex; align-items: center; justify-content: space-between; flex-shrink: 0;
  }
  .panel-country { font-size: 18px; font-weight: 700; color: #fff; }
  .panel-close {
    width: 32px; height: 32px; border-radius: 8px; background: rgba(255,255,255,0.08);
    border: none; color: rgba(255,255,255,0.6); font-size: 16px;
    cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.15s;
  }
  .panel-close:hover { background: rgba(255,255,255,0.15); color: #fff; }
  .panel-filter {
    display: flex; gap: 6px; padding: 10px 16px 0;
    flex-shrink: 0; border-bottom: 1px solid rgba(255,255,255,0.06); padding-bottom: 10px;
  }
  .panel-filter-btn {
    flex: 1; padding: 6px 0; border-radius: 16px; border: 1px solid rgba(255,255,255,0.1);
    background: rgba(255,255,255,0.05); color: rgba(255,255,255,0.5);
    font-size: 11px; font-weight: 600; cursor: pointer;
    font-family: 'Inter', sans-serif; transition: all 0.18s; text-align: center;
  }
  .panel-filter-btn:hover { background: rgba(255,255,255,0.1); color: #fff; }
  .panel-filter-btn.pf-all   { background: rgba(255,255,255,0.12); color: #fff; border-color: rgba(255,255,255,0.25); }
  .panel-filter-btn.pf-mine  { background: rgba(52,211,153,0.18); color: #34d399; border-color: rgba(52,211,153,0.4); }
  .panel-filter-btn.pf-other { background: rgba(96,165,250,0.18); color: #60a5fa; border-color: rgba(96,165,250,0.4); }
  .panel-body { flex: 1; overflow-y: auto; padding: 16px; }
  .panel-body::-webkit-scrollbar { width: 5px; }
  .panel-body::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.12); border-radius: 3px; }

  .journal-item {
    background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.08);
    border-radius: 14px; overflow: hidden; margin-bottom: 12px;
    transition: border-color 0.2s, transform 0.15s; cursor: pointer;
  }
  .journal-item:hover { border-color: rgba(96,165,250,0.3); transform: translateY(-2px); }
  .journal-item-img { width: 100%; height: 120px; background: #1e3a5f; display: flex; align-items: center; justify-content: center; font-size: 36px; overflow: hidden; }
  .journal-item-img img { width: 100%; height: 100%; object-fit: cover; }
  .journal-item-body { padding: 14px; }
  .journal-item-title { font-size: 14px; font-weight: 600; color: #fff; margin-bottom: 6px; }
  .journal-item-memo {
    font-size: 12px; color: rgba(255,255,255,0.45); line-height: 1.6;
    display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
  }
  .journal-item-footer { display: flex; align-items: center; justify-content: space-between; margin-top: 8px; }
  .journal-item-date { font-size: 11px; color: rgba(255,255,255,0.28); }
  .journal-item-writer { font-size: 10px; font-weight: 600; padding: 2px 7px; border-radius: 20px; background: rgba(96,165,250,0.15); color: #60a5fa; }
  .journal-item-writer.mine { background: rgba(52,211,153,0.15); color: #34d399; }
  .mine-item { border-color: rgba(52,211,153,0.3) !important; }
  .journal-item-more {
    font-size: 11px; color: #60a5fa; margin-top: 6px; font-weight: 500;
  }
  .panel-empty { text-align: center; padding: 60px 20px; color: rgba(255,255,255,0.3); font-size: 14px; }

  /* ── 전체화면 상세보기 ── */
  .detail-screen {
    display: none; position: fixed; inset: 0; z-index: 500;
    background: #0b1120; overflow-y: auto;
    animation: fadeIn 0.22s ease;
  }
  .detail-screen.open { display: block; }
  @keyframes fadeIn { from { opacity:0; } to { opacity:1; } }

  .detail-top-bar {
    position: sticky; top: 0; z-index: 10;
    display: flex; align-items: center; gap: 14px;
    padding: 14px 24px; background: rgba(11,17,32,0.92);
    border-bottom: 1px solid rgba(255,255,255,0.08); backdrop-filter: blur(12px);
  }
  .detail-back-btn {
    padding: 8px 16px; border-radius: 10px;
    background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.12);
    color: rgba(255,255,255,0.8); font-size: 13px; font-weight: 500;
    cursor: pointer; font-family: 'Inter', sans-serif; transition: all 0.15s;
  }
  .detail-back-btn:hover { background: rgba(255,255,255,0.14); color: #fff; }
  .detail-bar-title { font-size: 15px; font-weight: 600; color: rgba(255,255,255,0.7); }

  .detail-hero {
    width: 100%; height: 55vh; min-height: 280px;
    background: linear-gradient(135deg,#1e3a5f,#0f2144);
    display: flex; align-items: center; justify-content: center; font-size: 100px;
    overflow: hidden;
  }
  .detail-hero img { width: 100%; height: 100%; object-fit: cover; }

  .detail-body { max-width: 780px; margin: 0 auto; padding: 40px 32px 80px; }
  .detail-dest-badge {
    display: inline-flex; align-items: center; gap: 6px;
    font-size: 12px; color: #60a5fa; font-weight: 700;
    text-transform: uppercase; letter-spacing: 1px;
    background: rgba(96,165,250,0.1); border-radius: 8px;
    padding: 5px 12px; margin-bottom: 18px;
  }
  .detail-title { font-size: 32px; font-weight: 800; line-height: 1.25; margin-bottom: 12px; color: #fff; }
  .detail-writer { font-size: 13px; color: rgba(255,255,255,0.45); margin-bottom: 6px; }
  .detail-writer span { font-weight: 700; color: #60a5fa; }
  .detail-writer.mine span { color: #34d399; }
  .detail-date { font-size: 13px; color: rgba(255,255,255,0.35); margin-bottom: 32px; }
  .detail-divider { border: none; border-top: 1px solid rgba(255,255,255,0.08); margin-bottom: 32px; }
  .detail-memo { font-size: 17px; color: rgba(255,255,255,0.8); line-height: 1.9; white-space: pre-wrap; }
  .detail-actions { display: flex; gap: 10px; margin-top: 32px; }
  .detail-action-btn { padding: 10px 22px; border-radius: 10px; border: none; font-size: 13px; font-weight: 600; cursor: pointer; font-family: 'Inter', sans-serif; transition: all 0.15s; }
  .detail-edit-btn { background: rgba(96,165,250,0.15); color: #60a5fa; border: 1px solid rgba(96,165,250,0.3); }
  .detail-edit-btn:hover { background: rgba(96,165,250,0.28); }
  .detail-del-btn  { background: rgba(239,68,68,0.12); color: #f87171; border: 1px solid rgba(239,68,68,0.3); }
  .detail-del-btn:hover  { background: rgba(239,68,68,0.25); }

  @keyframes pulse {
    0%, 100% { transform: scale(1); opacity: 0.5; }
    50% { transform: scale(2.5); opacity: 0; }
  }
</style>
</head>
<body>

<div id="map"></div>

<nav class="nav-bar">
  <div class="nav-logo">Travel<span>Log</span></div>
  <div class="nav-actions">
    <button class="nav-btn nav-btn-blue" onclick="location.href='List.jsp'">📋 게시판</button>
    <button class="nav-btn nav-btn-ghost" onclick="location.href='profile.jsp'" title="내 정보">👤</button>
    <button class="nav-btn nav-btn-ghost" onclick="location.href='logout.jsp'">로그아웃</button>
  </div>
</nav>

<!-- CALENDAR -->
<div class="calendar-panel">
  <div class="cal-header">
    <a class="cal-nav-btn" href="<c:url value='/Calendar.jsp'/>?year=<%=month==0?year-1:year%>&month=<%=month==0?11:month-1%>">‹</a>
    <span class="cal-title"><%=year%>년 <%=month+1%>월</span>
    <a class="cal-nav-btn" href="<c:url value='/Calendar.jsp'/>?year=<%=month==11?year+1:year%>&month=<%=month==11?0:month+1%>">›</a>
  </div>
  <div class="cal-grid">
    <div class="cal-day-name sun">일</div>
    <div class="cal-day-name">월</div>
    <div class="cal-day-name">화</div>
    <div class="cal-day-name">수</div>
    <div class="cal-day-name">목</div>
    <div class="cal-day-name">금</div>
    <div class="cal-day-name sat">토</div>
    <%
      for (int i=1;i<start;i++){out.println("<div class='cal-day empty'></div>");newLine++;}
      for (int i=1;i<=endDay;i++){
        String sd=Integer.toString(year);
        sd+=Integer.toString(month+1).length()==1?"0"+Integer.toString(month+1):Integer.toString(month+1);
        sd+=Integer.toString(i).length()==1?"0"+Integer.toString(i):Integer.toString(i);
        boolean isTd=(Integer.parseInt(sd)==intToday);
        String cls="cal-day";
        if(isTd)cls+=" today";
        else if(newLine%7==0)cls+=" sun";
        else if(newLine%7==6)cls+=" sat";
        out.println("<div class='"+cls+"' onclick=\"location.href='write.jsp'\">"+i+"</div>");
        newLine++;
      }
    %>
  </div>
</div>

<!-- LOCATION CARD -->
<div class="location-card">
  <div class="card-label">My Current Location</div>
  <div class="location-info">
    <div class="location-icon">📍</div>
    <div>
      <div class="location-city" id="locCity">불러오는 중...</div>
      <div class="location-country" id="locCountry"></div>
    </div>
  </div>
  <div class="location-coords" id="locCoords"></div>
</div>

<!-- STATS -->
<div class="stats-row">
  <div class="stat-pill">
    <div class="stat-pill-value"><%=userCount%></div>
    <div class="stat-pill-label">여행자</div>
  </div>
  <div class="stat-pill">
    <div class="stat-pill-value"><%=journalCount%></div>
    <div class="stat-pill-label">일지</div>
  </div>
  <div class="stat-pill">
    <div class="stat-pill-value"><%=countryCount%></div>
    <div class="stat-pill-label">국가</div>
  </div>
</div>

<!-- 일지 사이드 패널 -->
<div class="journal-panel" id="journalPanel">
  <div class="panel-header">
    <div class="panel-country" id="panelCountry"></div>
    <button class="panel-close" onclick="closePanel()">✕</button>
  </div>
  <div class="panel-filter">
    <button class="panel-filter-btn pf-all"   id="pfAll"   onclick="setPanelFilter('all')">🌍 전체</button>
    <button class="panel-filter-btn"           id="pfMine"  onclick="setPanelFilter('mine')">✦ 내 글</button>
    <button class="panel-filter-btn"           id="pfOther" onclick="setPanelFilter('other')">👥 다른 사람</button>
  </div>
  <div class="panel-body" id="panelBody"></div>
</div>

<!-- 전체화면 상세보기 -->
<div class="detail-screen" id="detailScreen">
  <div class="detail-top-bar">
    <button class="detail-back-btn" onclick="closeDetail()">← 돌아가기</button>
    <span class="detail-bar-title" id="detailBarTitle"></span>
  </div>
  <div class="detail-hero" id="detailHero"></div>
  <div class="detail-body">
    <div class="detail-dest-badge" id="detailDest"></div>
    <div class="detail-title" id="detailTitle"></div>
    <div class="detail-writer" id="detailWriter"></div>
    <div class="detail-date" id="detailDate"></div>
    <hr class="detail-divider">
    <div class="detail-memo" id="detailMemo"></div>
    <div class="detail-actions" id="detailActions" style="display:none">
      <button class="detail-action-btn detail-edit-btn" id="detailEditBtn">✏️ 수정하기</button>
      <button class="detail-action-btn detail-del-btn"  id="detailDelBtn" >🗑️ 삭제하기</button>
    </div>
  </div>
</div>

<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
const map = L.map('map', { zoomControl: false, attributionControl: false, minZoom: 2 }).setView([20,10],2);
L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',{maxZoom:10,minZoom:2}).addTo(map);

// 전 세계 국가 좌표
const COUNTRY_COORDS = {
  "서울":[37.5665,126.978],"부산":[35.1796,129.075],"대구":[35.8714,128.602],
  "인천":[37.4563,126.705],"광주":[35.1595,126.852],"대전":[36.3504,127.385],
  "울산":[35.5384,129.311],"세종":[36.4800,127.289],"수원":[37.2636,127.029],
  "성남":[37.4201,127.126],"고양":[37.6584,126.832],"용인":[37.2411,127.177],
  "창원":[35.2278,128.681],"청주":[36.6424,127.489],"전주":[35.8242,127.148],
  "천안":[36.8151,127.114],"제주도":[33.4996,126.531],"강릉":[37.7519,128.876],
  "경주":[35.8562,129.225],"속초":[38.2070,128.592],"여수":[34.7604,127.662],
  "포항":[36.0190,129.343],"경기도":[37.2750,127.009],"강원도":[37.8228,128.153],
  "충청북도":[36.6357,127.491],"충청남도":[36.5184,126.800],"전라북도":[35.7175,127.153],
  "전라남도":[34.8679,126.991],"경상북도":[36.4919,128.889],"경상남도":[35.4606,128.213],
  "대한민국":[37.5665,126.978],"일본":[35.6762,139.650],"중국":[35.8617,104.195],
  "홍콩":[22.319,114.169],"대만":[23.697,120.960],"몽골":[46.862,103.846],
  "태국":[13.756,100.501],"베트남":[14.058,108.277],"인도네시아":[-0.789,113.921],
  "말레이시아":[4.210,101.975],"필리핀":[12.879,121.774],"싱가포르":[1.352,103.819],
  "캄보디아":[12.565,104.991],"미얀마":[21.916,95.956],"라오스":[17.967,102.600],
  "브루나이":[4.535,114.727],"동티모르":[-8.874,125.727],
  "인도":[20.593,78.962],"파키스탄":[30.375,69.345],"방글라데시":[23.685,90.356],
  "스리랑카":[7.873,80.771],"네팔":[28.394,84.124],"부탄":[27.514,90.433],
  "몰디브":[3.202,73.220],"아프가니스탄":[33.939,67.710],
  "카자흐스탄":[48.019,66.923],"우즈베키스탄":[41.377,64.585],
  "키르기스스탄":[41.204,74.766],"타지키스탄":[38.861,71.276],
  "투르크메니스탄":[38.969,59.556],
  "터키":[38.963,35.243],"UAE":[23.424,53.847],"사우디아라비아":[23.886,45.079],
  "카타르":[25.354,51.183],"쿠웨이트":[29.375,47.979],"바레인":[26.066,50.558],
  "오만":[21.473,55.975],"이스라엘":[31.046,34.851],"요르단":[30.585,36.238],
  "레바논":[33.888,35.495],"이란":[32.427,53.688],"이라크":[33.224,43.679],
  "시리아":[34.802,38.996],"예멘":[15.552,48.516],
  "조지아":[42.315,43.356],"아르메니아":[40.069,45.038],"아제르바이잔":[40.143,47.576],
  "프랑스":[48.8566,2.3522],"영국":[51.5074,-0.127],"독일":[52.520,13.405],
  "이탈리아":[41.902,12.496],"스페인":[40.416,-3.703],"포르투갈":[39.399,-8.224],
  "네덜란드":[52.132,5.291],"벨기에":[50.503,4.469],"스위스":[46.818,8.227],
  "오스트리아":[47.516,14.550],"아일랜드":[53.412,-8.243],"룩셈부르크":[49.815,6.129],
  "모나코":[43.750,7.424],"안도라":[42.546,1.601],"리히텐슈타인":[47.141,9.524],
  "몰타":[35.937,14.375],"사이프러스":[35.126,33.430],
  "노르웨이":[60.472,8.468],"스웨덴":[60.128,18.643],"덴마크":[56.263,9.501],
  "핀란드":[61.924,25.748],"아이슬란드":[64.963,-19.020],
  "에스토니아":[58.595,25.014],"라트비아":[56.879,24.604],"리투아니아":[55.169,23.881],
  "러시아":[61.524,105.318],"우크라이나":[48.379,31.165],"폴란드":[51.919,19.145],
  "체코":[49.817,15.472],"슬로바키아":[48.669,19.699],"헝가리":[47.162,19.503],
  "루마니아":[45.943,24.966],"불가리아":[42.733,25.486],
  "벨라루스":[53.709,27.953],"몰도바":[47.411,28.369],
  "그리스":[39.074,21.824],"크로아티아":[45.100,15.200],"세르비아":[44.017,21.006],
  "슬로베니아":[46.151,14.995],"보스니아헤르체고비나":[43.915,17.679],
  "알바니아":[41.153,20.168],"북마케도니아":[41.608,21.745],
  "몬테네그로":[42.708,19.374],"코소보":[42.602,20.903],"산마리노":[43.942,12.457],
  "미국":[37.0902,-95.712],"캐나다":[56.130,-106.346],"멕시코":[23.634,-102.552],
  "쿠바":[21.521,-77.781],"자메이카":[18.109,-77.297],
  "도미니카공화국":[18.736,-70.163],"아이티":[18.971,-72.285],
  "파나마":[8.537,-80.782],"코스타리카":[9.748,-83.753],
  "과테말라":[15.783,-90.231],"온두라스":[15.200,-86.242],
  "엘살바도르":[13.794,-88.896],"니카라과":[12.865,-85.208],
  "벨리즈":[17.189,-88.497],"트리니다드토바고":[10.692,-61.223],
  "바하마":[25.025,-77.396],"바베이도스":[13.193,-59.543],
  "브라질":[-14.235,-51.925],"아르헨티나":[-38.416,-63.616],"칠레":[-35.675,-71.543],
  "페루":[-9.190,-75.015],"콜롬비아":[4.570,-74.297],"베네수엘라":[6.424,-66.590],
  "에콰도르":[-1.831,-78.183],"볼리비아":[-16.290,-63.589],
  "파라과이":[-23.442,-58.444],"우루과이":[-32.522,-55.765],
  "가이아나":[4.860,-58.930],"수리남":[3.919,-56.028],
  "호주":[-25.274,133.775],"뉴질랜드":[-40.900,174.886],
  "파푸아뉴기니":[-6.315,143.956],"피지":[-17.713,178.065],
  "솔로몬제도":[-9.645,160.156],"바누아투":[-15.377,166.959],
  "사모아":[-13.759,-172.104],"통가":[-21.178,-175.198],
  "팔라우":[7.514,134.582],"키리바시":[-3.370,-168.734],"투발루":[-7.109,179.194],
  "이집트":[26.820,30.802],"모로코":[31.791,-7.092],"알제리":[28.033,1.659],
  "튀니지":[33.886,9.537],"리비아":[26.335,17.228],"수단":[12.862,30.218],
  "나이지리아":[9.082,8.675],"가나":[7.946,-1.023],"세네갈":[14.497,-14.452],
  "코트디부아르":[7.539,-5.547],"카메룬":[3.848,11.502],"말리":[17.570,-3.996],
  "부르키나파소":[12.364,-1.562],"기니":[9.946,-9.696],"토고":[8.620,0.825],
  "베냉":[9.308,2.315],"시에라리온":[8.460,-11.779],"감비아":[13.443,-15.310],
  "라이베리아":[6.428,-9.429],"모리타니":[21.007,-10.940],"니제르":[17.608,8.082],
  "카보베르데":[16.002,-24.013],
  "에티오피아":[9.145,40.489],"케냐":[-0.023,37.906],"탄자니아":[-6.369,34.889],
  "우간다":[1.373,32.290],"르완다":[-1.940,29.874],"소말리아":[5.152,46.199],
  "지부티":[11.825,42.590],"에리트레아":[15.179,39.782],"남수단":[6.877,31.307],
  "부룬디":[-3.373,29.919],"모잠비크":[-18.665,35.530],"마다가스카르":[-18.767,46.869],
  "모리셔스":[-20.348,57.552],"세이셸":[-4.679,55.492],"코모로":[-11.875,43.872],
  "차드":[15.454,18.732],"중앙아프리카공화국":[6.611,20.939],
  "콩고공화국":[-0.228,15.827],"콩고민주공화국":[-4.038,21.759],
  "가봉":[-0.803,11.609],"적도기니":[1.650,10.267],
  "남아프리카":[-30.559,22.937],"나미비아":[-22.957,18.490],
  "보츠와나":[-22.328,24.684],"짐바브웨":[-19.015,29.154],
  "잠비아":[-13.133,27.849],"말라위":[-13.254,34.302],"앙골라":[-11.202,17.873],
  "레소토":[-29.610,28.233],"에스와티니":[-26.522,31.466],
};

const COLORS = ['#f59e0b','#60a5fa','#34d399','#f472b6','#a78bfa','#fb923c','#22d3ee','#10b981','#e879f9','#38bdf8'];
const dbCountries = <%=countryJson%>;
const allJournals = <%=journalJson%>;

dbCountries.forEach((c, i) => {
  const coords = COUNTRY_COORDS[c.name];
  if (!coords) return;
  const color = COLORS[i % COLORS.length];

  const marker = L.marker(coords, { icon: L.divIcon({
    className: '',
    html: `<div style="position:relative;width:46px;height:46px;cursor:pointer;">
      <div style="width:38px;height:38px;border-radius:50%;background:${color};border:3px solid rgba(255,255,255,0.9);display:flex;align-items:center;justify-content:center;font-size:10px;font-weight:700;color:#0f172a;font-family:Inter,sans-serif;text-align:center;">${c.name.length>3?c.name.substring(0,3):c.name}</div>
      <div style="position:absolute;top:-2px;right:-2px;background:#ef4444;border-radius:50%;width:18px;height:18px;display:flex;align-items:center;justify-content:center;font-size:9px;font-weight:700;color:#fff;border:2px solid #0f172a;">${c.count}</div>
    </div>`,
    iconSize: [46,46], iconAnchor: [23,23]
  })}).addTo(map);

  marker.on('click', () => openPanel(c.name));

  L.marker(coords, { icon: L.divIcon({
    className: '',
    html: `<div style="width:16px;height:16px;border-radius:50%;background:${color}44;animation:pulse 2.5s infinite;position:relative;">
      <div style="width:8px;height:8px;border-radius:50%;background:${color};border:2px solid #fff;position:absolute;top:4px;left:4px;"></div>
    </div>`,
    iconSize: [16,16], iconAnchor: [8,8]
  })}).addTo(map);
});

// 현재 패널에 표시 중인 일지 목록 (인덱스 참조용)
let panelJournals = [];

function esc(s) {
  return s ? s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;') : '';
}

let panelFilter = 'all';

function buildPanelItems(journals) {
  const body = document.getElementById('panelBody');
  if (!journals.length) {
    body.innerHTML = '<div class="panel-empty">해당 조건의 일지가 없습니다</div>';
    return;
  }
  body.innerHTML = journals.map((j, idx) => {
    const thumb = j.image
      ? `<div class="journal-item-img"><img src="uploads/${j.image}" alt=""></div>`
      : `<div class="journal-item-img">✈️</div>`;
    const writerLabel = j.mine ? '✦ 내 글' : (j.writer || '알 수 없음');
    const writerCls = j.mine ? 'journal-item-writer mine' : 'journal-item-writer';
    return `<div class="journal-item${j.mine ? ' mine-item' : ''}" onclick="openDetail(${idx})">
      ${thumb}
      <div class="journal-item-body">
        <div class="journal-item-title">${esc(j.title)}</div>
        <div class="journal-item-memo">${esc(j.memo)}</div>
        <div class="journal-item-footer">
          <div class="journal-item-date">${esc(j.date)}</div>
          <div class="${writerCls}">${esc(writerLabel)}</div>
        </div>
        <div class="journal-item-more">전체 보기 →</div>
      </div>
    </div>`;
  }).join('');
}

function setPanelFilter(type) {
  panelFilter = type;
  document.getElementById('pfAll').className   = 'panel-filter-btn' + (type === 'all'   ? ' pf-all'   : '');
  document.getElementById('pfMine').className  = 'panel-filter-btn' + (type === 'mine'  ? ' pf-mine'  : '');
  document.getElementById('pfOther').className = 'panel-filter-btn' + (type === 'other' ? ' pf-other' : '');

  let filtered = panelJournals;
  if (type === 'mine')  filtered = panelJournals.filter(j => j.mine);
  if (type === 'other') filtered = panelJournals.filter(j => !j.mine);
  buildPanelItems(filtered);
}

function openPanel(countryName) {
  panelJournals = allJournals.filter(j => j.trip === countryName);
  panelFilter = 'all';
  document.getElementById('panelCountry').textContent = '📍 ' + countryName + ' 일지';
  document.getElementById('pfAll').className   = 'panel-filter-btn pf-all';
  document.getElementById('pfMine').className  = 'panel-filter-btn';
  document.getElementById('pfOther').className = 'panel-filter-btn';

  buildPanelItems(panelJournals);
  document.getElementById('journalPanel').classList.add('open');
}

function closePanel() { document.getElementById('journalPanel').classList.remove('open'); }

function openDetail(idx) {
  const j = panelJournals[idx];
  if (!j) return;
  const hero = document.getElementById('detailHero');
  if (j.image && j.image.trim()) {
    hero.innerHTML = '<img src="uploads/' + j.image + '" alt="">';
  } else {
    hero.innerHTML = '✈️';
  }
  document.getElementById('detailBarTitle').textContent = j.title;
  document.getElementById('detailDest').textContent = '📍 ' + j.trip;
  document.getElementById('detailTitle').textContent = j.title;
  const wrEl = document.getElementById('detailWriter');
  const wrName = j.writer || '알 수 없음';
  wrEl.innerHTML = '✍️ <span>' + (j.mine ? '내가 쓴 글' : wrName + ' 님의 글') + '</span>';
  wrEl.className = 'detail-writer' + (j.mine ? ' mine' : '');
  document.getElementById('detailDate').textContent = '🕐 ' + j.date;
  document.getElementById('detailMemo').textContent = j.memo;

  const actionsEl = document.getElementById('detailActions');
  if (j.mine) {
    actionsEl.style.display = 'flex';
    const encTs = encodeURIComponent(j.ts);
    document.getElementById('detailEditBtn').onclick = () => { location.href = 'edit.jsp?ts=' + encTs; };
    document.getElementById('detailDelBtn').onclick  = () => {
      if (!confirm('정말 삭제하시겠습니까?')) return;
      location.href = 'delete_Action.jsp?ts=' + encTs;
    };
  } else {
    actionsEl.style.display = 'none';
  }

  const screen = document.getElementById('detailScreen');
  screen.classList.add('open');
  screen.scrollTop = 0;
}

function closeDetail() {
  document.getElementById('detailScreen').classList.remove('open');
}

document.addEventListener('keydown', e => { if (e.key === 'Escape') { closeDetail(); closePanel(); } });

// 현재 위치
if (navigator.geolocation) {
  navigator.geolocation.getCurrentPosition(pos => {
    const lat = pos.coords.latitude.toFixed(4);
    const lng = pos.coords.longitude.toFixed(4);
    document.getElementById('locCoords').textContent = lat + '° N, ' + lng + '° E';
    fetch(`https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lng}&format=json&accept-language=ko`)
      .then(r => r.json())
      .then(data => {
        const city = data.address.city || data.address.town || data.address.county || '';
        const country = data.address.country || '';
        const cc = data.address.country_code ? data.address.country_code.toUpperCase() : '';
        document.getElementById('locCity').textContent = city || country;
        document.getElementById('locCountry').textContent = country + (cc ? ' · ' + cc : '');
      }).catch(() => { document.getElementById('locCity').textContent = '위치 정보 없음'; });
  }, () => {
    document.getElementById('locCity').textContent = 'Seoul';
    document.getElementById('locCountry').textContent = 'South Korea · KR';
    document.getElementById('locCoords').textContent = '37.5665° N, 126.9780° E';
  });
} else {
  document.getElementById('locCity').textContent = 'Seoul';
  document.getElementById('locCountry').textContent = 'South Korea · KR';
  document.getElementById('locCoords').textContent = '37.5665° N, 126.9780° E';
}
</script>
</body>
</html>
