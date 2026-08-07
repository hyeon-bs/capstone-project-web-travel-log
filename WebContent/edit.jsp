<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="java.sql.*"%>
<%
  response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
  response.setHeader("Pragma", "no-cache");
  response.setDateHeader("Expires", 0);
  if (session.getAttribute("loginUser") == null) {
    response.sendRedirect("main.jsp");
    return;
  }
  request.setCharacterEncoding("UTF-8");
  String loginUser = (String) session.getAttribute("loginUser");

  String ts = request.getParameter("ts"); // sysdate 초단위 (식별자)
  if (ts == null || ts.isEmpty()) {
    response.sendRedirect("List.jsp");
    return;
  }

  String dbTrip = "", dbTitle = "", dbMemo = "", dbImage = "";
  try {
    Connection conn = db.DBUtil.getConnection();
    PreparedStatement ps = conn.prepareStatement(
      "SELECT trip, title, memo, image, id FROM test.`write` WHERE DATE_FORMAT(sysdate,'%Y-%m-%d %H:%i:%S')=?");
    ps.setString(1, ts);
    ResultSet rs = ps.executeQuery();
    if (rs.next()) {
      String owner = rs.getString("id");
      if (!loginUser.equals(owner)) {
        rs.close(); ps.close(); conn.close();
        response.sendRedirect("List.jsp");
        return;
      }
      dbTrip  = rs.getString("trip")  != null ? rs.getString("trip")  : "";
      dbTitle = rs.getString("title") != null ? rs.getString("title") : "";
      dbMemo  = rs.getString("memo")  != null ? rs.getString("memo")  : "";
      dbImage = rs.getString("image") != null ? rs.getString("image") : "";
    } else {
      rs.close(); ps.close(); conn.close();
      response.sendRedirect("List.jsp");
      return;
    }
    rs.close(); ps.close(); conn.close();
  } catch (Exception e) { e.printStackTrace(); }

  String safeTrip  = dbTrip.replace("&","&amp;").replace("<","&lt;").replace("\"","&quot;");
  String safeTitle = dbTitle.replace("&","&amp;").replace("<","&lt;").replace("\"","&quot;");
  String safeMemo  = dbMemo.replace("&","&amp;").replace("<","&lt;");
  String safeTs    = ts.replace("&","&amp;").replace("\"","&quot;");
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>TravelLog — 일지 수정</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: 'Inter', sans-serif; background: #0f172a; min-height: 100vh; color: #fff; }
  .nav-bar {
    display: flex; align-items: center; justify-content: space-between;
    padding: 14px 28px; background: rgba(10,15,35,0.9);
    border-bottom: 1px solid rgba(255,255,255,0.08);
    position: sticky; top: 0; z-index: 10; backdrop-filter: blur(12px);
  }
  .nav-logo { font-size: 20px; font-weight: 700; }
  .nav-logo span { color: #60a5fa; }
  .nav-btn {
    padding: 7px 14px; border-radius: 8px; border: 1px solid rgba(255,255,255,0.12);
    background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.8);
    font-size: 13px; font-weight: 500; cursor: pointer;
    font-family: 'Inter', sans-serif; transition: all 0.15s;
  }
  .nav-btn:hover { background: rgba(255,255,255,0.14); color: #fff; }
  .page-wrapper { max-width: 620px; margin: 48px auto; padding: 0 20px 80px; }
  .page-title { font-size: 22px; font-weight: 700; margin-bottom: 28px; }
  .form-card {
    background: rgba(255,255,255,0.05);
    border: 1px solid rgba(255,255,255,0.1);
    border-radius: 18px; padding: 32px 28px;
  }
  .form-group { margin-bottom: 18px; }
  .form-group label {
    display: block; font-size: 11px; font-weight: 600;
    color: rgba(255,255,255,0.45); text-transform: uppercase;
    letter-spacing: 0.8px; margin-bottom: 8px;
  }
  .form-group input,
  .form-group textarea {
    width: 100%; padding: 12px 14px;
    background: rgba(255,255,255,0.07);
    border: 1px solid rgba(255,255,255,0.12);
    border-radius: 10px; color: #fff;
    font-size: 14px; font-family: 'Inter', sans-serif;
    outline: none; transition: border-color 0.2s, background 0.2s; resize: vertical;
  }
  .form-group input::placeholder,
  .form-group textarea::placeholder { color: rgba(255,255,255,0.3); }
  .form-group input:focus,
  .form-group textarea:focus { border-color: #60a5fa; background: rgba(96,165,250,0.08); }
  .current-image { margin-top: 8px; font-size: 12px; color: rgba(255,255,255,0.4); }
  .current-image span { color: #60a5fa; }

  /* 여행지 검색 */
  .country-wrap { position: relative; }
  .country-search {
    width: 100%; padding: 12px 14px;
    background: rgba(255,255,255,0.07); border: 1px solid rgba(255,255,255,0.12);
    border-radius: 10px; color: #fff; font-size: 14px; font-family: 'Inter', sans-serif;
    outline: none; transition: border-color 0.2s; box-sizing: border-box;
  }
  .country-search::placeholder { color: rgba(255,255,255,0.3); }
  .country-search:focus { border-color: #60a5fa; background: rgba(96,165,250,0.08); }
  .country-list {
    display: none; position: absolute; left: 0; right: 0; top: calc(100% + 4px);
    background: #162032; border: 1px solid rgba(96,165,250,0.35);
    border-radius: 14px; max-height: 260px; overflow-y: auto; z-index: 999;
    box-shadow: 0 16px 40px rgba(0,0,0,0.7);
  }
  .country-list.show { display: block; }
  .country-group-label {
    padding: 8px 14px 4px; font-size: 10px; font-weight: 700;
    color: rgba(96,165,250,0.6); text-transform: uppercase; letter-spacing: 1px;
    border-top: 1px solid rgba(255,255,255,0.05); margin-top: 2px;
  }
  .country-group-label:first-child { border-top: none; margin-top: 0; }
  .country-opt {
    padding: 10px 16px; cursor: pointer; font-size: 14px; font-weight: 500;
    color: #fff; display: flex; align-items: center; gap: 10px; transition: background 0.1s;
  }
  .country-opt:hover, .country-opt.active { background: rgba(96,165,250,0.22); }
  .country-opt .flag { font-size: 18px; flex-shrink: 0; }
  .country-opt .kr-name { flex: 1; font-weight: 600; }
  .country-opt .en-name { font-size: 12px; color: rgba(255,255,255,0.55); }
  .country-list::-webkit-scrollbar { width: 5px; }
  .country-list::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.15); border-radius: 3px; }
  .selected-tag {
    display: none; margin-top: 8px; padding: 8px 14px;
    background: rgba(96,165,250,0.12); border: 1px solid rgba(96,165,250,0.3);
    border-radius: 10px; font-size: 14px; font-weight: 500; color: #93c5fd;
    align-items: center; gap: 8px;
  }
  .selected-tag.show { display: inline-flex; }
  .tag-x { cursor: pointer; color: rgba(255,255,255,0.35); margin-left: 4px; font-size: 16px; }
  .tag-x:hover { color: #fff; }
  .btn-row { display: flex; gap: 10px; margin-top: 8px; }
  .btn-save {
    flex: 1; padding: 13px;
    background: linear-gradient(135deg, #3b82f6, #1d4ed8);
    border: none; border-radius: 12px; color: #fff;
    font-size: 15px; font-weight: 600; cursor: pointer;
    transition: transform 0.15s, box-shadow 0.15s; font-family: 'Inter', sans-serif;
  }
  .btn-save:hover { transform: translateY(-1px); box-shadow: 0 10px 28px rgba(59,130,246,0.5); }
  .btn-cancel {
    padding: 13px 22px; border-radius: 12px;
    background: rgba(255,255,255,0.07); border: 1px solid rgba(255,255,255,0.12);
    color: rgba(255,255,255,0.7); font-size: 15px; font-weight: 500;
    cursor: pointer; font-family: 'Inter', sans-serif; transition: all 0.15s;
  }
  .btn-cancel:hover { background: rgba(255,255,255,0.14); color: #fff; }
</style>
</head>
<body>
<nav class="nav-bar">
  <div class="nav-logo">Travel<span>Log</span></div>
  <button class="nav-btn" onclick="history.back()">← 뒤로</button>
</nav>
<div class="page-wrapper">
  <div class="page-title">✏️ 여행 일지 수정</div>
  <div class="form-card">
    <form method="post" action="edit_Action.jsp" enctype="multipart/form-data">
      <input type="hidden" name="ts" value="<%=safeTs%>">
      <input type="hidden" name="trip" id="tripHidden" value="<%=safeTrip%>">
      <div class="form-group">
        <label>여행지</label>
        <div class="country-wrap">
          <input type="text" class="country-search" id="countrySearch"
                 placeholder="🔍  지역명 검색 (예: 구미, 서울, 제주...)" autocomplete="off">
          <div class="country-list" id="countryList"></div>
        </div>
        <div class="selected-tag" id="selectedTag">
          <span id="selFlag"></span>
          <span id="selName"></span>
          <span class="tag-x" onclick="clearSel()">✕</span>
        </div>
      </div>
      <div class="form-group">
        <label>제목</label>
        <input type="text" name="title" value="<%=safeTitle%>" placeholder="제목 입력" maxlength="100" required>
      </div>
      <div class="form-group">
        <label>내용</label>
        <textarea name="memo" rows="8" placeholder="여행 이야기를 적어보세요" required><%=safeMemo%></textarea>
      </div>
      <div class="form-group">
        <label>이미지 변경 (선택)</label>
        <input type="file" name="image" accept="image/*">
        <% if (!dbImage.isEmpty()) { %>
        <div class="current-image">현재 이미지: <span><%=dbImage%></span></div>
        <% } %>
      </div>
      <div class="btn-row">
        <button type="submit" class="btn-save">저장하기</button>
        <button type="button" class="btn-cancel" onclick="history.back()">취소</button>
      </div>
    </form>
  </div>
</div>
<script>
const COUNTRY_GROUPS = [
  { label: "🇰🇷 서울 · 광역시", list: [
    {kr:"서울",en:"Seoul",flag:"🇰🇷"},{kr:"부산",en:"Busan",flag:"🇰🇷"},
    {kr:"대구",en:"Daegu",flag:"🇰🇷"},{kr:"인천",en:"Incheon",flag:"🇰🇷"},
    {kr:"광주",en:"Gwangju",flag:"🇰🇷"},{kr:"대전",en:"Daejeon",flag:"🇰🇷"},
    {kr:"울산",en:"Ulsan",flag:"🇰🇷"},{kr:"세종",en:"Sejong",flag:"🇰🇷"},
  ]},
  { label: "🇰🇷 경기도", list: [
    {kr:"수원",en:"Suwon",flag:"🇰🇷"},{kr:"성남",en:"Seongnam",flag:"🇰🇷"},
    {kr:"고양",en:"Goyang",flag:"🇰🇷"},{kr:"용인",en:"Yongin",flag:"🇰🇷"},
    {kr:"안산",en:"Ansan",flag:"🇰🇷"},{kr:"안양",en:"Anyang",flag:"🇰🇷"},
    {kr:"부천",en:"Bucheon",flag:"🇰🇷"},{kr:"평택",en:"Pyeongtaek",flag:"🇰🇷"},
    {kr:"의정부",en:"Uijeongbu",flag:"🇰🇷"},{kr:"시흥",en:"Siheung",flag:"🇰🇷"},
    {kr:"파주",en:"Paju",flag:"🇰🇷"},{kr:"김포",en:"Gimpo",flag:"🇰🇷"},
    {kr:"광명",en:"Gwangmyeong",flag:"🇰🇷"},{kr:"화성",en:"Hwaseong",flag:"🇰🇷"},
    {kr:"남양주",en:"Namyangju",flag:"🇰🇷"},{kr:"양주",en:"Yangju",flag:"🇰🇷"},
    {kr:"구리",en:"Guri",flag:"🇰🇷"},{kr:"하남",en:"Hanam",flag:"🇰🇷"},
    {kr:"오산",en:"Osan",flag:"🇰🇷"},{kr:"군포",en:"Gunpo",flag:"🇰🇷"},
    {kr:"의왕",en:"Uiwang",flag:"🇰🇷"},{kr:"과천",en:"Gwacheon",flag:"🇰🇷"},
    {kr:"안성",en:"Anseong",flag:"🇰🇷"},{kr:"이천",en:"Icheon",flag:"🇰🇷"},
    {kr:"여주",en:"Yeoju",flag:"🇰🇷"},{kr:"양평",en:"Yangpyeong",flag:"🇰🇷"},
    {kr:"가평",en:"Gapyeong",flag:"🇰🇷"},{kr:"포천",en:"Pocheon",flag:"🇰🇷"},
    {kr:"동두천",en:"Dongducheon",flag:"🇰🇷"},{kr:"연천",en:"Yeoncheon",flag:"🇰🇷"},
  ]},
  { label: "🇰🇷 강원도", list: [
    {kr:"춘천",en:"Chuncheon",flag:"🇰🇷"},{kr:"원주",en:"Wonju",flag:"🇰🇷"},
    {kr:"강릉",en:"Gangneung",flag:"🇰🇷"},{kr:"속초",en:"Sokcho",flag:"🇰🇷"},
    {kr:"동해",en:"Donghae",flag:"🇰🇷"},{kr:"태백",en:"Taebaek",flag:"🇰🇷"},
    {kr:"삼척",en:"Samcheok",flag:"🇰🇷"},{kr:"홍천",en:"Hongcheon",flag:"🇰🇷"},
    {kr:"횡성",en:"Hoengseong",flag:"🇰🇷"},{kr:"영월",en:"Yeongwol",flag:"🇰🇷"},
    {kr:"정선",en:"Jeongseon",flag:"🇰🇷"},{kr:"철원",en:"Cheorwon",flag:"🇰🇷"},
    {kr:"화천",en:"Hwacheon",flag:"🇰🇷"},{kr:"양구",en:"Yanggu",flag:"🇰🇷"},
    {kr:"인제",en:"Inje",flag:"🇰🇷"},{kr:"고성(강원)",en:"Goseong",flag:"🇰🇷"},
    {kr:"양양",en:"Yangyang",flag:"🇰🇷"},{kr:"평창",en:"Pyeongchang",flag:"🇰🇷"},
  ]},
  { label: "🇰🇷 충청북도", list: [
    {kr:"청주",en:"Cheongju",flag:"🇰🇷"},{kr:"충주",en:"Chungju",flag:"🇰🇷"},
    {kr:"제천",en:"Jecheon",flag:"🇰🇷"},{kr:"보은",en:"Boeun",flag:"🇰🇷"},
    {kr:"옥천",en:"Okcheon",flag:"🇰🇷"},{kr:"영동",en:"Yeongdong",flag:"🇰🇷"},
    {kr:"증평",en:"Jeungpyeong",flag:"🇰🇷"},{kr:"진천",en:"Jincheon",flag:"🇰🇷"},
    {kr:"괴산",en:"Goesan",flag:"🇰🇷"},{kr:"음성",en:"Eumseong",flag:"🇰🇷"},
    {kr:"단양",en:"Danyang",flag:"🇰🇷"},
  ]},
  { label: "🇰🇷 충청남도", list: [
    {kr:"천안",en:"Cheonan",flag:"🇰🇷"},{kr:"공주",en:"Gongju",flag:"🇰🇷"},
    {kr:"보령",en:"Boryeong",flag:"🇰🇷"},{kr:"아산",en:"Asan",flag:"🇰🇷"},
    {kr:"서산",en:"Seosan",flag:"🇰🇷"},{kr:"논산",en:"Nonsan",flag:"🇰🇷"},
    {kr:"계룡",en:"Gyeryong",flag:"🇰🇷"},{kr:"당진",en:"Dangjin",flag:"🇰🇷"},
    {kr:"금산",en:"Geumsan",flag:"🇰🇷"},{kr:"부여",en:"Buyeo",flag:"🇰🇷"},
    {kr:"서천",en:"Seocheon",flag:"🇰🇷"},{kr:"청양",en:"Cheongyang",flag:"🇰🇷"},
    {kr:"홍성",en:"Hongseong",flag:"🇰🇷"},{kr:"예산",en:"Yesan",flag:"🇰🇷"},
    {kr:"태안",en:"Taean",flag:"🇰🇷"},
  ]},
  { label: "🇰🇷 전라북도", list: [
    {kr:"전주",en:"Jeonju",flag:"🇰🇷"},{kr:"군산",en:"Gunsan",flag:"🇰🇷"},
    {kr:"익산",en:"Iksan",flag:"🇰🇷"},{kr:"정읍",en:"Jeongeup",flag:"🇰🇷"},
    {kr:"남원",en:"Namwon",flag:"🇰🇷"},{kr:"김제",en:"Gimje",flag:"🇰🇷"},
    {kr:"완주",en:"Wanju",flag:"🇰🇷"},{kr:"진안",en:"Jinan",flag:"🇰🇷"},
    {kr:"무주",en:"Muju",flag:"🇰🇷"},{kr:"장수",en:"Jangsu",flag:"🇰🇷"},
    {kr:"임실",en:"Imsil",flag:"🇰🇷"},{kr:"순창",en:"Sunchang",flag:"🇰🇷"},
    {kr:"고창",en:"Gochang",flag:"🇰🇷"},{kr:"부안",en:"Buan",flag:"🇰🇷"},
  ]},
  { label: "🇰🇷 전라남도", list: [
    {kr:"목포",en:"Mokpo",flag:"🇰🇷"},{kr:"여수",en:"Yeosu",flag:"🇰🇷"},
    {kr:"순천",en:"Suncheon",flag:"🇰🇷"},{kr:"나주",en:"Naju",flag:"🇰🇷"},
    {kr:"광양",en:"Gwangyang",flag:"🇰🇷"},{kr:"담양",en:"Damyang",flag:"🇰🇷"},
    {kr:"곡성",en:"Gokseong",flag:"🇰🇷"},{kr:"구례",en:"Gurye",flag:"🇰🇷"},
    {kr:"고흥",en:"Goheung",flag:"🇰🇷"},{kr:"보성",en:"Boseong",flag:"🇰🇷"},
    {kr:"화순",en:"Hwasun",flag:"🇰🇷"},{kr:"장흥",en:"Jangheung",flag:"🇰🇷"},
    {kr:"강진",en:"Gangjin",flag:"🇰🇷"},{kr:"해남",en:"Haenam",flag:"🇰🇷"},
    {kr:"영암",en:"Yeongam",flag:"🇰🇷"},{kr:"무안",en:"Muan",flag:"🇰🇷"},
    {kr:"함평",en:"Hampyeong",flag:"🇰🇷"},{kr:"영광",en:"Yeonggwang",flag:"🇰🇷"},
    {kr:"장성",en:"Jangseong",flag:"🇰🇷"},{kr:"완도",en:"Wando",flag:"🇰🇷"},
    {kr:"진도",en:"Jindo",flag:"🇰🇷"},{kr:"신안",en:"Sinan",flag:"🇰🇷"},
  ]},
  { label: "🇰🇷 경상북도", list: [
    {kr:"포항",en:"Pohang",flag:"🇰🇷"},{kr:"경주",en:"Gyeongju",flag:"🇰🇷"},
    {kr:"김천",en:"Gimcheon",flag:"🇰🇷"},{kr:"안동",en:"Andong",flag:"🇰🇷"},
    {kr:"구미",en:"Gumi",flag:"🇰🇷"},{kr:"영주",en:"Yeongju",flag:"🇰🇷"},
    {kr:"영천",en:"Yeongcheon",flag:"🇰🇷"},{kr:"상주",en:"Sangju",flag:"🇰🇷"},
    {kr:"문경",en:"Mungyeong",flag:"🇰🇷"},{kr:"경산",en:"Gyeongsan",flag:"🇰🇷"},
    {kr:"칠곡",en:"Chilgok",flag:"🇰🇷"},{kr:"군위",en:"Gunwi",flag:"🇰🇷"},
    {kr:"의성",en:"Uiseong",flag:"🇰🇷"},{kr:"청송",en:"Cheongsong",flag:"🇰🇷"},
    {kr:"영양",en:"Yeongyang",flag:"🇰🇷"},{kr:"영덕",en:"Yeongdeok",flag:"🇰🇷"},
    {kr:"청도",en:"Cheongdo",flag:"🇰🇷"},{kr:"고령",en:"Goryeong",flag:"🇰🇷"},
    {kr:"성주",en:"Seongju",flag:"🇰🇷"},{kr:"예천",en:"Yecheon",flag:"🇰🇷"},
    {kr:"봉화",en:"Bonghwa",flag:"🇰🇷"},{kr:"울진",en:"Uljin",flag:"🇰🇷"},
    {kr:"울릉도",en:"Ulleungdo",flag:"🇰🇷"},
  ]},
  { label: "🇰🇷 경상남도", list: [
    {kr:"창원",en:"Changwon",flag:"🇰🇷"},{kr:"진주",en:"Jinju",flag:"🇰🇷"},
    {kr:"통영",en:"Tongyeong",flag:"🇰🇷"},{kr:"사천",en:"Sacheon",flag:"🇰🇷"},
    {kr:"김해",en:"Gimhae",flag:"🇰🇷"},{kr:"밀양",en:"Miryang",flag:"🇰🇷"},
    {kr:"거제",en:"Geoje",flag:"🇰🇷"},{kr:"양산",en:"Yangsan",flag:"🇰🇷"},
    {kr:"의령",en:"Uiryeong",flag:"🇰🇷"},{kr:"함안",en:"Haman",flag:"🇰🇷"},
    {kr:"창녕",en:"Changnyeong",flag:"🇰🇷"},{kr:"고성(경남)",en:"Goseong(Gyeongnam)",flag:"🇰🇷"},
    {kr:"남해",en:"Namhae",flag:"🇰🇷"},{kr:"하동",en:"Hadong",flag:"🇰🇷"},
    {kr:"산청",en:"Sancheong",flag:"🇰🇷"},{kr:"함양",en:"Hamyang",flag:"🇰🇷"},
    {kr:"거창",en:"Geochang",flag:"🇰🇷"},{kr:"합천",en:"Hapcheon",flag:"🇰🇷"},
  ]},
  { label: "🇰🇷 제주도", list: [
    {kr:"제주도",en:"Jeju",flag:"🇰🇷"},
  ]},
  { label: "동아시아", list: [
    {kr:"대한민국",en:"South Korea",flag:"🇰🇷"},{kr:"일본",en:"Japan",flag:"🇯🇵"},
    {kr:"중국",en:"China",flag:"🇨🇳"},{kr:"홍콩",en:"Hong Kong",flag:"🇭🇰"},
    {kr:"대만",en:"Taiwan",flag:"🇹🇼"},{kr:"몽골",en:"Mongolia",flag:"🇲🇳"},
  ]},
  { label: "동남아시아", list: [
    {kr:"태국",en:"Thailand",flag:"🇹🇭"},{kr:"베트남",en:"Vietnam",flag:"🇻🇳"},
    {kr:"인도네시아",en:"Indonesia",flag:"🇮🇩"},{kr:"말레이시아",en:"Malaysia",flag:"🇲🇾"},
    {kr:"필리핀",en:"Philippines",flag:"🇵🇭"},{kr:"싱가포르",en:"Singapore",flag:"🇸🇬"},
    {kr:"캄보디아",en:"Cambodia",flag:"🇰🇭"},{kr:"미얀마",en:"Myanmar",flag:"🇲🇲"},
    {kr:"라오스",en:"Laos",flag:"🇱🇦"},{kr:"브루나이",en:"Brunei",flag:"🇧🇳"},
    {kr:"동티모르",en:"East Timor",flag:"🇹🇱"},
  ]},
  { label: "남아시아", list: [
    {kr:"인도",en:"India",flag:"🇮🇳"},{kr:"파키스탄",en:"Pakistan",flag:"🇵🇰"},
    {kr:"방글라데시",en:"Bangladesh",flag:"🇧🇩"},{kr:"스리랑카",en:"Sri Lanka",flag:"🇱🇰"},
    {kr:"네팔",en:"Nepal",flag:"🇳🇵"},{kr:"부탄",en:"Bhutan",flag:"🇧🇹"},
    {kr:"몰디브",en:"Maldives",flag:"🇲🇻"},{kr:"아프가니스탄",en:"Afghanistan",flag:"🇦🇫"},
  ]},
  { label: "중앙아시아", list: [
    {kr:"카자흐스탄",en:"Kazakhstan",flag:"🇰🇿"},{kr:"우즈베키스탄",en:"Uzbekistan",flag:"🇺🇿"},
    {kr:"키르기스스탄",en:"Kyrgyzstan",flag:"🇰🇬"},{kr:"타지키스탄",en:"Tajikistan",flag:"🇹🇯"},
    {kr:"투르크메니스탄",en:"Turkmenistan",flag:"🇹🇲"},
  ]},
  { label: "중동 · 서아시아", list: [
    {kr:"터키",en:"Turkey",flag:"🇹🇷"},{kr:"UAE",en:"UAE",flag:"🇦🇪"},
    {kr:"사우디아라비아",en:"Saudi Arabia",flag:"🇸🇦"},{kr:"카타르",en:"Qatar",flag:"🇶🇦"},
    {kr:"쿠웨이트",en:"Kuwait",flag:"🇰🇼"},{kr:"바레인",en:"Bahrain",flag:"🇧🇭"},
    {kr:"오만",en:"Oman",flag:"🇴🇲"},{kr:"이스라엘",en:"Israel",flag:"🇮🇱"},
    {kr:"요르단",en:"Jordan",flag:"🇯🇴"},{kr:"레바논",en:"Lebanon",flag:"🇱🇧"},
    {kr:"이란",en:"Iran",flag:"🇮🇷"},{kr:"이라크",en:"Iraq",flag:"🇮🇶"},
    {kr:"시리아",en:"Syria",flag:"🇸🇾"},{kr:"예멘",en:"Yemen",flag:"🇾🇪"},
    {kr:"조지아",en:"Georgia",flag:"🇬🇪"},{kr:"아르메니아",en:"Armenia",flag:"🇦🇲"},
    {kr:"아제르바이잔",en:"Azerbaijan",flag:"🇦🇿"},
  ]},
  { label: "서유럽", list: [
    {kr:"프랑스",en:"France",flag:"🇫🇷"},{kr:"영국",en:"UK",flag:"🇬🇧"},
    {kr:"독일",en:"Germany",flag:"🇩🇪"},{kr:"이탈리아",en:"Italy",flag:"🇮🇹"},
    {kr:"스페인",en:"Spain",flag:"🇪🇸"},{kr:"포르투갈",en:"Portugal",flag:"🇵🇹"},
    {kr:"네덜란드",en:"Netherlands",flag:"🇳🇱"},{kr:"벨기에",en:"Belgium",flag:"🇧🇪"},
    {kr:"스위스",en:"Switzerland",flag:"🇨🇭"},{kr:"오스트리아",en:"Austria",flag:"🇦🇹"},
    {kr:"아일랜드",en:"Ireland",flag:"🇮🇪"},{kr:"룩셈부르크",en:"Luxembourg",flag:"🇱🇺"},
    {kr:"모나코",en:"Monaco",flag:"🇲🇨"},{kr:"안도라",en:"Andorra",flag:"🇦🇩"},
    {kr:"리히텐슈타인",en:"Liechtenstein",flag:"🇱🇮"},{kr:"몰타",en:"Malta",flag:"🇲🇹"},
    {kr:"사이프러스",en:"Cyprus",flag:"🇨🇾"},
  ]},
  { label: "북유럽", list: [
    {kr:"노르웨이",en:"Norway",flag:"🇳🇴"},{kr:"스웨덴",en:"Sweden",flag:"🇸🇪"},
    {kr:"덴마크",en:"Denmark",flag:"🇩🇰"},{kr:"핀란드",en:"Finland",flag:"🇫🇮"},
    {kr:"아이슬란드",en:"Iceland",flag:"🇮🇸"},{kr:"에스토니아",en:"Estonia",flag:"🇪🇪"},
    {kr:"라트비아",en:"Latvia",flag:"🇱🇻"},{kr:"리투아니아",en:"Lithuania",flag:"🇱🇹"},
  ]},
  { label: "동유럽", list: [
    {kr:"러시아",en:"Russia",flag:"🇷🇺"},{kr:"우크라이나",en:"Ukraine",flag:"🇺🇦"},
    {kr:"폴란드",en:"Poland",flag:"🇵🇱"},{kr:"체코",en:"Czech Republic",flag:"🇨🇿"},
    {kr:"슬로바키아",en:"Slovakia",flag:"🇸🇰"},{kr:"헝가리",en:"Hungary",flag:"🇭🇺"},
    {kr:"루마니아",en:"Romania",flag:"🇷🇴"},{kr:"불가리아",en:"Bulgaria",flag:"🇧🇬"},
    {kr:"벨라루스",en:"Belarus",flag:"🇧🇾"},{kr:"몰도바",en:"Moldova",flag:"🇲🇩"},
  ]},
  { label: "남유럽 · 발칸", list: [
    {kr:"그리스",en:"Greece",flag:"🇬🇷"},{kr:"크로아티아",en:"Croatia",flag:"🇭🇷"},
    {kr:"세르비아",en:"Serbia",flag:"🇷🇸"},{kr:"슬로베니아",en:"Slovenia",flag:"🇸🇮"},
    {kr:"보스니아헤르체고비나",en:"Bosnia",flag:"🇧🇦"},{kr:"알바니아",en:"Albania",flag:"🇦🇱"},
    {kr:"북마케도니아",en:"N. Macedonia",flag:"🇲🇰"},{kr:"몬테네그로",en:"Montenegro",flag:"🇲🇪"},
    {kr:"코소보",en:"Kosovo",flag:"🇽🇰"},{kr:"산마리노",en:"San Marino",flag:"🇸🇲"},
  ]},
  { label: "북아메리카", list: [
    {kr:"미국",en:"USA",flag:"🇺🇸"},{kr:"캐나다",en:"Canada",flag:"🇨🇦"},
    {kr:"멕시코",en:"Mexico",flag:"🇲🇽"},
  ]},
  { label: "중앙아메리카 · 카리브", list: [
    {kr:"쿠바",en:"Cuba",flag:"🇨🇺"},{kr:"자메이카",en:"Jamaica",flag:"🇯🇲"},
    {kr:"도미니카공화국",en:"Dominican Rep.",flag:"🇩🇴"},{kr:"아이티",en:"Haiti",flag:"🇭🇹"},
    {kr:"파나마",en:"Panama",flag:"🇵🇦"},{kr:"코스타리카",en:"Costa Rica",flag:"🇨🇷"},
    {kr:"과테말라",en:"Guatemala",flag:"🇬🇹"},{kr:"온두라스",en:"Honduras",flag:"🇭🇳"},
    {kr:"엘살바도르",en:"El Salvador",flag:"🇸🇻"},{kr:"니카라과",en:"Nicaragua",flag:"🇳🇮"},
  ]},
  { label: "남아메리카", list: [
    {kr:"브라질",en:"Brazil",flag:"🇧🇷"},{kr:"아르헨티나",en:"Argentina",flag:"🇦🇷"},
    {kr:"칠레",en:"Chile",flag:"🇨🇱"},{kr:"페루",en:"Peru",flag:"🇵🇪"},
    {kr:"콜롬비아",en:"Colombia",flag:"🇨🇴"},{kr:"베네수엘라",en:"Venezuela",flag:"🇻🇪"},
    {kr:"에콰도르",en:"Ecuador",flag:"🇪🇨"},{kr:"볼리비아",en:"Bolivia",flag:"🇧🇴"},
    {kr:"파라과이",en:"Paraguay",flag:"🇵🇾"},{kr:"우루과이",en:"Uruguay",flag:"🇺🇾"},
  ]},
  { label: "오세아니아", list: [
    {kr:"호주",en:"Australia",flag:"🇦🇺"},{kr:"뉴질랜드",en:"New Zealand",flag:"🇳🇿"},
    {kr:"파푸아뉴기니",en:"Papua New Guinea",flag:"🇵🇬"},{kr:"피지",en:"Fiji",flag:"🇫🇯"},
  ]},
  { label: "아프리카", list: [
    {kr:"이집트",en:"Egypt",flag:"🇪🇬"},{kr:"모로코",en:"Morocco",flag:"🇲🇦"},
    {kr:"나이지리아",en:"Nigeria",flag:"🇳🇬"},{kr:"케냐",en:"Kenya",flag:"🇰🇪"},
    {kr:"남아프리카",en:"South Africa",flag:"🇿🇦"},{kr:"에티오피아",en:"Ethiopia",flag:"🇪🇹"},
    {kr:"탄자니아",en:"Tanzania",flag:"🇹🇿"},{kr:"가나",en:"Ghana",flag:"🇬🇭"},
  ]},
];

const COUNTRIES = COUNTRY_GROUPS.flatMap(g => g.list);
const searchEl  = document.getElementById('countrySearch');
const listEl    = document.getElementById('countryList');
const hiddenEl  = document.getElementById('tripHidden');
const tagEl     = document.getElementById('selectedTag');

function buildList(arr, grouped) {
  listEl.innerHTML = '';
  if (!arr.length) {
    listEl.innerHTML = '<div style="padding:14px 16px;color:rgba(255,255,255,0.35);font-size:13px;">검색 결과 없음</div>';
    listEl.classList.add('show'); return;
  }
  if (grouped) {
    COUNTRY_GROUPS.forEach(g => {
      const filtered = g.list.filter(c => arr.includes(c));
      if (!filtered.length) return;
      const lbl = document.createElement('div');
      lbl.className = 'country-group-label';
      lbl.textContent = g.label;
      listEl.appendChild(lbl);
      filtered.forEach(c => appendOpt(c));
    });
  } else {
    arr.forEach(c => appendOpt(c));
  }
  listEl.classList.add('show');
}

function appendOpt(c) {
  const d = document.createElement('div');
  d.className = 'country-opt';
  d.innerHTML = `<span class="flag">${c.flag}</span><span class="kr-name">${c.kr}</span><span class="en-name">${c.en}</span>`;
  d.addEventListener('mousedown', e => { e.preventDefault(); pick(c); });
  listEl.appendChild(d);
}

function pick(c) {
  hiddenEl.value = c.kr;
  searchEl.value = '';
  listEl.classList.remove('show');
  document.getElementById('selFlag').textContent = c.flag + ' ';
  document.getElementById('selName').textContent = c.kr + ' (' + c.en + ')';
  tagEl.classList.add('show');
}

function clearSel() { hiddenEl.value = ''; tagEl.classList.remove('show'); }

searchEl.addEventListener('focus', () => buildList(COUNTRIES, true));
searchEl.addEventListener('input', function() {
  const q = this.value.toLowerCase();
  if (!q) { buildList(COUNTRIES, true); return; }
  const filtered = COUNTRIES.filter(c => c.kr.includes(q) || c.en.toLowerCase().includes(q));
  buildList(filtered, false);
});
searchEl.addEventListener('blur', () => setTimeout(() => listEl.classList.remove('show'), 180));

// 기존 여행지 값 미리 선택
(function() {
  const saved = hiddenEl.value;
  if (!saved) return;
  const found = COUNTRIES.find(c => c.kr === saved);
  if (found) {
    document.getElementById('selFlag').textContent = found.flag + ' ';
    document.getElementById('selName').textContent = found.kr + ' (' + found.en + ')';
    tagEl.classList.add('show');
  } else {
    // 목록에 없는 값이면 이름만 표시
    document.getElementById('selFlag').textContent = '📍 ';
    document.getElementById('selName').textContent = saved;
    tagEl.classList.add('show');
  }
})();
</script>
</body>
</html>
