<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
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

  // ── 페이지·필터 파라미터 ──
  final int PAGE_SIZE = 24;
  String filterParam = request.getParameter("filter");
  if (filterParam == null) filterParam = "all";
  int curPage = 1;
  try { curPage = Integer.parseInt(request.getParameter("page")); } catch(Exception e) {}
  if (curPage < 1) curPage = 1;
  int offset = (curPage - 1) * PAGE_SIZE;

  // ── WHERE 조건 ──
  String whereClause = "";
  if ("mine".equals(filterParam))  whereClause = " WHERE id = '" + loginUser.replace("'","''") + "'";
  if ("other".equals(filterParam)) whereClause = " WHERE id != '" + loginUser.replace("'","''") + "'";

  Connection conn = db.DBUtil.getConnection();
  Statement stmt = conn.createStatement();

  // ── 전체 건수 (필터 포함) ──
  ResultSet cntRs = stmt.executeQuery("SELECT COUNT(*) FROM test.`write`" + whereClause);
  int totalCount = 0;
  if (cntRs.next()) totalCount = cntRs.getInt(1);
  cntRs.close();

  // 내 글 / 전체 카운트 (탭 숫자용)
  ResultSet mineRs = stmt.executeQuery("SELECT COUNT(*) FROM test.`write` WHERE id='" + loginUser.replace("'","''") + "'");
  int mineCount = 0;
  if (mineRs.next()) mineCount = mineRs.getInt(1);
  mineRs.close();

  ResultSet allRs = stmt.executeQuery("SELECT COUNT(*) FROM test.`write`");
  int allCount = 0;
  if (allRs.next()) allCount = allRs.getInt(1);
  allRs.close();
  int otherCount = allCount - mineCount;

  int totalPages = (int) Math.ceil((double) totalCount / PAGE_SIZE);
  if (totalPages < 1) totalPages = 1;
  if (curPage > totalPages) curPage = totalPages;

  // ── 현재 페이지 데이터 ──
  ResultSet rs = stmt.executeQuery(
    "SELECT trip, title, memo, image," +
    " DATE_FORMAT(sysdate,'%Y-%m-%d %H:%i') as dt," +
    " DATE_FORMAT(sysdate,'%Y-%m-%d %H:%i:%S') as ts," +
    " IFNULL(id,'') as writer" +
    " FROM test.`write`" + whereClause +
    " ORDER BY sysdate DESC LIMIT " + PAGE_SIZE + " OFFSET " + offset);

  boolean hasData = false;
  StringBuilder cards = new StringBuilder();
  StringBuilder jsonArr = new StringBuilder("[");
  int idx = 0;

  while (rs.next()) {
    hasData = true;
    String trip   = rs.getString("trip");
    String title  = rs.getString("title");
    String memo   = rs.getString("memo");
    String image  = rs.getString("image");
    String dt     = rs.getString("dt");
    String ts     = rs.getString("ts");
    String writer = rs.getString("writer");
    boolean isMine = loginUser.equals(writer);

    String thumbHtml = (image != null && !image.isEmpty())
      ? "<div class='journal-thumb'><img src='uploads/" + image + "' alt='' loading='lazy'></div>"
      : "<div class='journal-thumb'>✈️</div>";

    String safeMemoHtml  = memo  == null ? "" : memo.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;");
    String safeTitleHtml = title == null ? "" : title.replace("&","&amp;").replace("<","&lt;");
    String safeWriter    = writer.isEmpty() ? "알 수 없음" : writer.replace("&","&amp;").replace("<","&lt;");

    String jTrip   = trip   == null ? "" : trip.replace("\\","\\\\").replace("\"","\\\"").replace("\n","\\n");
    String jTitle2 = title  == null ? "" : title.replace("\\","\\\\").replace("\"","\\\"").replace("\n","\\n");
    String jMemo   = memo   == null ? "" : memo.replace("\\","\\\\").replace("\"","\\\"").replace("\n","\\n");
    String jImage  = image  == null ? "" : image.replace("\"","");
    String jDt     = dt     == null ? "" : dt;
    String jTs     = ts     == null ? "" : ts;
    String jWriter = writer.replace("\\","\\\\").replace("\"","\\\"");

    if (idx > 0) jsonArr.append(",");
    jsonArr.append("{\"ts\":\"").append(jTs)
           .append("\",\"trip\":\"").append(jTrip)
           .append("\",\"title\":\"").append(jTitle2)
           .append("\",\"memo\":\"").append(jMemo)
           .append("\",\"image\":\"").append(jImage)
           .append("\",\"dt\":\"").append(jDt)
           .append("\",\"writer\":\"").append(jWriter)
           .append("\",\"mine\":").append(isMine).append("}");

    String writerClass = isMine ? "journal-writer mine" : "journal-writer";
    String writerLabel = isMine ? "✦ " + safeWriter : safeWriter;
    String encTs = ts == null ? "" : ts.replace(" ", "%20").replace(":", "%3A");

    cards.append("<div class='journal-card").append(isMine ? " mine-card" : "")
         .append("' onclick=\"openDetail(").append(idx).append(")\">")
         .append(thumbHtml)
         .append("<div class='journal-body'>")
         .append("<div class='journal-dest'>📍 ").append(trip != null ? trip.replace("&","&amp;").replace("<","&lt;") : "").append("</div>")
         .append("<div class='journal-title'>").append(safeTitleHtml).append("</div>")
         .append("<div class='journal-memo'>").append(safeMemoHtml).append("</div>")
         .append("<div class='journal-footer'>")
         .append("<div class='journal-date'>").append(dt != null ? dt : "").append("</div>")
         .append("<div class='").append(writerClass).append("'>").append(writerLabel).append("</div>")
         .append("</div>");
    if (isMine) {
      cards.append("<div class='card-actions' onclick='event.stopPropagation()'>")
           .append("<button class='card-btn edit-btn' onclick=\"location.href='edit.jsp?ts=").append(encTs).append("'\">✏️ 수정</button>")
           .append("<button class='card-btn del-btn' onclick=\"doDelete('").append(encTs).append("')\">🗑️ 삭제</button>")
           .append("</div>");
    }
    cards.append("</div></div>");
    idx++;
  }
  rs.close(); stmt.close(); conn.close();
  jsonArr.append("]");

  // ── 페이지 번호 블록 (최대 10개씩) ──
  int blockSize = 10;
  int blockStart = ((curPage - 1) / blockSize) * blockSize + 1;
  int blockEnd   = Math.min(blockStart + blockSize - 1, totalPages);
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>TravelLog — 게시판</title>
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
  .nav-actions { display: flex; gap: 10px; }
  .nav-btn {
    padding: 7px 14px; border-radius: 8px; border: none;
    font-size: 13px; font-weight: 500; cursor: pointer;
    font-family: 'Inter', sans-serif; transition: all 0.15s;
  }
  .nav-btn-ghost { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.8); border: 1px solid rgba(255,255,255,0.12); }
  .nav-btn-ghost:hover { background: rgba(255,255,255,0.14); color: #fff; }
  .nav-btn-primary { background: linear-gradient(135deg,#3b82f6,#1d4ed8); color: #fff; }
  .nav-btn-primary:hover { box-shadow: 0 4px 14px rgba(59,130,246,0.4); transform: translateY(-1px); }

  .page-wrapper { max-width: 900px; margin: 0 auto; padding: 28px 20px 60px; }
  .page-title { font-size: 22px; font-weight: 700; margin-bottom: 4px; }
  .page-info  { font-size: 12px; color: rgba(255,255,255,0.35); margin-bottom: 16px; }

  /* 필터 탭 */
  .filter-bar { display: flex; gap: 8px; margin-bottom: 20px; }
  .filter-btn {
    padding: 7px 18px; border-radius: 20px; border: 1px solid rgba(255,255,255,0.12);
    background: rgba(255,255,255,0.06); color: rgba(255,255,255,0.55);
    font-size: 12px; font-weight: 600; cursor: pointer;
    font-family: 'Inter', sans-serif; transition: all 0.18s; text-decoration: none; display: inline-block;
  }
  .filter-btn:hover { background: rgba(255,255,255,0.12); color: #fff; }
  .filter-btn.active-all   { background: rgba(255,255,255,0.14); color: #fff; border-color: rgba(255,255,255,0.3); }
  .filter-btn.active-mine  { background: rgba(52,211,153,0.18); color: #34d399; border-color: rgba(52,211,153,0.4); }
  .filter-btn.active-other { background: rgba(96,165,250,0.18); color: #60a5fa; border-color: rgba(96,165,250,0.4); }

  /* 카드 그리드 */
  .journal-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(190px, 1fr));
    gap: 14px;
  }
  .journal-card {
    background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.08);
    border-radius: 14px; overflow: hidden; cursor: pointer;
    transition: transform 0.18s, box-shadow 0.18s, border-color 0.18s;
  }
  .journal-card:hover { transform: translateY(-3px); box-shadow: 0 10px 28px rgba(0,0,0,0.4); border-color: rgba(96,165,250,0.35); }
  .journal-card.mine-card { border-color: rgba(52,211,153,0.3); }
  .journal-card.mine-card:hover { border-color: rgba(52,211,153,0.6); box-shadow: 0 10px 28px rgba(52,211,153,0.1); }
  .journal-thumb { width: 100%; height: 110px; background: linear-gradient(135deg,#1e3a5f,#0f2144); display: flex; align-items: center; justify-content: center; font-size: 34px; overflow: hidden; }
  .journal-thumb img { width: 100%; height: 100%; object-fit: cover; }
  .journal-body { padding: 12px; }
  .journal-dest { font-size: 10px; color: #60a5fa; font-weight: 600; text-transform: uppercase; letter-spacing: 0.6px; margin-bottom: 5px; }
  .journal-title { font-size: 13px; font-weight: 600; margin-bottom: 5px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .journal-memo { font-size: 11px; color: rgba(255,255,255,0.45); line-height: 1.5; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
  .journal-footer { display: flex; align-items: center; justify-content: space-between; margin-top: 8px; }
  .journal-date { font-size: 10px; color: rgba(255,255,255,0.28); }
  .journal-writer { font-size: 10px; font-weight: 600; padding: 2px 7px; border-radius: 20px; background: rgba(96,165,250,0.15); color: #60a5fa; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 80px; }
  .journal-writer.mine { background: rgba(52,211,153,0.15); color: #34d399; }
  .card-actions { display: flex; gap: 6px; padding: 8px 12px 10px; border-top: 1px solid rgba(255,255,255,0.06); }
  .card-btn { flex: 1; padding: 6px 0; border-radius: 8px; border: none; font-size: 11px; font-weight: 600; cursor: pointer; font-family: 'Inter', sans-serif; transition: all 0.15s; }
  .edit-btn { background: rgba(96,165,250,0.15); color: #60a5fa; }
  .edit-btn:hover { background: rgba(96,165,250,0.28); }
  .del-btn  { background: rgba(239,68,68,0.12); color: #f87171; }
  .del-btn:hover  { background: rgba(239,68,68,0.25); }

  /* 페이지네이션 */
  .pagination { display: flex; justify-content: center; align-items: center; gap: 6px; margin-top: 36px; flex-wrap: wrap; }
  .pg-btn {
    padding: 7px 13px; border-radius: 8px; border: 1px solid rgba(255,255,255,0.1);
    background: rgba(255,255,255,0.05); color: rgba(255,255,255,0.6);
    font-size: 13px; font-weight: 500; cursor: pointer; text-decoration: none;
    font-family: 'Inter', sans-serif; transition: all 0.15s; display: inline-block;
  }
  .pg-btn:hover { background: rgba(255,255,255,0.12); color: #fff; }
  .pg-btn.active { background: linear-gradient(135deg,#3b82f6,#1d4ed8); color: #fff; border-color: transparent; }
  .pg-btn.disabled { opacity: 0.3; pointer-events: none; }
  .pg-info { font-size: 12px; color: rgba(255,255,255,0.3); margin: 0 8px; }

  /* 상세뷰 */
  .detail-screen { display: none; position: fixed; inset: 0; z-index: 1000; background: #0b1120; overflow-y: auto; animation: fadeIn 0.22s ease; }
  .detail-screen.open { display: block; }
  @keyframes fadeIn { from { opacity:0; } to { opacity:1; } }
  .detail-top-bar { position: sticky; top: 0; z-index: 10; display: flex; align-items: center; gap: 14px; padding: 14px 24px; background: rgba(11,17,32,0.9); border-bottom: 1px solid rgba(255,255,255,0.08); backdrop-filter: blur(12px); }
  .detail-back-btn { display: flex; align-items: center; gap: 6px; padding: 8px 16px; border-radius: 10px; background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.12); color: rgba(255,255,255,0.8); font-size: 13px; font-weight: 500; cursor: pointer; font-family: 'Inter', sans-serif; transition: all 0.15s; }
  .detail-back-btn:hover { background: rgba(255,255,255,0.14); color: #fff; }
  .detail-bar-title { font-size: 15px; font-weight: 600; color: rgba(255,255,255,0.7); }
  .detail-hero { width: 100%; height: 55vh; min-height: 300px; background: linear-gradient(135deg,#1e3a5f,#0f2144); display: flex; align-items: center; justify-content: center; font-size: 100px; overflow: hidden; }
  .detail-hero img { width: 100%; height: 100%; object-fit: cover; }
  .detail-body { max-width: 780px; margin: 0 auto; padding: 40px 32px 80px; }
  .detail-dest-badge { display: inline-flex; align-items: center; gap: 6px; font-size: 12px; color: #60a5fa; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; background: rgba(96,165,250,0.1); border-radius: 8px; padding: 5px 12px; margin-bottom: 18px; }
  .detail-title { font-size: 32px; font-weight: 800; line-height: 1.25; margin-bottom: 12px; letter-spacing: -0.5px; color: #fff; }
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

  .empty-state { text-align: center; padding: 80px 20px; }
  .empty-icon { font-size: 50px; margin-bottom: 14px; }
  .empty-text { font-size: 15px; color: rgba(255,255,255,0.5); margin-bottom: 6px; }
  .empty-sub { font-size: 13px; color: rgba(255,255,255,0.3); }
</style>
</head>
<body>

<nav class="nav-bar">
  <div class="nav-logo">Travel<span>Log</span></div>
  <div class="nav-actions">
    <button class="nav-btn nav-btn-ghost" onclick="location.href='Calendar.jsp'">← 지도로</button>
    <button class="nav-btn nav-btn-primary" onclick="location.href='write.jsp'">+ 일지 작성</button>
    <button class="nav-btn nav-btn-ghost" onclick="location.href='profile.jsp'" title="내 정보">👤</button>
    <button class="nav-btn nav-btn-ghost" onclick="location.href='logout.jsp'">로그아웃</button>
  </div>
</nav>

<div class="page-wrapper">
  <div class="page-title">여행 게시판</div>
  <div class="page-info">총 <%=String.format("%,d", totalCount)%>개 일지 &nbsp;·&nbsp; <%=curPage%> / <%=totalPages%> 페이지</div>

  <!-- 필터 탭 (서버사이드) -->
  <div class="filter-bar">
    <a class="filter-btn <%="all".equals(filterParam)?"active-all":""%>" href="List.jsp?filter=all&page=1">
      🌍 전체 <span style="opacity:.65">(<%=String.format("%,d", allCount)%>)</span>
    </a>
    <a class="filter-btn <%="mine".equals(filterParam)?"active-mine":""%>" href="List.jsp?filter=mine&page=1">
      ✦ 내 글 <span style="opacity:.65">(<%=String.format("%,d", mineCount)%>)</span>
    </a>
    <a class="filter-btn <%="other".equals(filterParam)?"active-other":""%>" href="List.jsp?filter=other&page=1">
      👥 다른 사람 글 <span style="opacity:.65">(<%=String.format("%,d", otherCount)%>)</span>
    </a>
  </div>

  <%
    if (hasData) {
      out.println("<div class='journal-grid'>" + cards + "</div>");
    } else {
  %>
    <div class="empty-state">
      <div class="empty-icon">🗺️</div>
      <div class="empty-text">해당 조건의 일지가 없어요</div>
      <div class="empty-sub">다른 필터를 선택하거나 일지를 작성해보세요</div>
    </div>
  <% } %>

  <!-- 페이지네이션 -->
  <% if (totalPages > 1) { %>
  <div class="pagination">
    <!-- 이전 블록 -->
    <% if (blockStart > 1) { %>
    <a class="pg-btn" href="List.jsp?filter=<%=filterParam%>&page=<%=blockStart-1%>">‹</a>
    <% } %>

    <!-- 페이지 번호 -->
    <% for (int p = blockStart; p <= blockEnd; p++) { %>
    <a class="pg-btn <%=(p==curPage)?"active":""%>" href="List.jsp?filter=<%=filterParam%>&page=<%=p%>"><%=p%></a>
    <% } %>

    <!-- 다음 블록 -->
    <% if (blockEnd < totalPages) { %>
    <a class="pg-btn" href="List.jsp?filter=<%=filterParam%>&page=<%=blockEnd+1%>">›</a>
    <% } %>
  </div>
  <% } %>
</div>

<!-- 전체화면 상세보기 -->
<div class="detail-screen" id="detailScreen">
  <div class="detail-top-bar">
    <button class="detail-back-btn" onclick="closeDetail()">← 목록으로</button>
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
      <button class="detail-action-btn detail-del-btn"  id="detailDelBtn">🗑️ 삭제하기</button>
    </div>
  </div>
</div>

<script>
const JOURNALS = <%=jsonArr%>;

function openDetail(i) {
  const j = JOURNALS[i];
  const hero = document.getElementById('detailHero');
  hero.innerHTML = (j.image && j.image.trim())
    ? '<img src="uploads/' + j.image + '" alt="">'
    : '✈️';
  document.getElementById('detailBarTitle').textContent = j.title;
  document.getElementById('detailDest').textContent = '📍 ' + j.trip;
  document.getElementById('detailTitle').textContent = j.title;
  const wrEl = document.getElementById('detailWriter');
  wrEl.innerHTML = '✍️ <span>' + (j.mine ? '내가 쓴 글' : (j.writer || '알 수 없음') + ' 님의 글') + '</span>';
  wrEl.className = 'detail-writer' + (j.mine ? ' mine' : '');
  document.getElementById('detailDate').textContent = '🕐 ' + j.dt;
  document.getElementById('detailMemo').textContent = j.memo;
  const actEl = document.getElementById('detailActions');
  if (j.mine) {
    actEl.style.display = 'flex';
    const encTs = encodeURIComponent(j.ts);
    document.getElementById('detailEditBtn').onclick = () => { location.href = 'edit.jsp?ts=' + encTs; };
    document.getElementById('detailDelBtn').onclick  = () => { doDelete(encTs); };
  } else {
    actEl.style.display = 'none';
  }
  const screen = document.getElementById('detailScreen');
  screen.classList.add('open');
  screen.scrollTop = 0;
  document.body.style.overflow = 'hidden';
}

function closeDetail() {
  document.getElementById('detailScreen').classList.remove('open');
  document.body.style.overflow = '';
}

function doDelete(ts) {
  if (!confirm('정말 삭제하시겠습니까?')) return;
  location.href = 'delete_Action.jsp?ts=' + ts;
}

document.addEventListener('keydown', e => { if (e.key === 'Escape') closeDetail(); });
</script>
</body>
</html>
